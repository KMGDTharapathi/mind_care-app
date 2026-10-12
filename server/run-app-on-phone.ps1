# Run the MindCare app on a phone, wired to the local model server.
#
# One command does everything: it starts the model server (if not already
# running), waits until it is ready, then launches the app pointed at it.
#
#   # Phone on the same Wi-Fi as this PC (most common):
#   .\run-app-on-phone.ps1
#
#   # Android phone connected by USB (uses `adb reverse`, no Wi-Fi needed):
#   .\run-app-on-phone.ps1 -AdbReverse
#
#   # Override the port if you changed SRV_PORT:
#   .\run-app-on-phone.ps1 -Port 8100
#
#   # Build an installable APK (bakes the URL in) instead of `flutter run`:
#   .\run-app-on-phone.ps1 -BuildApk
#
#   # Only launch the app, leave the server to another terminal (.\run.ps1):
#   .\run-app-on-phone.ps1 -NoServer
#
# It passes --dart-define=WILLOW_API_BASE_URL, so the chat screen asks the
# model server for replies instead of the in-app curated brain.

param(
    [int]$Port = 8000,
    [switch]$AdbReverse,
    [switch]$OpenFirewall,
    [switch]$BuildApk,
    [switch]$NoServer,
    [int]$ServerWaitSeconds = 600
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repoRoot

# Invoke-WebRequest otherwise waits on proxy auto-detection, which can stall
# the readiness check below on some Windows setups (even with no proxy set).
[System.Net.WebRequest]::DefaultWebProxy = $null

$venvPython = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
$requirements = Join-Path $PSScriptRoot "requirements.txt"

function Get-LanIp {
    $candidates = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notlike "127.*" -and
            $_.IPAddress -notlike "169.254.*"
        } |
        Sort-Object InterfaceMetric
    foreach ($c in $candidates) {
        $ip = $c.IPAddress
        if ($ip -match "^192\.168\." -or
            $ip -match "^10\." -or
            $ip -match "^172\.(1[6-9]|2[0-9]|3[01])\.") {
            return $ip
        }
    }
    return $null
}

function Test-Health([int]$p) {
    # Use the IPv4 loopback explicitly: on Windows "localhost" resolves to ::1
    # first, but uvicorn binds IPv4 (0.0.0.0) only, so "localhost" would never
    # connect and the ready-wait below would time out.
    try {
        $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 "http://127.0.0.1:$p/health"
        return $r.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Test-LatestServer([int]$p) {
    try {
        $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 "http://127.0.0.1:$p/health"
        if ($r.StatusCode -ne 200) { return $false }
        return ($r.Content -match '"version"\s*:\s*2')
    } catch {
        return $false
    }
}

function Stop-PortProcess([int]$p) {
    try {
        $conns = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
        foreach ($c in $conns) {
            if ($c.OwningProcess -gt 0) {
                Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
            }
        }
        Start-Sleep -Seconds 2
    } catch {}
}

function Test-ValidPython([string]$exe) {
    if (-not $exe -or -not (Test-Path -LiteralPath $exe)) { return $false }
    if ($exe -like "*\WindowsApps\*") { return $false }
    try {
        $out = & $exe -c "import sys, venv; print(f'{sys.version_info[0]}.{sys.version_info[1]}')" 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $out) { return $false }
        $parts = $out.Trim().Split(".")
        $major = [int]$parts[0]
        $minor = [int]$parts[1]
        return ($major -eq 3 -and $minor -ge 10)
    } catch {
        return $false
    }
}

function Find-SystemPython {
    $searchPaths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python*\python.exe",
        "C:\Python312\python.exe",
        "C:\Python311\python.exe",
        "C:\Python310\python.exe",
        "C:\Program Files\Python312\python.exe",
        "C:\Program Files\Python311\python.exe",
        "C:\Program Files\Python310\python.exe",
        "$env:USERPROFILE\anaconda3\python.exe",
        "$env:USERPROFILE\miniconda3\python.exe"
    )
    foreach ($pattern in $searchPaths) {
        $matches = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending
        foreach ($m in $matches) {
            if (Test-ValidPython $m.FullName) { return $m.FullName }
        }
    }
    $found = Get-Command "python" -ErrorAction SilentlyContinue
    if ($found -and (Test-ValidPython $found.Source)) {
        return $found.Source
    }
    return $null
}

function Install-PythonIfMissing {
    $existing = Find-SystemPython
    if ($existing) { return $existing }

    Write-Host "Valid Python 3.10+ not found on this PC. Downloading and installing Python 3.11.9 (user-scope) ..."
    $installer = Join-Path $env:TEMP "python-3.11.9-amd64.exe"
    $targetDir = "$env:LOCALAPPDATA\Programs\Python\Python311"
    if (-not (Test-Path -LiteralPath $installer)) {
        Invoke-WebRequest -UseBasicParsing `
            -Uri "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe" `
            -OutFile $installer
    }
    $proc = Start-Process -FilePath $installer `
        -ArgumentList "/quiet InstallAllUsers=0 TargetDir=`"$targetDir`" PrependPath=1 Include_test=0 Include_pip=1" `
        -Wait -PassThru
    $installed = Find-SystemPython
    if (-not $installed) {
        throw "Python 3.11 installation did not complete (exit code $($proc.ExitCode)). Please install Python 3.11 from https://www.python.org/downloads/ and check 'Add python.exe to PATH'."
    }
    return $installed
}

function Test-VenvReady {
    if (-not (Test-Path -LiteralPath $venvPython)) { return $false }
    try {
        & $venvPython -c "import torch, transformers, fastapi, uvicorn" 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Ensure-Venv {
    if (Test-VenvReady) { return }
    $venvDir = Join-Path $PSScriptRoot ".venv"
    if (Test-Path -LiteralPath $venvDir) {
        Write-Host "Removing incomplete/broken .venv before recreating with Python 3.11 ..."
        Remove-Item -LiteralPath $venvDir -Recurse -Force
    }
    $sysPython = Install-PythonIfMissing
    Write-Host "Setting up the model server environment using $sysPython (first run, may take a few minutes) ..."
    & $sysPython -m venv $venvDir
    & $venvPython -m ensurepip --upgrade
    & $venvPython -m pip install --upgrade pip
    & $venvPython -m pip install torch --index-url https://download.pytorch.org/whl/cpu
    & $venvPython -m pip install -r $requirements
}

function Start-CloudflareTunnel([int]$p) {
    $cfExe = Join-Path $PSScriptRoot "cloudflared.exe"
    $cfLog = Join-Path $PSScriptRoot "cloudflared.log"
    if (-not (Test-Path -LiteralPath $cfExe)) {
        try {
            Write-Host "Downloading cloudflared for wireless phone access (works on Wi-Fi & mobile data) ..."
            Invoke-WebRequest -UseBasicParsing `
                -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" `
                -OutFile $cfExe
        } catch {
            Write-Warning "Could not download cloudflared; falling back to Wi-Fi LAN IP only."
            return $null
        }
    }
    if (Test-Path -LiteralPath $cfLog) {
        Remove-Item -LiteralPath $cfLog -Force -ErrorAction SilentlyContinue
    }
    $proc = Start-Process -FilePath $cfExe `
        -ArgumentList "tunnel --url http://127.0.0.1:$p --no-autoupdate --logfile `"$cfLog`"" `
        -WorkingDirectory $PSScriptRoot `
        -PassThru -WindowStyle Hidden
    $deadline = (Get-Date).AddSeconds(25)
    while ((Get-Date) -lt $deadline) {
        if (Test-Path -LiteralPath $cfLog) {
            $content = Get-Content -LiteralPath $cfLog -Raw -ErrorAction SilentlyContinue
            if ($content -match "(https://[a-zA-Z0-9-]+\.trycloudflare\.com)") {
                return @{ Process = $proc; Url = $Matches[1] }
            }
        }
        Start-Sleep -Seconds 1
    }
    return @{ Process = $proc; Url = $null }
}

function Find-Adb {
    $found = Get-Command "adb" -ErrorAction SilentlyContinue
    if ($found -and (Test-Path -LiteralPath $found.Source)) {
        return $found.Source
    }
    $localProps = Join-Path $repoRoot "android\local.properties"
    if (Test-Path -LiteralPath $localProps) {
        $lines = Get-Content -LiteralPath $localProps -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ($line -match "^sdk\.dir\s*=\s*(.+)$") {
                $sdkDir = $Matches[1].Trim() -replace "\\\\", "\" -replace "\\:", ":"
                $candidate = Join-Path $sdkDir "platform-tools\adb.exe"
                if (Test-Path -LiteralPath $candidate) { return $candidate }
            }
        }
    }
    $candidates = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:ANDROID_HOME\platform-tools\adb.exe",
        "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe",
        "C:\Users\Administrator\AppData\Local\Android\sdk\platform-tools\adb.exe"
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    return $null
}

$adbExe = Find-Adb
if ($adbExe) {
    $adbDir = Split-Path -Parent $adbExe
    if ($env:Path -notlike "*$adbDir*") {
        $env:Path = "$adbDir;$env:Path"
    }
}

# --- Resolve the URLs the phone should use ------------------------------
if ($adbExe) {
    try {
        & $adbExe reverse "tcp:$Port" "tcp:$Port" 2>$null | Out-Null
    } catch {}
}

$ip = Get-LanIp
$lanUrl = if ($ip) { "http://${ip}:$Port" } else { "http://127.0.0.1:$Port" }
$baseUrl = $lanUrl

if ($OpenFirewall) {
    Write-Host "Adding firewall rule for TCP $Port (needs admin) ..."
    New-NetFirewallRule -DisplayName "MindCare model server" `
        -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
}

# --- Start the model server (unless running/flutter-only build) ---------
$server = $null
$tunnel = $null
try {
    if (-not $NoServer) {
        if (Test-Health $Port) {
            if (-not (Test-LatestServer $Port)) {
                Write-Host "Restarting model server on port $Port with latest app.py ..."
                Stop-PortProcess $Port
            }
        }
        if (Test-Health $Port) {
            Write-Host "Model server already running on port $Port."
        } else {
            Ensure-Venv
            Write-Host "Starting model server on port $Port ..."
            $env:SRV_PORT = "$Port"
            $server = Start-Process -FilePath $venvPython `
                -ArgumentList "app.py" `
                -WorkingDirectory $PSScriptRoot `
                -PassThru -NoNewWindow
            Write-Host "Waiting for the model to load (up to $ServerWaitSeconds s) ..."
            $deadline = (Get-Date).AddSeconds($ServerWaitSeconds)
            while (-not (Test-Health $Port)) {
                if ($server.HasExited) {
                    throw "Model server exited early (code $($server.ExitCode)). See the log above."
                }
                if ((Get-Date) -ge $deadline) {
                    throw "Model server was not ready within $ServerWaitSeconds s."
                }
                Start-Sleep -Seconds 2
            }
            Write-Host "Model server is ready."
        }

        if (-not $AdbReverse) {
            $tunnel = Start-CloudflareTunnel $Port
            if ($tunnel -and $tunnel.Url) {
                $baseUrl = $tunnel.Url
                Write-Host "Wireless Tunnel URL (works without USB cable): $baseUrl"
            }
        }
    }

    Write-Host ""
    Write-Host "Primary Model Server URL : $baseUrl"
    Write-Host "Wi-Fi LAN Backup URL     : $lanUrl"
    Write-Host ""

    Write-Host "Building standalone Release APK (works after unplugging USB cable) ..."
    flutter build apk --release --android-skip-build-dependency-validation `
        --dart-define=WILLOW_API_BASE_URL="$baseUrl" `
        --dart-define=WILLOW_LAN_URL="$lanUrl"
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter APK build failed (exit code $LASTEXITCODE)."
    }

    $apkPath = Join-Path $repoRoot "build\app\outputs\flutter-apk\app-release.apk"
    Write-Host ""
    Write-Host "APK built: $apkPath"

    if (-not $BuildApk) {
        Write-Host "Installing Release APK onto connected phone ..."
        if ($adbExe) {
            & $adbExe install -r "$apkPath"
            Write-Host "Launching MindCare on your phone ..."
            & $adbExe shell monkey -p com.example.mindcare_app -c android.intent.category.LAUNCHER 1 2>$null | Out-Null
        } else {
            flutter install --release
        }

        Write-Host ""
        Write-Host "==================================================================="
        Write-Host " SUCCESS! MindCare is installed and running on your phone."
        Write-Host " You can now UNPLUG the USB data cable from your mobile phone!"
        Write-Host " Keep this PowerShell window open so the trained model (app.py)"
        Write-Host " continues answering your phone wirelessly. (Press Ctrl+C to stop)"
        Write-Host "==================================================================="
        Write-Host ""

        while ($true) {
            if ($server -and $server.HasExited) {
                throw "Model server exited unexpectedly (code $($server.ExitCode))."
            }
            Start-Sleep -Seconds 3
        }
    }
} finally {
    if ($tunnel -and $tunnel.Process -and -not $tunnel.Process.HasExited) {
        Stop-Process -Id $tunnel.Process.Id -Force -ErrorAction SilentlyContinue
    }
    if ($server -and -not $server.HasExited) {
        Write-Host "Stopping the model server ..."
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    }
}

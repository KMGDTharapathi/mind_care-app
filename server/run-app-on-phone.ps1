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
    try {
        $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 "http://localhost:$p/health"
        return $r.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Ensure-Venv {
    if (Test-Path -LiteralPath $venvPython) { return }
    Write-Host "Setting up the model server environment (first run, may take a few minutes) ..."
    python -m venv (Join-Path $PSScriptRoot ".venv")
    & $venvPython -m pip install --upgrade pip
    & $venvPython -m pip install -r $requirements
}

# --- Resolve the URL the phone should use -------------------------------
if ($AdbReverse) {
    Write-Host "Setting up adb reverse tcp:$Port -> tcp:$Port ..."
    adb reverse "tcp:$Port" "tcp:$Port"
    $baseUrl = "http://localhost:$Port"
} else {
    $ip = Get-LanIp
    if (-not $ip) {
        throw "Could not detect a LAN IP. Connect to Wi-Fi or pass -AdbReverse for USB."
    }
    $baseUrl = "http://${ip}:$Port"
}

if ($OpenFirewall) {
    Write-Host "Adding firewall rule for TCP $Port (needs admin) ..."
    New-NetFirewallRule -DisplayName "MindCare model server" `
        -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
}

# --- Start the model server (unless running/flutter-only build) ---------
$server = $null
try {
    if (-not $NoServer -and -not $BuildApk) {
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
    }

    Write-Host ""
    Write-Host "Model server URL: $baseUrl"
    Write-Host ""

    if ($BuildApk) {
        Write-Host "Building a release APK with this URL baked in ..."
        flutter build apk --release --dart-define=WILLOW_API_BASE_URL="$baseUrl"
        Write-Host ""
        Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk"
    } else {
        Write-Host "Building and launching the app on the connected device ..."
        flutter run --dart-define=WILLOW_API_BASE_URL="$baseUrl"
    }
} finally {
    if ($server -and -not $server.HasExited) {
        Write-Host "Stopping the model server ..."
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    }
}

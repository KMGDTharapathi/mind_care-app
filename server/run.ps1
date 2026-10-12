# MindCare Willow model server launcher
#
# Creates a local virtualenv, installs dependencies, then starts the API on
# 0.0.0.0:8000. Override the model location or port with environment variables
# before calling this script, e.g.:
#
#   $env:SRV_PORT = "8100"
#   $env:SRV_MODELS_DIR = "F:\Models\models_dl"
#   .\run.ps1

$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

$venv = Join-Path $PSScriptRoot ".venv"
$python = Join-Path $venv "Scripts\python.exe"

function Test-ValidPython([string]$exe) {
    if (-not $exe -or -not (Test-Path -LiteralPath $exe)) { return $false }
    if ($exe -like "*\WindowsApps\*") { return $false }
    try {
        $out = & $exe -c "import sys, venv; print(f'{sys.version_info[0]}.{sys.version_info[1]}')" 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $out) { return $false }
        $parts = $out.Trim().Split(".")
        return ([int]$parts[0] -eq 3 -and [int]$parts[1] -ge 10)
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

$venvReady = $false
if (Test-Path -LiteralPath $python) {
    try {
        & $python -c "import torch, transformers, fastapi, uvicorn" 2>$null
        $venvReady = ($LASTEXITCODE -eq 0)
    } catch {
        $venvReady = $false
    }
}

if (-not $venvReady) {
    if (Test-Path -LiteralPath $venv) {
        Write-Host "Removing incomplete/broken .venv ..."
        Remove-Item -LiteralPath $venv -Recurse -Force
    }
    $sysPython = Find-SystemPython
    if (-not $sysPython) {
        Write-Host "Valid Python 3.10+ not found on this PC. Downloading and installing Python 3.11.9 (user-scope) ..."
        $installer = Join-Path $env:TEMP "python-3.11.9-amd64.exe"
        $targetDir = "$env:LOCALAPPDATA\Programs\Python\Python311"
        if (-not (Test-Path -LiteralPath $installer)) {
            Invoke-WebRequest -UseBasicParsing `
                -Uri "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe" `
                -OutFile $installer
        }
        Start-Process -FilePath $installer `
            -ArgumentList "/quiet InstallAllUsers=0 TargetDir=`"$targetDir`" PrependPath=1 Include_test=0 Include_pip=1" `
            -Wait | Out-Null
        $sysPython = Find-SystemPython
    }
    Write-Host "Creating virtualenv in $venv using $sysPython ..."
    & $sysPython -m venv $venv
    Write-Host "Installing dependencies ..."
    & $python -m ensurepip --upgrade
    & $python -m pip install --upgrade pip
    & $python -m pip install torch --index-url https://download.pytorch.org/whl/cpu
    & $python -m pip install -r (Join-Path $PSScriptRoot "requirements.txt")
}

Write-Host "Starting MindCare Willow model server ..."
& $python (Join-Path $PSScriptRoot "app.py")

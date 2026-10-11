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

if (-not (Test-Path -LiteralPath $python)) {
    Write-Host "Creating virtualenv in $venv ..."
    python -m venv $venv
}

Write-Host "Installing dependencies ..."
& $python -m pip install --upgrade pip
& $python -m pip install -r (Join-Path $PSScriptRoot "requirements.txt")

Write-Host "Starting MindCare Willow model server ..."
& $python (Join-Path $PSScriptRoot "app.py")

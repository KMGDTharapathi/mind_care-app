# MindCare one-command launcher.
#
# Starts the trained model server (server/app.py), waits until it is ready,
# then builds and launches the app pointed at it. The chatbot then generates
# every reply from that model.
#
#   # Phone on the same Wi-Fi as this PC (most common):
#   .\run-app.ps1
#
#   # Android phone on USB (uses `adb reverse`, no Wi-Fi needed):
#   .\run-app.ps1 -AdbReverse
#
#   # Build an installable APK (bakes the server URL into the app):
#   .\run-app.ps1 -BuildApk
#
#   # Only launch the app; run the server yourself in another terminal:
#   .\run-app.ps1 -NoServer
#
# This simply forwards to server\run-app-on-phone.ps1.

param(
    [int]$Port = 8000,
    [switch]$AdbReverse,
    [switch]$OpenFirewall,
    [switch]$BuildApk,
    [switch]$NoServer,
    [int]$ServerWaitSeconds = 600
)

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "server\run-app-on-phone.ps1") `
    -Port $Port `
    -ServerWaitSeconds $ServerWaitSeconds `
    -AdbReverse:$AdbReverse `
    -OpenFirewall:$OpenFirewall `
    -BuildApk:$BuildApk `
    -NoServer:$NoServer

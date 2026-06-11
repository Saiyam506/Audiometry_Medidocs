<#
Start backend in a background PowerShell process (logs written to ./logs)
and then start the Flutter frontend in the current terminal so you can
interact with it (Ctrl+C to stop).

Usage (from workspace root, VS Code terminal):
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_dev.ps1
#>

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location (Join-Path $scriptDir '..')

# ensure logs directory
$logDir = Join-Path $PWD 'logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

$backendLog = Join-Path $logDir 'backend.log'
$backendErr = Join-Path $logDir 'backend.err'

Write-Host "Starting backend in background (logs: $backendLog, $backendErr)"

# Start backend in a new PowerShell process; output redirected to logs.
Start-Process -FilePath powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File .\scripts\run_backend.ps1" -RedirectStandardOutput $backendLog -RedirectStandardError $backendErr -WindowStyle Hidden

Start-Sleep -Seconds 2

Write-Host "Starting Flutter frontend in foreground (press Ctrl+C to stop)..."

# Run flutter in current terminal so it remains interactive.
flutter pub get
flutter run -d chrome

Pop-Location

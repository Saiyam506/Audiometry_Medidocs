<#
Run this to build a Windows release if the Visual Studio toolchain is present.
If Visual Studio is missing, the script prints instructions to install the
"Desktop development with C++" workload and exits.

Usage (PowerShell):
    powershell -ExecutionPolicy Bypass -File .\scripts\build_windows_helper.ps1
#>

Write-Host "Checking Flutter / Visual Studio toolchain..."

$doctor = flutter doctor -v 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "flutter doctor failed. Ensure Flutter is on PATH." -ForegroundColor Red
    exit 1
}

if ($doctor -match 'Visual Studio not installed') {
    Write-Host "Visual Studio (Desktop C++) is not installed." -ForegroundColor Yellow
    Write-Host "To build Windows releases you must install Visual Studio with the 'Desktop development with C++' workload." -ForegroundColor Yellow
    Write-Host "Download: https://visualstudio.microsoft.com/downloads/"
    Write-Host "After installation, re-run this script to build the release." -ForegroundColor Yellow
    exit 2
}

Write-Host "Visual Studio toolchain detected. Running Windows build..."
try {
    flutter build windows --release
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Windows build succeeded. Artifacts in build\windows\runner\Release" -ForegroundColor Green
    } else {
        Write-Host "flutter build windows returned exit code $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "Build failed: $_" -ForegroundColor Red
    exit 3
}

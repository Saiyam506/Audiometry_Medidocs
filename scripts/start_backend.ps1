param(
  [int]$Port = 8002,
  [switch]$Reload
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$venvPython = Join-Path $projectRoot 'backend\.venv\Scripts\python.exe'

if (-not (Test-Path $venvPython)) {
  throw "Backend virtual environment not found at $venvPython. Create it first with: python -m venv backend\.venv"
}

Push-Location $projectRoot
try {
  $uvicornArgs = @('-m', 'uvicorn', 'backend.main:app', '--port', "$Port")
  if ($Reload) {
    $uvicornArgs += '--reload'
  }

  & $venvPython @uvicornArgs
}
finally {
  Pop-Location
}

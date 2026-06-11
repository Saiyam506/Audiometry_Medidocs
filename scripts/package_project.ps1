# Package the project into hearing_aid_release.zip
$dst = "hearing_aid_release.zip"
if (Test-Path $dst) { Remove-Item $dst }
Compress-Archive -Path * -DestinationPath $dst -Force
Write-Host "Created $dst"

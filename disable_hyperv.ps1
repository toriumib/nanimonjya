Write-Host "Disabling Hyper-V..." -ForegroundColor Yellow
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart
Write-Host "Done. Reboot required." -ForegroundColor Green
Read-Host "Press Enter"

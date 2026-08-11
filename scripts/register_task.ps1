$action = New-ScheduledTaskAction -Execute "python" -Argument "scripts/auto_poster.py daily" -WorkingDirectory "C:\Users\tori\Downloads\nanimonjya-main\nanimonjya-main"
$trigger = New-ScheduledTaskTrigger -Daily -At 9:00AM
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "PetaNameAutoPost" -Action $action -Trigger $trigger -Settings $settings -Description "PetaName daily SNS auto poster"
Write-Host "Done."

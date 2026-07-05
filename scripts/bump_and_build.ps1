# Auto-increment the versionCode (the number after '+') in pubspec.yaml,
# then build the release AAB. Play Console never accepts a reused versionCode,
# so this removes the need to edit the number by hand every build.
#
# IMPORTANT: pubspec.yaml contains Japanese (UTF-8) comments. Windows PowerShell
# Get-Content/Set-Content default to the ANSI (Shift-JIS) codepage and WILL
# corrupt those bytes. We therefore read/write via .NET with explicit UTF-8
# (no BOM) so the file stays valid UTF-8.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $root "pubspec.yaml"

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$content = [System.IO.File]::ReadAllText($pubspecPath, $utf8NoBom)

if ($content -notmatch "version:\s*(\d+\.\d+\.\d+)\+(\d+)") {
    Write-Host "ERROR: 'version: X.Y.Z+N' line not found in pubspec.yaml" -ForegroundColor Red
    exit 1
}

$versionName = $Matches[1]
$oldBuild = [int]$Matches[2]
$newBuild = $oldBuild + 1

$newContent = $content -replace "version:\s*\d+\.\d+\.\d+\+\d+", "version: $versionName+$newBuild"
[System.IO.File]::WriteAllText($pubspecPath, $newContent, $utf8NoBom)

Write-Host "versionCode: $oldBuild -> $newBuild  (versionName: $versionName)" -ForegroundColor Green

Set-Location $root
flutter build appbundle --release

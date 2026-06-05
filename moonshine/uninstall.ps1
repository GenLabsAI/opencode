[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "Uninstalling Moonshine Edition..."
$moonshineHome = Join-Path $env:USERPROFILE ".moonshine"

if (Test-Path $moonshineHome) {
    Remove-Item -Path $moonshineHome -Recurse -Force
    Write-Host "Removed $moonshineHome."
} else {
    Write-Host "Moonshine Edition directory not found."
}

$InstallDir = Join-Path $env:USERPROFILE ".moonshine\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -match [regex]::Escape($InstallDir)) {
    $paths = $userPath -split ';'
    $newPaths = $paths | Where-Object { $_ -ne $InstallDir -and -not [string]::IsNullOrWhiteSpace($_) }
    $newPathStr = $newPaths -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPathStr, "User")
    Write-Host "Removed $InstallDir from user PATH."
}

Write-Host "Uninstallation complete." -ForegroundColor Green

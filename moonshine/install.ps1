#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $env:USERPROFILE ".moonshine\bin"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

$arch = if ([System.Environment]::Is64BitOperatingSystem) { "x64" } else { throw "Unsupported architecture" }
$target = "windows-$arch"
$filename = "opencode-$target.zip"

if ([string]::IsNullOrEmpty($Version)) {
    $url = "https://github.com/GenLabsAI/opencode/releases/latest/download/$filename"
} else {
    $cleanVersion = $Version -replace '^v', ''
    $url = "https://github.com/GenLabsAI/opencode/releases/download/v$cleanVersion/$filename"
}

Write-Host "Downloading Moonshine Edition from: $url"
$tmpDir = Join-Path $env:TEMP "moonshine_install_$PID"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
$archivePath = Join-Path $tmpDir $filename

try {
    Invoke-WebRequest -Uri $url -OutFile $archivePath -UseBasicParsing
} catch {
    Write-Host "Download failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Extracting..."
Expand-Archive -Path $archivePath -DestinationPath $tmpDir -Force

$exeSource = Join-Path $tmpDir "opencode.exe"
if (-not (Test-Path $exeSource)) {
    $exeSource = Get-ChildItem -Path $tmpDir -Filter "opencode.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName
}
Move-Item -Path $exeSource -Destination (Join-Path $InstallDir "opencode.exe") -Force

$launcher = @'
@echo off
set "OPENCODE_CONFIG_DIR=%USERPROFILE%\.moonshine\config"
set "XDG_DATA_HOME=%USERPROFILE%\.moonshine\data"
set "XDG_STATE_HOME=%USERPROFILE%\.moonshine\state"
set "XDG_CACHE_HOME=%USERPROFILE%\.moonshine\cache"
set "XDG_CONFIG_HOME=%USERPROFILE%\.moonshine\config"
"%USERPROFILE%\.moonshine\bin\opencode.exe" %*
'@
Set-Content -Path (Join-Path $InstallDir "moonshine.cmd") -Value $launcher -Encoding ASCII

Remove-Item -Recurse -Force $tmpDir

# Add to user PATH if not already present
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not ($userPath -split ';' | Where-Object { $_ -eq $InstallDir })) {
    $newPath = if ([string]::IsNullOrEmpty($userPath)) { $InstallDir } else { "$userPath;$InstallDir" }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Added $InstallDir to user PATH (restart your shell to take effect)."
}

Write-Host ""
Write-Host "Successfully installed Moonshine Edition to $InstallDir" -ForegroundColor Green
Write-Host "Run 'moonshine' from a new shell to start."

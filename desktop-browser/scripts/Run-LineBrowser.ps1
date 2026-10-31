$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot "Sync-Profile.ps1")
$engine = & (Join-Path $PSScriptRoot "Prepare-Runtime.ps1")
$profile = Join-Path $root "data\profile"
Write-Host "Engine: $engine"
Write-Host "Profile: $profile"
Start-Process -FilePath $engine -ArgumentList @("-no-remote", "-profile", $profile)

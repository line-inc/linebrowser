$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Find-Firefox.ps1")

$root = Split-Path -Parent $PSScriptRoot
$runtime = Join-Path $root "runtime\firefox"
$runtimeExe = Join-Path $runtime "firefox.exe"
$stamp = Join-Path $runtime ".line-runtime-ready"

function Write-LineAutoconfig([string]$installDir) {
    $defaultsPref = Join-Path $installDir "defaults\pref"
    New-Item -ItemType Directory -Force -Path $defaultsPref, (Join-Path $installDir "distribution") | Out-Null
    Set-Content -Path (Join-Path $defaultsPref "line-autoconfig.js") -Encoding ASCII -Value @"
pref("general.config.filename", "line.cfg");
pref("general.config.obscure_value", 0);
"@
    # The first line of autoconfig files must be a comment.
    Set-Content -Path (Join-Path $installDir "line.cfg") -Encoding ASCII -Value @"
// Line Browser autoconfig
pref("xpinstall.signatures.required", false);
pref("extensions.autoDisableScopes", 0);
pref("extensions.enabledScopes", 15);
pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
pref("browser.shell.checkDefaultBrowser", false);
pref("datareporting.policy.dataSubmissionEnabled", false);
pref("toolkit.telemetry.enabled", false);
"@
    Set-Content -Path (Join-Path $installDir "distribution\policies.json") -Encoding UTF8 -Value @"
{
  "policies": {
    "DisableAppUpdate": true,
    "DontCheckDefaultBrowser": true,
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "SearchEngines": {
      "Default": "DuckDuckGo"
    }
  }
}
"@
}

$source = Find-LineBrowserEngine
if (-not $source) {
    throw "A Gecko browser executable was not found. Install a supported Gecko browser or set LINE_FIREFOX_PATH."
}

$sourceDir = Split-Path -Parent $source
if (Test-Path $stamp) {
    Write-LineAutoconfig $runtime
    Write-Host "Runtime ready: $runtimeExe"
    return $runtimeExe
}

Write-Host "Copying Gecko runtime from $sourceDir ..."
New-Item -ItemType Directory -Force -Path $runtime | Out-Null
robocopy $sourceDir $runtime /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Failed to copy the Gecko runtime (robocopy $LASTEXITCODE)" }
Write-LineAutoconfig $runtime
Set-Content $stamp -Value (Get-Date -Format o)
Write-Host "Runtime ready: $runtimeExe"
return $runtimeExe

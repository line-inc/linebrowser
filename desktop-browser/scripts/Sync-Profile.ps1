$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$template = Join-Path $root "profile-template"
$profile = Join-Path $root "data\profile"
$assetsExt = Join-Path $root "app\assets\web_extensions"
$extDir = Join-Path $profile "extensions"

New-Item -ItemType Directory -Force -Path $profile, $extDir, (Join-Path $profile "chrome") | Out-Null

Copy-Item (Join-Path $template "user.js") (Join-Path $profile "user.js") -Force
Copy-Item (Join-Path $template "chrome\userChrome.css") (Join-Path $profile "chrome\userChrome.css") -Force
Copy-Item (Join-Path $template "chrome\userContent.css") (Join-Path $profile "chrome\userContent.css") -Force

$map = @{
    "ai_blocker"      = "line-ai-blocker@linebrowser.app"
    "force_dark"      = "line-force-dark@linebrowser.app"
    "media_grabber"   = "line-media-grabber@linebrowser.app"
    "omni_sync"       = "line-sync@linebrowser.org"
    "omni_translate"  = "line-translate@linebrowser.app"
    "proxy_router"    = "line-proxy-router@linebrowser.app"
    "universal_copy"  = "line-universal-copy@linebrowser.app"
}

foreach ($folder in $map.Keys) {
    $src = Join-Path $assetsExt $folder
    $dst = Join-Path $extDir $map[$folder]
    if (Test-Path $src) {
        if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
        Copy-Item $src $dst -Recurse -Force
    }
}

$overlays = Join-Path $root "app\desktop-overlays"
Copy-Item (Join-Path $overlays "media_grabber.manifest.json") (Join-Path $extDir "line-media-grabber@linebrowser.app\manifest.json") -Force
Copy-Item (Join-Path $overlays "proxy_router.manifest.json") (Join-Path $extDir "line-proxy-router@linebrowser.app\manifest.json") -Force

Copy-Item (Join-Path $root "app\ui") (Join-Path $extDir "line-ui@linebrowser.app") -Recurse -Force
Copy-Item (Join-Path $root "app\shield") (Join-Path $extDir "line-shield@linebrowser.app") -Recurse -Force
Copy-Item (Join-Path $root "app\assets\adblock_seed.txt") (Join-Path $extDir "line-shield@linebrowser.app\adblock_seed.txt") -Force

Write-Host "Profile synced: $profile"

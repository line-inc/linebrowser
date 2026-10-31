function Find-LineBrowserEngine {
    $candidates = @()
    if ($env:LINE_FIREFOX_PATH) { $candidates += $env:LINE_FIREFOX_PATH }
    $candidates += @(
        "C:\Program Files\Mozilla Firefox\firefox.exe",
        "C:\Program Files\Firefox Nightly\firefox.exe",
        "C:\Program Files (x86)\Mozilla Firefox\firefox.exe",
        (Join-Path $env:LOCALAPPDATA "Mozilla Firefox\firefox.exe"),
        "C:\Users\WinTechDragos\Desktop\Firefox.exe"
    )
    $geckoObj = Join-Path (Split-Path -Parent $PSScriptRoot) "line-desktop-gecko"
    if (Test-Path $geckoObj) {
        Get-ChildItem -Path $geckoObj -Filter firefox.exe -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 3 -ExpandProperty FullName |
            ForEach-Object { $candidates += $_ }
    }
    foreach ($path in $candidates) {
        if ($path -and (Test-Path $path)) {
            $item = Get-Item $path
            if ($item.Length -gt 1MB) { return $item.FullName }
        }
    }
    return $null
}

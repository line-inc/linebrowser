$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Get-Process electron -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
$targets = @(
    Join-Path $root "node_modules",
    Join-Path $root "_trash_electron_node_modules",
    Join-Path $root "package.json",
    Join-Path $root "package-lock.json",
    Join-Path $root "main.js",
    Join-Path $root "index.html"
)
foreach ($t in $targets) {
    if (Test-Path $t) {
        cmd /c "rmdir /s /q `"$t`"" 2>$null
        Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue
    }
}
if (Test-Path (Join-Path $root "node_modules")) {
    Write-Host "node_modules is still locked. Close Cursor's file preview of Electron files and run this script again."
} else {
    Write-Host "Electron leftovers removed."
}

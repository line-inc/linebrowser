@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ========================================================
echo Lansare Line Browser (Chromium Core Nativ)...
echo ========================================================

set "PROFILE_DIR=%~dp0\LineBrowser_Profile"
if not exist "%PROFILE_DIR%" mkdir "%PROFILE_DIR%"

set "BROWSER_PATH="
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set "BROWSER_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe"
if not defined BROWSER_PATH if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set "BROWSER_PATH=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
if not defined BROWSER_PATH if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" set "BROWSER_PATH=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
if not defined BROWSER_PATH if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" set "BROWSER_PATH=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

if defined BROWSER_PATH (
    echo Se porneste motorul Chromium nativ...
    start "" "%BROWSER_PATH%" --user-data-dir="%PROFILE_DIR%" --new-window "https://lineinc.ro"
) else (
    echo [Eroare] Nu s-a găsit Google Chrome sau Microsoft Edge instalat pe acest PC.
    pause
)
exit

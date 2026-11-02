@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ========================================================
echo Line Browser - Lansare Motor Chromium
echo ========================================================

set "PROFILE_DIR=%~dp0\LineBrowser_Profile"
if not exist "%PROFILE_DIR%" mkdir "%PROFILE_DIR%"

set "CHROME_EXE="

if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=C:\Program Files\Google\Chrome\Application\chrome.exe"
if not defined CHROME_EXE if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
if not defined CHROME_EXE if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" set "CHROME_EXE=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
if not defined CHROME_EXE if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" set "CHROME_EXE=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

if not defined CHROME_EXE if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
if not defined CHROME_EXE if exist "%LOCALAPPDATA%\Microsoft\Edge\Application\msedge.exe" set "CHROME_EXE=%LOCALAPPDATA%\Microsoft\Edge\Application\msedge.exe"

if defined CHROME_EXE (
    echo Se porneste browserul cu motorul Chromium...
    start "" "%CHROME_EXE%" --user-data-dir="%PROFILE_DIR%" --new-window "https://lineinc.ro"
) else (
    echo [Eroare] Nu s-a gasit Google Chrome sau Microsoft Edge instalat pe acest PC.
    pause
)
exit

@echo off
cd /d "%~dp0"
echo ========================================================
echo Lansare Line Browser (Chromium Core Nativ)...
echo ========================================================
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe /out:LineBrowser.exe main.cs
if exist LineBrowser.exe (
    start "" LineBrowser.exe
) else (
    echo [Eroare] Compilarea a eșuat.
    pause
)

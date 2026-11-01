@echo off
cd /d "%~dp0"
echo ========================================================
echo Compilare Line Browser (Chromium Core nativ Windows)...
echo ========================================================
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe /out:LineBrowser.exe main.cs
if exist LineBrowser.exe (
    echo Pornire LineBrowser.exe...
    start "" LineBrowser.exe
) else (
    echo [Eroare] Compilarea C# a eșuat.
    pause
)

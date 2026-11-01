@echo off
cd /d "%~dp0"
echo ========================================================
echo Se lanseaza Line Browser Desktop (Chromium Engine)...
echo ========================================================
python -c "import PyQt5" 2>nul
if errorlevel 1 (
    echo Se instaleaza PyQt5 si PyQtWebEngine pentru randare Chromium...
    pip install PyQt5 PyQtWebEngine requests
)
start "" python main.py
exit

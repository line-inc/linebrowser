@echo off
cd /d "%~dp0"
echo ========================================================
echo Se porneste Line Browser (Chromium Core Nativ)...
echo ========================================================
python -c "import PyQt5" 2>nul
if errorlevel 1 (
    echo Se instaleaza PyQt5 si PyQtWebEngine...
    pip install PyQt5 PyQtWebEngine
)
python main.py
pause

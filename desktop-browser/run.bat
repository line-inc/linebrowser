@echo off
cd /d "%~dp0"
echo Se instaleaza PyQt5 si dependintele necesare...
pip install -r requirements.txt
echo Se porneste Line Browser Desktop...
python main.py
if errorlevel 1 (
    echo.
    echo [Eroare] Python a întâmpinat o problemă.
    pause
)

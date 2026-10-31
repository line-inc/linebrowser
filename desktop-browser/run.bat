@echo off
cd /d "%~dp0"
echo Se porneste Line Browser Desktop...
python main.py
if errorlevel 1 (
    echo.
    echo [Eroare] Python a întâmpinat o problemă. Asigurați-vă că ați rulat 'pip install -r requirements.txt'.
    pause
)

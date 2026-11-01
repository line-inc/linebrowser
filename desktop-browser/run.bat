@echo off
cd /d "%~dp0"
echo Se instaleaza dependintele necesare pentru Line Browser (Chromium Engine)...
pip install -r requirements.txt
echo Se porneste Line Browser...
python main.py
pause

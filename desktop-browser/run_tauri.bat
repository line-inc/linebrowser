@echo off
cd /d "%~dp0"
echo Se porneste Line Browser Desktop (Tauri)...
if not exist "node_modules" (
    echo Se instalează pachetele Node.js...
    call npm install
)
echo Se lanseaza aplicatia...
call npx tauri dev
pause

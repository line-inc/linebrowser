@echo off
cd /d "%~dp0"
echo Se pornește Line Browser Desktop (Tauri)...
if not exist "node_modules" (
    echo Se instalează pachetele Node.js...
    call npm install
)
echo Se compilează backend-ul Rust și se lansează aplicația...
call npm run tauri dev
pause

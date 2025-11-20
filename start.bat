@echo off
setlocal enableextensions
title SpotCancerAI - Dev Orchestrator
echo ========================================
echo    SpotCancerAI - Dev Orchestrator
echo ========================================
echo This will start: Backend (5000), ML (8001), Frontend Web (4000)
echo.

REM Start Backend (Node.js) in new window
echo [1/3] Starting Backend on http://localhost:5000 ...
start "Backend" cmd /c "cd /d backend && npm install && node server.js"

REM Start ML Service (Python) in new window
echo [2/3] Starting ML Service on http://localhost:8001 ...
start "ML Service" cmd /c "cd /d ml_service && python -m pip install -r requirements.txt && python app.py"

REM Start Flutter Web dev server in new window
echo [3/3] Starting Flutter Web on http://localhost:4000 ...
start "Flutter Web" cmd /c "flutter run -d web-server --web-port 4000 --web-hostname localhost"

echo.
echo All services launched. Open your browser at: http://localhost:4000
echo Logs available in their respective windows. Press any key to exit this orchestrator.
pause >nul
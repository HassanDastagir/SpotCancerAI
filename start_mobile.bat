@echo off
setlocal enableextensions
title SpotCancerAI - Mobile Dev Orchestrator
echo ========================================
echo    SpotCancerAI - Mobile Dev Orchestrator
echo ========================================
echo This will start: Backend (5000), ML (8001), then Flutter on Android
echo.

REM Start Backend (Node.js)
echo [1/3] Starting Backend on http://localhost:5000 ...
start "Backend" cmd /c "cd /d backend && npm install && node server.js"

REM Start ML Service (Python)
echo [2/3] Starting ML Service on http://localhost:8001 ...
start "ML Service" cmd /c "cd /d ml_service && python -m pip install -r requirements.txt && python app.py"

REM Run Flutter on Android device/emulator (foreground)
echo [3/3] Launching Flutter app on Android ...
echo Tip: Ensure device is connected and 'flutter devices' lists it.
flutter run -d android
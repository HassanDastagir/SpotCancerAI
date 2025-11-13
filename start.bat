@echo off
echo ========================================
echo    SpotCancerAI - Combined Startup
echo ========================================
echo.

echo [1/3] Building Flutter web application...
flutter build web
if %errorlevel% neq 0 (
    echo ERROR: Flutter build failed!
    pause
    exit /b 1
)

echo.
echo [2/3] Installing backend dependencies...
cd backend
call npm install
if %errorlevel% neq 0 (
    echo ERROR: npm install failed!
    pause
    exit /b 1
)

echo.
echo [3/3] Starting combined application...
echo Frontend and Backend will run on: http://localhost:5000
echo.
node server.js
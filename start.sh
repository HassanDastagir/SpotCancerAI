#!/bin/bash

echo "========================================"
echo "   SpotCancerAI - Combined Startup"
echo "========================================"
echo

echo "[1/3] Building Flutter web application..."
flutter build web
if [ $? -ne 0 ]; then
    echo "ERROR: Flutter build failed!"
    exit 1
fi

echo
echo "[2/3] Installing backend dependencies..."
cd backend
npm install
if [ $? -ne 0 ]; then
    echo "ERROR: npm install failed!"
    exit 1
fi

echo
echo "[3/3] Starting combined application..."
echo "Frontend and Backend will run on: http://localhost:5000"
echo
node server.js
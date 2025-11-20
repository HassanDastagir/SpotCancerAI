#!/bin/bash
echo "========================================"
echo "   SpotCancerAI - Mobile Dev Orchestrator"
echo "========================================"
echo "This will start: Backend (5000), ML (8001), then Flutter on Android"
echo

# Start Backend and ML in background
echo "[1/3] Starting Backend on http://localhost:5000 ..."
(cd backend && npm install && node server.js) &
echo "[2/3] Starting ML Service on http://localhost:8001 ..."
(cd ml_service && pip install -r requirements.txt && python app.py) &

# Run Flutter on Android (foreground)
echo "[3/3] Launching Flutter app on Android ..."
echo "Tip: Ensure device is connected and 'flutter devices' lists it."
flutter run -d android
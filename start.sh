#!/bin/bash

echo "========================================"
echo "   SpotCancerAI - Dev Orchestrator"
echo "========================================"
echo "This will start: Backend (5000), ML (8001), Frontend Web (4000)"
echo

# Start Backend in background
echo "[1/3] Starting Backend on http://localhost:5000 ..."
(cd backend && npm install && node server.js) &

# Start ML service in background
echo "[2/3] Starting ML Service on http://localhost:8001 ..."
(cd ml_service && pip install -r requirements.txt && python app.py) &

# Start Flutter web dev server (foreground)
echo "[3/3] Starting Flutter Web on http://localhost:4000 ..."
flutter run -d web-server --web-port 4000 --web-hostname localhost

echo "All services launched. If the Flutter server stops, background services keep running."
# SpotCancerAI

Flutter frontend + Node/Express backend + FastAPI (TensorFlow) ML service.

## Project Structure
- `lib/` Flutter app (web/mobile/desktop)
- `backend/` Express API and routes
- `ml_service/` FastAPI service that loads the TensorFlow model and performs preprocessing/prediction
- `Cancermodel/` Local model artifacts (not committed)

## Prerequisites
- Flutter SDK (3.x)
- Node.js (16+)
- Python 3.9+ with pip

## Setup
1) Backend env vars
   - Copy `backend/.env.example` to `backend/.env` and set values:
     - `MONGODB_URI`, `JWT_SECRET`, `ML_URL` (default `http://localhost:8001/predict`).

2) ML service
   - `pip install -r ml_service/requirements.txt`
   - Place model file at `Cancermodel/efficientnetb5_focal_model.h5` (kept out of Git), or set `MODEL_PATH` env var.
   - Run: `python ml_service/app.py` (serves at `http://localhost:8001`).

3) Backend
   - `cd backend && npm install`
   - `node server.js` (serves at `http://localhost:5000`).

4) Frontend (Flutter web)
   - `flutter run -d chrome` or use root `npm run dev` (builds web then runs backend).

## Prediction Flow
- Frontend sends image → `http://localhost:5000/api/predict`.
- Backend forwards to ML service `http://localhost:8001/predict` with multipart `file`.
- ML service preprocesses (hair removal, resize 456x456, EfficientNet preprocess_input) and returns JSON.

## Git Notes
- Secrets and heavy files are ignored:
  - `backend/.env`, `backend/uploads/`, `backend/node_modules/`, `ml_service/__pycache__/`, `Cancermodel/*.h5`.
- If you need to version large model files, use Git LFS and remove the ignore for `Cancermodel/*.h5`.

## Health Checks
- ML service: `http://localhost:8001/health`
- Backend logs show `[predict]` entries on image uploads.

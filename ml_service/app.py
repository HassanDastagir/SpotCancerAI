from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi import Request
import uvicorn
import tensorflow as tf
import numpy as np
from PIL import Image
from PIL import ImageFile
ImageFile.LOAD_TRUNCATED_IMAGES = True
import io
import os

app = FastAPI(title="SpotCancerAI ML Service")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Model path config: default to your uploaded Kaggle model
MODEL_PATH = os.getenv("MODEL_PATH", os.path.join(os.path.dirname(os.path.dirname(__file__)), "Cancermodel", "efficientnetb5_focal_model.h5"))
IMG_W, IMG_H = [int(x) for x in os.getenv("IMG_SIZE", "456,456").split(",")]  # EfficientNetB5 default
THRESHOLD = float(os.getenv("THRESHOLD", "0.5"))
# Class labels mapping (override via env CLASS_LABELS as comma-separated list)
DEFAULT_CLASS_LABELS = [
    "Actinic keratoses (akiec)",
    "Basal cell carcinoma (bcc)",
    "Benign keratosis-like lesions (bkl)",
    "Dermatofibroma (df)",
    "Melanoma (mel)",
    "Melanocytic nevi (nv)",
    "Vascular lesions (vasc)",
]
CLASS_LABELS = [
    lbl.strip() for lbl in os.getenv("CLASS_LABELS", ",".join(DEFAULT_CLASS_LABELS)).split(",")
]


# Lazy-load model to improve startup
_model = None
def get_model():
    global _model
    if _model is None:
        # Supports .h5 or SavedModel directory
        _model = tf.keras.models.load_model(MODEL_PATH, compile=False)
    return _model


def preprocess_image_bytes(image_bytes: bytes, size=(IMG_W, IMG_H)):
    # 1️⃣ Read image properly in RGB
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = image.resize(size)

    # 2️⃣ Convert to NumPy (float32)
    arr = np.array(image).astype(np.float32)

    # ⚠️ Make sure your hair-removal step (agar use kar rahe ho)
    # output 0–255 range me ho aur 3-channel RGB hi rahe
    # agar tum hair removal karte ho, wo iss step se pehle lagao
    # aur output np.uint8 me convert kar ke yahan pass karo

    # 3️⃣ EfficientNetB5 preprocessing (V1)
    arr = tf.keras.applications.efficientnet.preprocess_input(arr)

    # 4️⃣ Add batch dimension
    arr = np.expand_dims(arr, axis=0)
    return arr


@app.get("/health")
async def health():
    return {"status": "ok", "model_path": MODEL_PATH, "img_size": [IMG_W, IMG_H]}


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        input_tensor = preprocess_image_bytes(contents)
        model = get_model()
        preds = model.predict(input_tensor)
        if preds.ndim == 2 and preds.shape[1] == 1:
            prob = float(preds[0][0])
            label = "positive" if prob >= THRESHOLD else "negative"
            return {"success": True, "probability": prob, "label": label, "meta": {"threshold": THRESHOLD, "img_size": [IMG_W, IMG_H]}}
        else:
            probs = preds[0].astype(float).tolist()
            top_idx = int(np.argmax(preds[0]))
            labels = CLASS_LABELS[:len(probs)]
            top_label = labels[top_idx] if top_idx < len(labels) else str(top_idx)
            return {"success": True, "probabilities": probs, "labels": labels, "top_index": top_idx, "top_label": top_label, "meta": {"img_size": [IMG_W, IMG_H]}}
    except Exception as e:
        try:
            size = len(contents) if 'contents' in locals() else None
        except Exception:
            size = None
        return {"success": False, "error": str(e), "size": size}


@app.post("/predict_raw")
async def predict_raw(request: Request):
    stage = "start"
    try:
        stage = "read_body"
        contents = await request.body()
        stage = "preprocess"
        input_tensor = preprocess_image_bytes(contents)
        stage = "load_model"
        model = get_model()
        stage = "predict"
        preds = model.predict(input_tensor)
        stage = "parse"
        try:
            if hasattr(preds, 'ndim') and preds.ndim == 2 and preds.shape[1] == 1:
                prob = float(preds[0][0])
                label = "positive" if prob >= THRESHOLD else "negative"
                return {"success": True, "probability": prob, "label": label, "meta": {"threshold": THRESHOLD, "img_size": [IMG_W, IMG_H]}}
            else:
                arr = None
                if isinstance(preds, (list, tuple)):
                    arr = preds[0]
                elif isinstance(preds, dict):
                    key = sorted(preds.keys())[0]
                    arr = preds[key]
                else:
                    arr = preds
                arr = np.array(arr)
                probs = arr[0].astype(float).tolist() if arr.ndim >= 2 else arr.astype(float).tolist()
                top_idx = int(np.argmax(arr[0])) if arr.ndim >= 2 else int(np.argmax(arr))
                labels = CLASS_LABELS[:len(probs)]
                top_label = labels[top_idx] if top_idx < len(labels) else str(top_idx)
                return {"success": True, "probabilities": probs, "labels": labels, "top_index": top_idx, "top_label": top_label, "meta": {"img_size": [IMG_W, IMG_H]}}
        except Exception as pred_err:
            return {"success": False, "error": f"Prediction parse error: {pred_err}", "preds_type": str(type(preds))}
    except Exception as e:
        try:
            contents = contents if 'contents' in locals() else b''
            header_hex = contents[:8].hex()
            size = len(contents)
        except Exception:
            header_hex = None
            size = None
        return {"success": False, "error": str(e), "stage": stage, "size": size, "header_hex": header_hex}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
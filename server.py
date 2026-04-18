"""
AgriGuard FastAPI Server
========================
Priority 1: PlantNet (prof-freakenstein/plantnet-disease-detection) — 97% accuracy
             Loads automatically once HuggingFace access is approved.
Priority 2: Your trained TFLite model (98.9% accuracy) — fallback

Install: pip install fastapi uvicorn torch torchvision tensorflow pillow python-multipart huggingface_hub numpy
Run:     python server.py
"""

import io, os, numpy as np
from contextlib import asynccontextmanager
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import uvicorn

HF_TOKEN = os.environ.get("HF_TOKEN", "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")

CLASS_NAMES = [
    "Apple___Apple_scab","Apple___Black_rot","Apple___Cedar_apple_rust","Apple___healthy",
    "Blueberry___healthy","Cherry_(including_sour)___Powdery_mildew","Cherry_(including_sour)___healthy",
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot","Corn_(maize)___Common_rust_",
    "Corn_(maize)___Northern_Leaf_Blight","Corn_(maize)___healthy",
    "Grape___Black_rot","Grape___Esca_(Black_Measles)","Grape___Leaf_blight_(Isariopsis_Leaf_Spot)","Grape___healthy",
    "Orange___Haunglongbing_(Citrus_greening)","Peach___Bacterial_spot","Peach___healthy",
    "Pepper,_bell___Bacterial_spot","Pepper,_bell___healthy",
    "Potato___Early_blight","Potato___Late_blight","Potato___healthy",
    "Raspberry___healthy","Soybean___healthy","Squash___Powdery_mildew",
    "Strawberry___Leaf_scorch","Strawberry___healthy",
    "Tomato___Bacterial_spot","Tomato___Early_blight","Tomato___Late_blight","Tomato___Leaf_Mold",
    "Tomato___Septoria_leaf_spot","Tomato___Spider_mites Two-spotted_spider_mite",
    "Tomato___Target_Spot","Tomato___Tomato_Yellow_Leaf_Curl_Virus",
    "Tomato___Tomato_mosaic_virus","Tomato___healthy",
]

# ── Model state ───────────────────────────────────────────────────────────────
plantnet_model = None          # PyTorch PlantNet (priority 1)
tflite_interpreter = None      # TFLite fallback (priority 2)
tflite_input_details = None
tflite_output_details = None
tflite_input_shape = (224, 224)
tflite_input_dtype = None
active_model = "none"          # "plantnet" | "tflite" | "none"

# ── PlantNet preprocessing (384x384, ImageNet normalization) ──────────────────
try:
    from torchvision import transforms
    plantnet_transform = transforms.Compose([
        transforms.Resize((384, 384)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
except ImportError:
    plantnet_transform = None


def try_load_plantnet():
    """Try to load PlantNet from HuggingFace. Returns True if successful."""
    global plantnet_model, active_model
    try:
        import torch
        os.environ["HUGGING_FACE_HUB_TOKEN"] = HF_TOKEN
        os.environ["HF_TOKEN"] = HF_TOKEN
        try:
            from huggingface_hub import login
            login(token=HF_TOKEN, add_to_git_credential=False)
        except Exception:
            pass

        print("Trying PlantNet (prof-freakenstein/plantnet-disease-detection)...")
        m = torch.hub.load(
            "prof-freakenstein/plantnet-disease-detection",
            "model",
            trust_repo=True,
            force_reload=False,
        )
        m.eval()
        plantnet_model = m
        active_model = "plantnet"
        print("✅ PlantNet loaded! Using PlantNet (97% accuracy, 384x384)")
        return True
    except Exception as e:
        err = str(e)
        if "awaiting a review" in err or "403" in err:
            print(f"⏳ PlantNet access pending approval — falling back to TFLite")
        elif "Authorization" in err:
            print(f"⏳ PlantNet not yet accessible — falling back to TFLite")
        else:
            print(f"⚠️  PlantNet unavailable ({err[:80]}) — falling back to TFLite")
        return False


def try_load_tflite():
    """Load your trained TFLite model as fallback."""
    global tflite_interpreter, tflite_input_details, tflite_output_details
    global tflite_input_shape, tflite_input_dtype, active_model
    try:
        import tensorflow as tf
        paths = ["assets/new_model/plant_disease.tflite", "plant_disease.tflite"]
        for path in paths:
            if os.path.exists(path):
                interp = tf.lite.Interpreter(model_path=path)
                interp.allocate_tensors()
                inp = interp.get_input_details()[0]
                out = interp.get_output_details()[0]
                tflite_interpreter = interp
                tflite_input_details = inp
                tflite_output_details = out
                tflite_input_shape = (inp["shape"][1], inp["shape"][2])
                tflite_input_dtype = inp["dtype"]
                active_model = "tflite"
                print(f"✅ TFLite fallback loaded: {path} | Input: {inp['shape']} {inp['dtype']}")
                return True
        print("❌ TFLite model not found")
        return False
    except Exception as e:
        print(f"❌ TFLite load failed: {e}")
        return False


def load_models():
    """Try PlantNet first, fall back to TFLite."""
    if not try_load_plantnet():
        try_load_tflite()


@asynccontextmanager
async def lifespan(app):
    load_models()
    yield


app = FastAPI(title="AgriGuard Disease API", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


def infer_plantnet(image_bytes: bytes, top_k: int = 5):
    import torch
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    t = plantnet_transform(img).unsqueeze(0)
    with torch.no_grad():
        probs = torch.softmax(plantnet_model(t), dim=1)[0]
    top_p, top_i = torch.topk(probs, min(top_k, 38))
    results = []
    for p, i in zip(top_p.tolist(), top_i.tolist()):
        cn = CLASS_NAMES[i]
        parts = cn.split("___")
        plant = parts[0].replace("_", " ").replace(",", "").strip()
        disease = parts[1].replace("_", " ").strip() if len(parts) > 1 else "healthy"
        results.append({"class_name": cn, "class_index": i, "plant": plant, "disease": disease,
                        "confidence": round(p * 100, 2), "is_healthy": "healthy" in disease.lower()})
    return results


def infer_tflite(image_bytes: bytes, top_k: int = 5):
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB").resize(tflite_input_shape, Image.BILINEAR)
    arr = np.array(img)
    arr = arr.astype(np.uint8) if tflite_input_dtype == np.uint8 else arr.astype(np.float32) / 255.0
    tflite_interpreter.set_tensor(tflite_input_details["index"], np.expand_dims(arr, 0))
    tflite_interpreter.invoke()
    probs = tflite_interpreter.get_tensor(tflite_output_details["index"])[0]
    if abs(probs.sum() - 1.0) > 0.05:
        probs = np.exp(probs - probs.max()); probs /= probs.sum()
    top_i = np.argsort(probs)[::-1][:top_k]
    results = []
    for i in top_i:
        cn = CLASS_NAMES[i]
        parts = cn.split("___")
        plant = parts[0].replace("_", " ").replace(",", "").strip()
        disease = parts[1].replace("_", " ").strip() if len(parts) > 1 else "healthy"
        results.append({"class_name": cn, "class_index": int(i), "plant": plant, "disease": disease,
                        "confidence": round(float(probs[i]) * 100, 2), "is_healthy": "healthy" in disease.lower()})
    return results


def infer(image_bytes: bytes, top_k: int = 5):
    if active_model == "plantnet":
        return infer_plantnet(image_bytes, top_k)
    elif active_model == "tflite":
        return infer_tflite(image_bytes, top_k)
    raise RuntimeError("No model loaded")


@app.get("/")
def root():
    return {"status": "running", "active_model": active_model,
            "plantnet_loaded": plantnet_model is not None,
            "tflite_loaded": tflite_interpreter is not None, "classes": 38}

@app.get("/health")
def health():
    return {"status": "ok" if active_model != "none" else "no_model",
            "active_model": active_model, "model_loaded": active_model != "none"}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    if active_model == "none": raise HTTPException(503, "No model loaded")
    data = await file.read()
    top = infer(data, 1)[0]
    return {"success": True, "model_used": active_model, **top}

@app.post("/predict_topk")
async def predict_topk(file: UploadFile = File(...), k: int = 5):
    if active_model == "none": raise HTTPException(503, "No model loaded")
    data = await file.read()
    return {"success": True, "model_used": active_model, "predictions": infer(data, min(k, 5))}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8000)))

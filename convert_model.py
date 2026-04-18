"""
AgriGuard — Convert Daksh159 MobileNetV2 .pth → TFLite
=======================================================
Requirements:
    pip install torch torchvision onnx onnx2tf tensorflow

Run:
    python convert_model.py

Output:
    plant_disease_new.tflite  ← drop this into assets/models/
"""

import os
import sys
import urllib.request

# ── Step 1: Download .pth from HuggingFace ───────────────────────────────────
PTH_URL = "https://huggingface.co/Daksh159/plant-disease-mobilenetv2/resolve/main/mobilenetv2_plant.pth"
PTH_FILE = "mobilenetv2_plant.pth"

if not os.path.exists(PTH_FILE):
    print(f"Downloading {PTH_FILE} ...")
    urllib.request.urlretrieve(PTH_URL, PTH_FILE)
    print("Download complete.")
else:
    print(f"{PTH_FILE} already exists, skipping download.")

# ── Step 2: Load model ────────────────────────────────────────────────────────
try:
    import torch
    import torch.nn as nn
    import torchvision.models as models
except ImportError:
    print("ERROR: Install PyTorch first: pip install torch torchvision")
    sys.exit(1)

print("Loading MobileNetV2 architecture...")
model = models.mobilenet_v2(weights=None)
model.classifier[1] = nn.Sequential(
    nn.Dropout(0.2),
    nn.Linear(model.classifier[1].in_features, 38)
)

state = torch.load(PTH_FILE, map_location="cpu")
# Handle both raw state_dict and wrapped checkpoints
if isinstance(state, dict) and "state_dict" in state:
    state = state["state_dict"]
model.load_state_dict(state)
model.eval()
print("Model loaded successfully. Classes: 38")

# ── Step 3: Export to ONNX ────────────────────────────────────────────────────
try:
    import onnx
except ImportError:
    print("ERROR: Install onnx: pip install onnx")
    sys.exit(1)

ONNX_FILE = "plant_disease.onnx"
print(f"Exporting to ONNX: {ONNX_FILE}")
dummy_input = torch.randn(1, 3, 224, 224)
torch.onnx.export(
    model,
    dummy_input,
    ONNX_FILE,
    input_names=["input"],
    output_names=["output"],
    dynamic_axes={"input": {0: "batch_size"}, "output": {0: "batch_size"}},
    opset_version=11,
    verbose=False,
)
# Verify
onnx_model = onnx.load(ONNX_FILE)
onnx.checker.check_model(onnx_model)
print("ONNX export verified.")

# ── Step 4: ONNX → TFLite via onnx2tf ────────────────────────────────────────
try:
    import onnx2tf
except ImportError:
    print("ERROR: Install onnx2tf: pip install onnx2tf")
    sys.exit(1)

TF_DIR = "plant_disease_tf"
print(f"Converting ONNX → TensorFlow SavedModel: {TF_DIR}/")
onnx2tf.convert(
    input_onnx_file_path=ONNX_FILE,
    output_folder_path=TF_DIR,
    non_verbose=True,
)
print("TensorFlow SavedModel created.")

# ── Step 5: SavedModel → TFLite ───────────────────────────────────────────────
try:
    import tensorflow as tf
except ImportError:
    print("ERROR: Install tensorflow: pip install tensorflow")
    sys.exit(1)

TFLITE_OUT = "plant_disease_new.tflite"
print(f"Converting SavedModel → TFLite: {TFLITE_OUT}")
converter = tf.lite.TFLiteConverter.from_saved_model(TF_DIR)
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # dynamic quantization
tflite_model = converter.convert()

with open(TFLITE_OUT, "wb") as f:
    f.write(tflite_model)

size_mb = os.path.getsize(TFLITE_OUT) / (1024 * 1024)
print(f"\n✅ Done! TFLite model saved: {TFLITE_OUT} ({size_mb:.1f} MB)")
print("\nNext steps:")
print(f"  1. Copy {TFLITE_OUT} → assets/models/plant_disease_dynamic_quant.tflite")
print(f"  2. Copy assets/models/disease_labels_38.txt → assets/models/disease_labels.txt")
print(f"  3. Run flutter run")

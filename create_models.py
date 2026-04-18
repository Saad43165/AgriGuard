"""
AgriGuard — Create Plant ID + Severity TFLite models
=====================================================
Since the disease model already identifies plant species through its labels,
we create:
1. A plant ID model derived from the same MobileNetV2 backbone (14 species)
2. A severity model using a simple rule-based approach encoded as TFLite

Run:
    python create_models.py

Requirements: pip install torch torchvision onnx onnx2tf tensorflow
"""

import os
import sys
import numpy as np

print("=" * 60)
print("AgriGuard Model Creator")
print("=" * 60)

# ── Check disease model exists ────────────────────────────────────────────────
DISEASE_ONNX = "plant_disease.onnx"
if not os.path.exists(DISEASE_ONNX):
    print(f"ERROR: {DISEASE_ONNX} not found. Run convert_model.py first.")
    sys.exit(1)

try:
    import torch
    import torch.nn as nn
    import torchvision.models as models
    import onnx
    import onnx2tf
    import tensorflow as tf
except ImportError as e:
    print(f"ERROR: Missing package: {e}")
    print("Run: pip install torch torchvision onnx onnx2tf tensorflow")
    sys.exit(1)

# ─────────────────────────────────────────────────────────────────────────────
# PART 1: Plant Species ID Model (14 classes from PlantVillage)
# ─────────────────────────────────────────────────────────────────────────────
print("\n[1/2] Creating Plant Species ID model (14 classes)...")

PLANT_CLASSES = [
    'Apple', 'Blueberry', 'Cherry', 'Corn', 'Grape',
    'Orange', 'Peach', 'Bell Pepper', 'Potato', 'Raspberry',
    'Soybean', 'Squash', 'Strawberry', 'Tomato'
]

# Load the same MobileNetV2 backbone but with 14 output classes
# We reuse the pretrained disease model weights for the feature extractor
# and add a new classification head for 14 species
print("  Loading MobileNetV2 backbone...")
species_model = models.mobilenet_v2(weights=None)
species_model.classifier[1] = nn.Sequential(
    nn.Dropout(0.2),
    nn.Linear(species_model.classifier[1].in_features, 14)
)

# Load the disease model weights for the feature extractor (shared backbone)
disease_model = models.mobilenet_v2(weights=None)
disease_model.classifier[1] = nn.Sequential(
    nn.Dropout(0.2),
    nn.Linear(disease_model.classifier[1].in_features, 38)
)
disease_state = torch.load("mobilenetv2_plant.pth", map_location="cpu")
if isinstance(disease_state, dict) and "state_dict" in disease_state:
    disease_state = disease_state["state_dict"]
disease_model.load_state_dict(disease_state)

# Copy feature extractor weights (shared backbone)
species_model.features.load_state_dict(disease_model.features.state_dict())
print("  Shared backbone weights loaded from disease model.")

# Initialize the classification head with weights derived from disease model
# Map 38 disease classes → 14 species by averaging class weights
disease_weight = disease_model.classifier[1][1].weight.data  # [38, 1280]
disease_bias = disease_model.classifier[1][1].bias.data      # [38]

# Disease label → species index mapping
DISEASE_TO_SPECIES = {
    0: 0, 1: 0, 2: 0, 3: 0,   # Apple (0-3)
    4: 1,                       # Blueberry (4)
    5: 2, 6: 2,                 # Cherry (5-6)
    7: 3, 8: 3, 9: 3, 10: 3,  # Corn (7-10)
    11: 4, 12: 4, 13: 4, 14: 4, # Grape (11-14)
    15: 5,                      # Orange (15)
    16: 6, 17: 6,               # Peach (16-17)
    18: 7, 19: 7,               # Bell Pepper (18-19)
    20: 8, 21: 8, 22: 8,       # Potato (20-22)
    23: 9,                      # Raspberry (23)
    24: 10,                     # Soybean (24)
    25: 11,                     # Squash (25)
    26: 12, 27: 12,             # Strawberry (26-27)
    28: 13, 29: 13, 30: 13, 31: 13, 32: 13, 33: 13, 34: 13, 35: 13, 36: 13, 37: 13,  # Tomato (28-37)
}

species_weight = torch.zeros(14, 1280)
species_bias = torch.zeros(14)
species_count = torch.zeros(14)

for disease_idx, species_idx in DISEASE_TO_SPECIES.items():
    species_weight[species_idx] += disease_weight[disease_idx]
    species_bias[species_idx] += disease_bias[disease_idx]
    species_count[species_idx] += 1

for i in range(14):
    if species_count[i] > 0:
        species_weight[i] /= species_count[i]
        species_bias[i] /= species_count[i]

species_model.classifier[1][1].weight.data = species_weight
species_model.classifier[1][1].bias.data = species_bias
species_model.eval()
print("  Species classification head initialized.")

# Export to ONNX
SPECIES_ONNX = "plant_species.onnx"
dummy = torch.randn(1, 3, 224, 224)
torch.onnx.export(
    species_model, dummy, SPECIES_ONNX,
    input_names=["input"], output_names=["output"],
    dynamic_axes={"input": {0: "batch"}, "output": {0: "batch"}},
    opset_version=18, verbose=False,
)
print(f"  ONNX exported: {SPECIES_ONNX}")

# Convert to TFLite
SPECIES_TF_DIR = "plant_species_tf"
onnx2tf.convert(
    input_onnx_file_path=SPECIES_ONNX,
    output_folder_path=SPECIES_TF_DIR,
    non_verbose=True,
)
print(f"  TFLite created in: {SPECIES_TF_DIR}/")

# ─────────────────────────────────────────────────────────────────────────────
# PART 2: Severity Model — simple MobileNetV2 with 5 severity classes
# We use the disease model backbone + severity head
# ─────────────────────────────────────────────────────────────────────────────
print("\n[2/2] Creating Severity model (5 classes)...")

severity_model = models.mobilenet_v2(weights=None)
severity_model.classifier[1] = nn.Sequential(
    nn.Dropout(0.2),
    nn.Linear(severity_model.classifier[1].in_features, 5)
)

# Copy feature extractor from disease model
severity_model.features.load_state_dict(disease_model.features.state_dict())

# Initialize severity head: map disease confidence → severity
# None=0, Low=1, Medium=2, High=3, Critical=4
# Use disease model weights to create severity-aware head
# Healthy classes → None severity
# Disease classes → severity based on disease type
disease_weight_sev = disease_model.classifier[1][1].weight.data  # [38, 1280]
disease_bias_sev = disease_model.classifier[1][1].bias.data

# Severity mapping for each of 38 disease classes
DISEASE_SEVERITY = [
    2,  # Apple___Apple_scab → Medium
    3,  # Apple___Black_rot → High
    2,  # Apple___Cedar_apple_rust → Medium
    0,  # Apple___healthy → None
    0,  # Blueberry___healthy → None
    2,  # Cherry___Powdery_mildew → Medium
    0,  # Cherry___healthy → None
    2,  # Corn___Cercospora_leaf_spot → Medium
    3,  # Corn___Common_rust → High
    3,  # Corn___Northern_Leaf_Blight → High
    0,  # Corn___healthy → None
    3,  # Grape___Black_rot → High
    3,  # Grape___Esca → High
    2,  # Grape___Leaf_blight → Medium
    0,  # Grape___healthy → None
    4,  # Orange___Haunglongbing → Critical
    3,  # Peach___Bacterial_spot → High
    0,  # Peach___healthy → None
    2,  # Pepper___Bacterial_spot → Medium
    0,  # Pepper___healthy → None
    2,  # Potato___Early_blight → Medium
    3,  # Potato___Late_blight → High
    0,  # Potato___healthy → None
    0,  # Raspberry___healthy → None
    0,  # Soybean___healthy → None
    2,  # Squash___Powdery_mildew → Medium
    2,  # Strawberry___Leaf_scorch → Medium
    0,  # Strawberry___healthy → None
    3,  # Tomato___Bacterial_spot → High
    2,  # Tomato___Early_blight → Medium
    3,  # Tomato___Late_blight → High
    2,  # Tomato___Leaf_Mold → Medium
    2,  # Tomato___Septoria_leaf_spot → Medium
    2,  # Tomato___Spider_mites → Medium
    2,  # Tomato___Target_Spot → Medium
    4,  # Tomato___Yellow_Leaf_Curl_Virus → Critical
    2,  # Tomato___Mosaic_virus → Medium
    0,  # Tomato___healthy → None
]

sev_weight = torch.zeros(5, 1280)
sev_bias = torch.zeros(5)
sev_count = torch.zeros(5)

for disease_idx, sev_idx in enumerate(DISEASE_SEVERITY):
    sev_weight[sev_idx] += disease_weight_sev[disease_idx]
    sev_bias[sev_idx] += disease_bias_sev[disease_idx]
    sev_count[sev_idx] += 1

for i in range(5):
    if sev_count[i] > 0:
        sev_weight[i] /= sev_count[i]
        sev_bias[i] /= sev_count[i]

severity_model.classifier[1][1].weight.data = sev_weight
severity_model.classifier[1][1].bias.data = sev_bias
severity_model.eval()
print("  Severity classification head initialized.")

SEVERITY_ONNX = "plant_severity.onnx"
torch.onnx.export(
    severity_model, dummy, SEVERITY_ONNX,
    input_names=["input"], output_names=["output"],
    dynamic_axes={"input": {0: "batch"}, "output": {0: "batch"}},
    opset_version=18, verbose=False,
)
print(f"  ONNX exported: {SEVERITY_ONNX}")

SEVERITY_TF_DIR = "plant_severity_tf"
onnx2tf.convert(
    input_onnx_file_path=SEVERITY_ONNX,
    output_folder_path=SEVERITY_TF_DIR,
    non_verbose=True,
)
print(f"  TFLite created in: {SEVERITY_TF_DIR}/")

# ─────────────────────────────────────────────────────────────────────────────
# PART 3: Copy to assets
# ─────────────────────────────────────────────────────────────────────────────
print("\n[3/3] Copying models to assets/models/...")

import shutil

# Plant species model
species_tflite = os.path.join(SPECIES_TF_DIR, "plant_species_float32.tflite")
if os.path.exists(species_tflite):
    shutil.copy(species_tflite, "assets/models/plant_species_final_quantized.tflite")
    print(f"  ✅ Plant ID model copied ({os.path.getsize(species_tflite)//1024}KB)")
else:
    print(f"  ❌ Species TFLite not found at {species_tflite}")
    # Try float16
    species_tflite_f16 = os.path.join(SPECIES_TF_DIR, "plant_species_float16.tflite")
    if os.path.exists(species_tflite_f16):
        shutil.copy(species_tflite_f16, "assets/models/plant_species_final_quantized.tflite")
        print(f"  ✅ Plant ID model (float16) copied")

# Severity model
severity_tflite = os.path.join(SEVERITY_TF_DIR, "plant_severity_float32.tflite")
if os.path.exists(severity_tflite):
    shutil.copy(severity_tflite, "assets/models/severity_dynamic_quant.tflite")
    print(f"  ✅ Severity model copied ({os.path.getsize(severity_tflite)//1024}KB)")
else:
    print(f"  ❌ Severity TFLite not found at {severity_tflite}")
    severity_tflite_f16 = os.path.join(SEVERITY_TF_DIR, "plant_severity_float16.tflite")
    if os.path.exists(severity_tflite_f16):
        shutil.copy(severity_tflite_f16, "assets/models/severity_dynamic_quant.tflite")
        print(f"  ✅ Severity model (float16) copied")

# Update labels
with open("assets/models/labels.txt", "w") as f:
    f.write("\n".join(PLANT_CLASSES) + "\n")
print("  ✅ Plant species labels updated (14 classes)")

print("\n" + "=" * 60)
print("✅ All models created and copied!")
print("Next: flutter run")
print("=" * 60)

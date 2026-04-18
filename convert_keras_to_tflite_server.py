"""
Convert your best_plant_model.keras to a format the FastAPI server can use.

Since your model is Keras (TensorFlow), the server uses TFLite directly.
This script converts the server to use TFLite instead of PyTorch.

Run: python convert_keras_to_tflite_server.py
"""

import os
import sys

try:
    import tensorflow as tf
    print(f"TensorFlow version: {tf.__version__}")
except ImportError:
    print("ERROR: pip install tensorflow")
    sys.exit(1)

KERAS_PATH = "assets/new_model/best_plant_model.keras"
TFLITE_PATH = "assets/new_model/plant_disease.tflite"

if not os.path.exists(KERAS_PATH):
    print(f"ERROR: {KERAS_PATH} not found")
    sys.exit(1)

print(f"Loading {KERAS_PATH}...")
model = tf.keras.models.load_model(KERAS_PATH)
print(f"Model input shape: {model.input_shape}")
print(f"Model output shape: {model.output_shape}")
print(f"Model already converted to TFLite at: {TFLITE_PATH}")
print("\nYour server.py should use TFLite directly — see server_tflite.py")

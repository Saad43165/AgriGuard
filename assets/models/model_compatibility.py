# Run this Python script to check model ops
import tensorflow as tf
import numpy as np

model_path = "plant_id_model.tflite"

# Check supported operations
interpreter = tf.lite.Interpreter(model_path=model_path)
interpreter.allocate_tensors()

# Get all operations in the model
ops = interpreter._get_ops_details()
print("=== MODEL OPERATIONS ===")
for op in ops:
    print(f"Op: {op['op_name']}")
    print(f"  Inputs: {op['inputs']}")
    print(f"  Outputs: {op['outputs']}")
    print("---")

# Check if there are any custom operations
print("=== OPERATION COMPATIBILITY ===")
try:
    # This will show if there are unsupported ops
    tf.lite.experimental.Analyzer.analyze(model_path=model_path)
except Exception as e:
    print(f"Analysis error: {e}")
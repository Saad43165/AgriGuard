import tensorflow as tf
import numpy as np
import os

print("🔍 TensorFlow Lite Model Inspector")
print("===================================")

# Update this path to point to your .tflite file
MODEL_PATH = "plant_id_model.tflite"  # Change this to your actual file path

try:
    # Check if file exists
    if not os.path.exists(MODEL_PATH):
        print(f"❌ Error: File '{MODEL_PATH}' not found!")
        print("Please update MODEL_PATH to point to your .tflite file")
        exit(1)

    print(f"📁 Model file: {MODEL_PATH}")
    print(f"📊 File size: {os.path.getsize(MODEL_PATH) / (1024*1024):.2f} MB")

    # Load the model
    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()

    # Get input details
    input_details = interpreter.get_input_details()
    print("\n=== INPUT DETAILS ===")
    for i, detail in enumerate(input_details):
        print(f"Input {i}:")
        print(f"  Name: {detail['name']}")
        print(f"  Shape: {detail['shape']}")
        print(f"  Data Type: {detail['dtype']}")
        print(f"  Quantization: {detail['quantization']}")

        # Extract image dimensions
        shape = detail['shape']
        if len(shape) == 4:
            print(f"  🎯 IMAGE REQUIREMENTS:")
            print(f"     - Batch size: {shape[0]}")
            print(f"     - Height: {shape[1]}")
            print(f"     - Width: {shape[2]}")
            print(f"     - Channels: {shape[3]}")

    # Get output details
    output_details = interpreter.get_output_details()
    print("\n=== OUTPUT DETAILS ===")
    for i, detail in enumerate(output_details):
        print(f"Output {i}:")
        print(f"  Name: {detail['name']}")
        print(f"  Shape: {detail['shape']}")
        print(f"  Data Type: {detail['dtype']}")
        print(f"  Quantization: {detail['quantization']}")

    print("\n=== FLUTTER CONFIGURATION ===")
    if input_details:
        main_input = input_details[0]
        shape = main_input['shape']
        if len(shape) == 4:
            height = shape[1]
            width = shape[2]
            channels = shape[3]
            dtype = main_input['dtype']

            print("📝 Update your PlantIdService with these values:")
            print(f"static const int inputSize = {height}; // or {width} (should be same)")
            print(f"static const int numClasses = {output_details[0]['shape'][-1]};")

            if dtype == np.float32:
                print("// Model expects FLOAT32 input (normalized 0.0-1.0)")
            elif dtype == np.uint8:
                print("// Model expects UINT8 input (raw pixels 0-255)")

    print("✅ Model inspection completed!")

except Exception as e:
    print(f"❌ Error: {e}")
    print("\n💡 Troubleshooting:")
    print("1. Make sure TensorFlow is installed: pip install tensorflow")
    print("2. Update MODEL_PATH to point to your actual .tflite file")
    print("3. Ensure the .tflite file is in the same directory as this script")
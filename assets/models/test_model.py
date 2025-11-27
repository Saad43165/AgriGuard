# test_plant_model_fixed.py
import tensorflow as tf
import numpy as np
import cv2
from PIL import Image
import os

class PlantModelTester:
    def __init__(self, model_path):
        self.model_path = model_path
        self.labels = [
            'Apple', 'Bell_pepper', 'Cedar_Apple_Rust', 'Cherry', 'Corn',
            'Grape', 'Peach', 'Potato', 'Soybean', 'Strawberry', 'Tomato', 'Wheat'
        ]
        self.interpreter = None
        self.input_details = None
        self.output_details = None

    def load_model(self):
        """Load the TFLite model and allocate tensors."""
        print("🚀 Loading TFLite model...")
        try:
            self.interpreter = tf.lite.Interpreter(model_path=self.model_path)
            self.interpreter.allocate_tensors()

            # Get input and output tensors
            self.input_details = self.interpreter.get_input_details()
            self.output_details = self.interpreter.get_output_details()

            print("✅ Model loaded successfully!")
            print(f"📥 Input: {self.input_details[0]['shape']} ({self.input_details[0]['dtype']})")
            print(f"📤 Output: {self.output_details[0]['shape']} ({self.output_details[0]['dtype']})")

            # Print quantization info
            if 'quantization' in self.input_details[0]:
                print(f"📊 Input quantization: {self.input_details[0]['quantization']}")
            if 'quantization' in self.output_details[0]:
                print(f"📊 Output quantization: {self.output_details[0]['quantization']}")

            return True

        except Exception as e:
            print(f"❌ Failed to load model: {e}")
            return False

    def test_color_response(self):
        """Test model with different colored images (UINT8)."""
        print("\n🎨 TESTING COLOR RESPONSE")
        print("=" * 50)

        colors = {
            'RED': [255, 0, 0],
            'GREEN': [0, 255, 0],
            'BLUE': [0, 0, 255],
            'BLACK': [0, 0, 0],
            'WHITE': [255, 255, 255],
            'BROWN': [165, 42, 42],
            'GRAY': [128, 128, 128]
        }

        results = {}

        for color_name, rgb in colors.items():
            # Create solid color image (UINT8 0-255)
            test_image = np.ones((224, 224, 3), dtype=np.uint8)
            test_image[:, :, 0] = rgb[0]  # R
            test_image[:, :, 1] = rgb[1]  # G
            test_image[:, :, 2] = rgb[2]  # B

            # Add batch dimension
            test_image = np.expand_dims(test_image, axis=0)

            # Run inference
            prediction = self.predict(test_image)
            results[color_name] = prediction

            print(f"   {color_name} → {prediction['plant']} ({prediction['confidence']:.3f})")

        # Check if all predictions are the same
        unique_predictions = set([r['plant'] for r in results.values()])
        if len(unique_predictions) == 1:
            print(f"\n❌ ALL COLORS PREDICT SAME CLASS: {list(unique_predictions)[0]}")
        else:
            print(f"\n✅ Model responds differently to colors")

        return results

    def test_preprocessing_strategies(self):
        """Test different preprocessing strategies."""
        print("\n🔄 TESTING PREPROCESSING STRATEGIES")
        print("=" * 50)

        # Create a gray test image (UINT8)
        gray_image = np.ones((224, 224, 3), dtype=np.uint8) * 128

        strategies = {
            'Raw UINT8': lambda img: img,  # Direct UINT8 (0-255)
            '0-1 Normalized': lambda img: (img.astype(np.float32) / 255.0).astype(np.uint8),  # Wrong but test
            'BGR UINT8': lambda img: img[:, :, [2, 1, 0]],  # BGR order
        }

        results = {}

        for strategy_name, preprocess_fn in strategies.items():
            try:
                # Preprocess image
                processed = preprocess_fn(gray_image)
                processed = np.expand_dims(processed, axis=0)

                # Run inference
                prediction = self.predict_with_input(processed)
                results[strategy_name] = prediction

                max_val = np.max(prediction['raw_output'])
                if max_val > 0.99:
                    print(f"   {strategy_name}: ❌ SUSPICIOUS (one class dominates: {max_val:.3f})")
                else:
                    print(f"   {strategy_name}: ✅ GOOD (max: {max_val:.3f})")

            except Exception as e:
                print(f"   {strategy_name}: ❌ ERROR - {e}")

        return results

    def test_model_consistency(self):
        """Test if model gives consistent results for same input."""
        print("\n🔄 TESTING MODEL CONSISTENCY")
        print("=" * 50)

        # Create test input (UINT8)
        test_input = np.ones((1, 224, 224, 3), dtype=np.uint8) * 128

        predictions = []
        for i in range(5):
            prediction = self.predict_with_input(test_input)
            predictions.append(prediction['plant'])
            print(f"   Run {i+1}: {prediction['plant']} ({prediction['confidence']:.3f})")

        unique_predictions = set(predictions)
        if len(unique_predictions) == 1:
            print(f"   ✅ Model is consistent")
        else:
            print(f"   ⚠️ Model shows inconsistency")

        return predictions

    def predict_image_file(self, image_path):
        """Predict from image file."""
        # Load and preprocess image (UINT8)
        image = Image.open(image_path).convert('RGB')
        image = image.resize((224, 224))
        image_array = np.array(image, dtype=np.uint8)  # Keep as UINT8
        image_array = np.expand_dims(image_array, axis=0)

        return self.predict_with_input(image_array)

    def predict_with_input(self, input_data):
        """Run prediction with given input data."""
        # Ensure input is UINT8
        if input_data.dtype != np.uint8:
            input_data = input_data.astype(np.uint8)

        # Set input tensor
        self.interpreter.set_tensor(self.input_details[0]['index'], input_data)

        # Run inference
        self.interpreter.invoke()

        # Get output tensor
        output_data = self.interpreter.get_tensor(self.output_details[0]['index'])
        output = output_data[0]  # Remove batch dimension

        return self.process_output(output)

    def predict(self, input_data):
        """Alias for predict_with_input."""
        return self.predict_with_input(input_data)

    def process_output(self, output):
        """Process model output to get prediction."""
        # Dequantize output if quantized
        if self.output_details[0]['dtype'] == np.uint8:
            # Output is quantized, dequantize it
            quantization = self.output_details[0]['quantization']
            scale = quantization[0]
            zero_point = quantization[1]
            output = (output.astype(np.float32) - zero_point) * scale

        # Apply softmax if needed
        if np.sum(output) < 0.9 or np.sum(output) > 1.1:
            # Output is logits, apply softmax
            exp_output = np.exp(output - np.max(output))
            probabilities = exp_output / np.sum(exp_output)
        else:
            # Output is already probabilities
            probabilities = output

        # Get best prediction
        best_index = np.argmax(probabilities)
        confidence = probabilities[best_index]
        plant_name = self.labels[best_index]

        return {
            'plant': plant_name,
            'confidence': confidence,
            'raw_output': output,
            'probabilities': probabilities
        }

    def detailed_output_analysis(self):
        """Perform detailed analysis of model outputs."""
        print("\n🔍 DETAILED OUTPUT ANALYSIS")
        print("=" * 50)

        # Test with neutral input (UINT8)
        test_input = np.ones((1, 224, 224, 3), dtype=np.uint8) * 128
        prediction = self.predict_with_input(test_input)

        print("Raw output values:")
        for i, (label, value) in enumerate(zip(self.labels, prediction['raw_output'])):
            print(f"   {i:2d}. {label:15} : {value:10.6f}")

        print(f"\nSum of outputs: {np.sum(prediction['raw_output']):.6f}")
        print(f"Max value: {np.max(prediction['raw_output']):.6f}")
        print(f"Min value: {np.min(prediction['raw_output']):.6f}")

        # Check if outputs are probabilities or logits
        output_sum = np.sum(prediction['raw_output'])
        if 0.9 <= output_sum <= 1.1:
            print("✓ Output appears to be probabilities")
        else:
            print("✓ Output appears to be logits")

    def run_comprehensive_test(self, image_folder=None):
        """Run all tests comprehensively."""
        if not self.load_model():
            return

        print("\n" + "="*60)
        print("🌿 COMPREHENSIVE PLANT MODEL DIAGNOSIS")
        print("="*60)

        # Run all tests
        self.detailed_output_analysis()
        self.test_color_response()
        self.test_preprocessing_strategies()
        self.test_model_consistency()

        print("\n" + "="*60)
        print("🎯 DIAGNOSIS COMPLETE")
        print("="*60)

def main():
    # Update this path to your model location
    MODEL_PATH = "plant_id_model.tflite"
    IMAGE_FOLDER = "test_images"  # Optional: folder with test images

    tester = PlantModelTester(MODEL_PATH)
    tester.run_comprehensive_test(IMAGE_FOLDER)

if __name__ == "__main__":
    main()
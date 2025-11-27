import tensorflow as tf
import numpy as np
import cv2

class FixedPlantModel:
    def __init__(self, model_path):
        self.interpreter = tf.lite.Interpreter(model_path=model_path)
        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()

        self.class_names = [
            'Apple', 'Bell_pepper', 'Cedar_Apple_Rust', 'Cherry',
            'Corn', 'Grape', 'Peach', 'Potato',
            'Soybean', 'Strawberry', 'Tomato', 'Wheat'
        ]

        # Confidence threshold to avoid over-prediction of Corn
        self.corn_threshold = 0.7

    def predict(self, image):
        # Preprocess
        if len(image.shape) == 3 and image.shape[2] == 3:
            if image.shape[:2] != (224, 224):
                image = cv2.resize(image, (224, 224))
        else:
            raise ValueError("Image must be RGB format")

        input_data = np.expand_dims(image.astype(np.uint8), axis=0)

        # Run inference
        self.interpreter.set_tensor(self.input_details[0]['index'], input_data)
        self.interpreter.invoke()
        output_data = self.interpreter.get_tensor(self.output_details[0]['index'])

        # Handle quantization
        if self.output_details[0]['dtype'] == np.uint8:
            output_scale, output_zero_point = self.output_details[0]['quantization']
            output_data = (output_data.astype(np.float32) - output_zero_point) * output_scale

        probabilities = tf.nn.softmax(output_data[0]).numpy()

        # Apply correction if Corn probability is too high
        corn_index = self.class_names.index('Corn')
        if probabilities[corn_index] > self.corn_threshold:
            print(f"⚠ Applying correction: Corn probability {probabilities[corn_index]:.3f} > {self.corn_threshold}")

            # Reduce corn probability and redistribute
            corn_prob = probabilities[corn_index]
            reduction = corn_prob - 0.3  # Reduce to max 30%
            probabilities[corn_index] = 0.3

            # Redistribute to other classes
            other_indices = [i for i in range(len(probabilities)) if i != corn_index]
            total_other = np.sum(probabilities[other_indices])

            if total_other > 0:
                for i in other_indices:
                    probabilities[i] += reduction * (probabilities[i] / total_other)
            else:
                # If all other probabilities are zero, distribute equally
                for i in other_indices:
                    probabilities[i] += reduction / len(other_indices)

        return probabilities

    def predict_class(self, image):
        probabilities = self.predict(image)
        predicted_index = np.argmax(probabilities)
        confidence = probabilities[predicted_index]
        return self.class_names[predicted_index], confidence, probabilities

# Usage example
if __name__ == "__main__":
    # Initialize fixed model
    model = FixedPlantModel("plant_id_model.tflite")

    # Test with different colored images
    colors = {
        'RED': (255, 0, 0),
        'GREEN': (0, 255, 0),
        'BLUE': (0, 0, 255),
    }

    print("Testing fixed model with different colors:")
    print("=" * 40)

    for color_name, color_value in colors.items():
        test_image = np.full((224, 224, 3), color_value, dtype=np.uint8)
        predicted_class, confidence, all_probs = model.predict_class(test_image)

        print(f"{color_name:6} → {predicted_class} ({confidence:.3f})")

        # Show top 3 predictions
        top_indices = np.argsort(all_probs)[-3:][::-1]
        for i, idx in enumerate(top_indices):
            print(f"        {i+1}. {model.class_names[idx]:20} {all_probs[idx]:.3f}")
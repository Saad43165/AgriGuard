import tensorflow as tf
import numpy as np
import cv2
import os
import json
from collections import Counter
import matplotlib.pyplot as plt

class ModelFixer:
    def __init__(self, model_path):
        self.model_path = model_path
        self.class_names = [
            'Apple', 'Bell_pepper', 'Cedar_Apple_Rust', 'Cherry',
            'Corn', 'Grape', 'Peach', 'Potato',
            'Soybean', 'Strawberry', 'Tomato', 'Wheat'
        ]

    def create_balanced_dataset_analysis(self):
        """Analyze and suggest dataset balancing strategies."""
        print("\n📊 DATASET BALANCE ANALYSIS")
        print("=" * 50)

        # Common class distributions in plant disease datasets
        typical_distribution = {
            'Corn': 1500, 'Tomato': 1200, 'Apple': 1000, 'Potato': 800,
            'Grape': 700, 'Bell_pepper': 600, 'Strawberry': 500,
            'Soybean': 400, 'Peach': 300, 'Cherry': 250,
            'Wheat': 200, 'Cedar_Apple_Rust': 150
        }

        print("Typical balanced distribution (example):")
        total = sum(typical_distribution.values())
        for class_name, count in typical_distribution.items():
            percentage = (count / total) * 100
            print(f"   {class_name:20}: {count:4d} samples ({percentage:5.1f}%)")

    def test_with_actual_images(self, image_folder="test_images"):
        """Test model with actual plant images if available."""
        print(f"\n🌿 TESTING WITH ACTUAL IMAGES from {image_folder}")
        print("=" * 50)

        if not os.path.exists(image_folder):
            print("   ⚠ Test images folder not found")
            print("   Please add some actual plant disease images to test")
            return

        image_extensions = ('.jpg', '.jpeg', '.png', '.bmp')
        test_images = [f for f in os.listdir(image_folder)
                       if f.lower().endswith(image_extensions)]

        if not test_images:
            print("   ⚠ No images found in test folder")
            return

        # Load model
        interpreter = tf.lite.Interpreter(model_path=self.model_path)
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        for image_file in test_images[:5]:  # Test first 5 images
            image_path = os.path.join(image_folder, image_file)
            try:
                # Load and preprocess image
                img = cv2.imread(image_path)
                if img is None:
                    continue

                img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                img = cv2.resize(img, (224, 224))
                img = img.astype(np.uint8)

                # Run inference
                input_data = np.expand_dims(img, axis=0)
                interpreter.set_tensor(input_details[0]['index'], input_data)
                interpreter.invoke()
                output_data = interpreter.get_tensor(output_details[0]['index'])

                # Handle quantization
                if output_details[0]['dtype'] == np.uint8:
                    output_scale, output_zero_point = output_details[0]['quantization']
                    output_data = (output_data.astype(np.float32) - output_zero_point) * output_scale

                probabilities = tf.nn.softmax(output_data[0]).numpy()
                predicted_class = self.class_names[np.argmax(probabilities)]
                confidence = np.max(probabilities)

                print(f"   {image_file:20} → {predicted_class} ({confidence:.3f})")

            except Exception as e:
                print(f"   {image_file:20} → ERROR: {e}")

    def create_data_augmentation_plan(self):
        """Create a data augmentation plan for retraining."""
        print("\n🔄 DATA AUGMENTATION PLAN")
        print("=" * 50)

        augmentation_techniques = [
            "Random rotation (±30 degrees)",
            "Horizontal and vertical flipping",
            "Brightness adjustment (±20%)",
            "Contrast adjustment (±20%)",
            "Random zoom (90-110%)",
            "Random shear (±10%)",
            "Color jittering",
            "Random cropping and resizing"
        ]

        print("Recommended augmentation techniques:")
        for technique in augmentation_techniques:
            print(f"   ✓ {technique}")

    def retraining_strategy(self):
        """Provide retraining strategy with class weights."""
        print("\n🎯 RETRAINING STRATEGY")
        print("=" * 50)

        strategy = {
            "class_weights": "Use sklearn.utils.class_weight.compute_class_weight",
            "architecture": "MobileNetV2 (current) or try EfficientNetB0",
            "input_size": "224x224 (keep current)",
            "optimizer": "Adam with learning rate 0.001",
            "loss_function": "CategoricalCrossentropy",
            "metrics": ["accuracy", "precision", "recall"],
            "callbacks": [
                "EarlyStopping(patience=5)",
                "ReduceLROnPlateau(factor=0.5, patience=3)",
                "ModelCheckpoint(best_model.h5)"
            ]
        }

        print("Recommended retraining configuration:")
        for key, value in strategy.items():
            if isinstance(value, list):
                print(f"   {key:15}: {value[0]}")
                for item in value[1:]:
                    print(f"                 {item}")
            else:
                print(f"   {key:15}: {value}")

    def alternative_quantization_approaches(self):
        """Suggest alternative quantization approaches."""
        print("\n⚡ ALTERNATIVE QUANTIZATION APPROACHES")
        print("=" * 50)

        approaches = [
            {
                "name": "FP32 (No Quantization)",
                "description": "Full precision, larger size but best accuracy",
                "command": "converter.optimizations = [tf.lite.Optimize.DEFAULT]"
            },
            {
                "name": "Dynamic Range Quantization",
                "description": "Weights quantized to int8, activations in float32",
                "command": "converter.optimizations = [tf.lite.Optimize.DEFAULT]"
            },
            {
                "name": "Float16 Quantization",
                "description": "Weights and activations in float16, good balance",
                "command": "converter.optimizations = [tf.lite.Optimize.DEFAULT]\nconverter.target_spec.supported_types = [tf.float16]"
            }
        ]

        for approach in approaches:
            print(f"   🔹 {approach['name']}")
            print(f"      {approach['description']}")
            print(f"      Code: {approach['command']}\n")

    def generate_retraining_script(self):
        """Generate a complete retraining script."""
        script_content = '''
# COMPLETE RETRAINING SCRIPT FOR PLANT DISEASE CLASSIFICATION

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import numpy as np
import os
from sklearn.utils.class_weight import compute_class_weight

# Data preparation
def prepare_balanced_dataset(data_dir, img_size=(224, 224), batch_size=32):
    """
    Create balanced dataset with augmentation for minority classes
    """
    # Data augmentation for training
    train_datagen = tf.keras.preprocessing.image.ImageDataGenerator(
        rescale=1./255,
        rotation_range=30,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        fill_mode='nearest',
        validation_split=0.2  # 80-20 split
    )
    
    # Load training data
    train_generator = train_datagen.flow_from_directory(
        data_dir,
        target_size=img_size,
        batch_size=batch_size,
        class_mode='categorical',
        subset='training'
    )
    
    # Load validation data
    validation_generator = train_datagen.flow_from_directory(
        data_dir,
        target_size=img_size,
        batch_size=batch_size,
        class_mode='categorical',
        subset='validation'
    )
    
    return train_generator, validation_generator

# Calculate class weights
def get_class_weights(generator):
    """
    Calculate class weights to handle imbalanced data
    """
    class_weights = compute_class_weight(
        class_weight='balanced',
        classes=np.unique(generator.classes),
        y=generator.classes
    )
    return dict(enumerate(class_weights))

# Create model
def create_model(num_classes=12):
    """
    Create MobileNetV2 model with custom classifier
    """
    # Load pre-trained MobileNetV2
    base_model = tf.keras.applications.MobileNetV2(
        weights='imagenet',
        include_top=False,
        input_shape=(224, 224, 3)
    )
    
    # Freeze base model initially
    base_model.trainable = False
    
    # Add custom classifier
    model = tf.keras.Sequential([
        base_model,
        layers.GlobalAveragePooling2D(),
        layers.Dropout(0.3),
        layers.Dense(512, activation='relu'),
        layers.BatchNormalization(),
        layers.Dropout(0.5),
        layers.Dense(num_classes, activation='softmax')
    ])
    
    return model

# Compile and train
def train_model(data_dir):
    """
    Complete training pipeline
    """
    # Prepare data
    train_gen, val_gen = prepare_balanced_dataset(data_dir)
    
    # Calculate class weights
    class_weights = get_class_weights(train_gen)
    
    # Create model
    model = create_model(num_classes=len(train_gen.class_indices))
    
    # Compile model
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='categorical_crossentropy',
        metrics=['accuracy', 'precision', 'recall']
    )
    
    # Callbacks
    callbacks = [
        tf.keras.callbacks.EarlyStopping(patience=5, restore_best_weights=True),
        tf.keras.callbacks.ReduceLROnPlateau(factor=0.5, patience=3),
        tf.keras.callbacks.ModelCheckpoint('best_plant_model.h5', save_best_only=True)
    ]
    
    # Train model
    history = model.fit(
        train_gen,
        epochs=50,
        validation_data=val_gen,
        class_weight=class_weights,
        callbacks=callbacks
    )
    
    return model, history

# Convert to TFLite with proper quantization
def convert_to_tflite(model_path, quantization='float16'):
    """
    Convert trained model to TFLite with different quantization options
    """
    converter = tf.lite.TFLiteConverter.from_keras_model(model_path)
    
    if quantization == 'float16':
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
    elif quantization == 'dynamic_range':
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
    elif quantization == 'full_integer':
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.representative_dataset = representative_dataset_gen
    
    tflite_model = converter.convert()
    
    # Save the model
    with open('plant_id_model.tflite', 'wb') as f:
        f.write(tflite_model)
    
    print("✅ Improved model converted to TFLite")

# Usage:
# 1. Set your data directory
# data_directory = "path/to/your/plant/disease/dataset"
# 
# 2. Train the model
# model, history = train_model(data_directory)
# 
# 3. Convert to TFLite
# convert_to_tflite(model, quantization='float16')
'''

        with open('retrain_plant_model.py', 'w') as f:
            f.write(script_content)
        print("✅ Complete retraining script saved as 'retrain_plant_model.py'")

    def quick_fix_current_model(self):
        """Attempt to fix the current model with post-processing."""
        print("\n🔧 QUICK FIX: POST-PROCESSING APPROACH")
        print("=" * 50)

        fix_code = '''
# QUICK FIX FOR CURRENT MODEL - Post-processing wrapper
import tensorflow as tf
import numpy as np

class FixedPlantModel:
    def __init__(self, model_path):
        self.interpreter = tf.lite.Interpreter(model_path=model_path)
        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
        
        # Class names
        self.class_names = [
            'Apple', 'Bell_pepper', 'Cedar_Apple_Rust', 'Cherry', 
            'Corn', 'Grape', 'Peach', 'Potato', 
            'Soybean', 'Strawberry', 'Tomato', 'Wheat'
        ]
        
        # Confidence threshold to avoid over-prediction of Corn
        self.corn_threshold = 0.7
    
    def predict(self, image):
        # Preprocess
        if image.shape != (224, 224, 3):
            image = cv2.resize(image, (224, 224))
        
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
            # Reduce corn probability and redistribute
            corn_prob = probabilities[corn_index]
            reduction = corn_prob - 0.3  # Reduce to max 30%
            probabilities[corn_index] = 0.3
            # Redistribute to other classes
            other_indices = [i for i in range(len(probabilities)) if i != corn_index]
            total_other = np.sum(probabilities[other_indices])
            for i in other_indices:
                probabilities[i] += reduction * (probabilities[i] / total_other)
        
        return probabilities

# Usage:
# fixed_model = FixedPlantModel("plant_id_model.tflite")
# probabilities = fixed_model.predict(image)
'''

        with open('quick_fix_model.py', 'w') as f:
            f.write(fix_code)
        print("✅ Quick fix wrapper saved as 'quick_fix_model.py'")

def main():
    MODEL_PATH = "plant_id_model.tflite"  # Update this path

    if not os.path.exists(MODEL_PATH):
        print(f"❌ Model not found at: {MODEL_PATH}")
        return

    fixer = ModelFixer(MODEL_PATH)

    print("🌿 PLANT DISEASE MODEL FIXING TOOL")
    print("=" * 60)

    # Run all fixes
    fixer.create_balanced_dataset_analysis()
    fixer.test_with_actual_images()
    fixer.create_data_augmentation_plan()
    fixer.retraining_strategy()
    fixer.alternative_quantization_approaches()
    fixer.generate_retraining_script()
    fixer.quick_fix_current_model()

    print("\n" + "=" * 60)
    print("🎯 ACTION PLAN:")
    print("   1. Use 'quick_fix_model.py' for immediate fix")
    print("   2. Use 'retrain_plant_model.py' for proper retraining")
    print("   3. Balance your training dataset")
    print("   4. Try different quantization approaches")
    print("=" * 60)

if __name__ == "__main__":
    main()
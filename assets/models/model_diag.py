import tensorflow as tf

interpreter = tf.lite.Interpreter(model_path="plant_id_model.tflite")
interpreter.allocate_tensors()
output_details = interpreter.get_output_details()
print("Model output shape:", output_details[0]['shape'])
print("Output dtype:", output_details[0]['dtype'])

# Test with a red image → see which index gets highest score
import numpy as np
red_input = np.full((1, 224, 224, 3), [255, 0, 0], dtype=np.uint8)
interpreter.set_tensor(interpreter.get_input_details()[0]['index'], red_input)
interpreter.invoke()
output = interpreter.get_tensor(output_details[0]['index'])[0]
print("Red image → highest class index:", np.argmax(output))
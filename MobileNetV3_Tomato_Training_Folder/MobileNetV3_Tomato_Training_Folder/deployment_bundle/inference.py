
"""
Standalone inference script for the tomato disease TFLite model.
Usage: python inference.py path/to/image.jpg
"""
import sys
import numpy as np
from PIL import Image
import tensorflow as tf

MODEL_PATH = "tomato_disease_mobilenetv3_with_metadata.tflite"
LABELS_PATH = "labels.txt"
IMG_SIZE = (224, 224)

def load_labels(path):
    with open(path, "r") as f:
        return [line.strip() for line in f.readlines()]

def preprocess_image(image_path):
    img = Image.open(image_path).convert("RGB")
    img = img.resize(IMG_SIZE)
    arr = np.asarray(img).astype(np.float32)  # keep raw 0-255, model normalizes internally
    return np.expand_dims(arr, axis=0)

def predict(image_path):
    labels = load_labels(LABELS_PATH)

    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    input_data = preprocess_image(image_path)
    interpreter.set_tensor(input_details[0]["index"], input_data)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]["index"])[0]

    top_idx = int(np.argmax(output))
    print(f"Prediction: {labels[top_idx]}  (confidence: {output[top_idx]:.4f})")
    print("\nAll class probabilities:")
    for label, prob in sorted(zip(labels, output), key=lambda x: -x[1]):
        print(f"  {label:40s} {prob:.4f}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python inference.py path/to/image.jpg")
        sys.exit(1)
    predict(sys.argv[1])

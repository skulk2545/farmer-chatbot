import tensorflow as tf
import numpy as np
import cv2
import json
import os
from tensorflow.keras.applications.efficientnet_v2 import preprocess_input

MODEL_PATH = "../models/jowar_model.h5"
CLASSES_PATH = "../models/classes.json"
IMG_SIZE = 224

# Global variables for model and classes
_model = None
_classes = None

def load_resources():
    global _model, _classes
    if _model is None:
        if os.path.exists(MODEL_PATH):
            _model = tf.keras.models.load_model(MODEL_PATH)
        else:
            print(f"Error: Model not found at {MODEL_PATH}")
            
    if _classes is None:
        if os.path.exists(CLASSES_PATH):
            with open(CLASSES_PATH, "r") as f:
                raw_classes = json.load(f)
                # Convert string keys to int if necessary
                _classes = {int(k): v for k, v in raw_classes.items()}
                _classes = dict(sorted(_classes.items()))
        else:
            print(f"Warning: Classes file not found at {CLASSES_PATH}")
            # Fallback to default if available or empty dict
            _classes = {}

def predict_image(image):
    load_resources()
    if _model is None:
        return "Model not loaded", 0.0

    # Preprocessing
    img = cv2.cvtColor(image, cv2.COLOR_BGR2RGB) # Ensure RGB before resize
    img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
    img = np.expand_dims(img, axis=0)
    img = preprocess_input(img)

    prediction = _model.predict(img, verbose=0)
    class_index = np.argmax(prediction)
    confidence = np.max(prediction)

    if confidence < 0.5:
        return "Unknown", float(confidence)

    class_name = _classes.get(class_index, f"Class {class_index}")
    return class_name, float(confidence)

if __name__ == "__main__":
    # Test with a dummy image if run directly
    dummy_img = np.zeros((IMG_SIZE, IMG_SIZE, 3), dtype=np.uint8)
    label, conf = predict_image(dummy_img)
    print(f"Prediction: {label} ({conf:.2f})")
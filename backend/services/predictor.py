import os
import json
import cv2
import numpy as np
import tensorflow as tf
from typing import Tuple, Dict, Optional
from tensorflow.keras.applications.efficientnet_v2 import preprocess_input

from backend.utils.config import settings
from backend.utils.logger import logger

class PredictorService:
    """
    Service class responsible for loading the trained TensorFlow model
    and executing the image prediction pipeline.
    """
    def __init__(self) -> None:
        self.model: Optional[tf.keras.Model] = None
        self.classes: Optional[Dict[int, str]] = None
        self.model_path: str = settings.MODEL_PATH
        self.classes_path: str = settings.CLASSES_PATH
        self.img_size: int = settings.IMG_SIZE

    def load_resources(self) -> None:
        """
        Loads the TensorFlow model and classes mapping from the filesystem.
        Performs lazy loading to prevent multiple loads.
        
        Raises:
            FileNotFoundError: If the model file or classes mapping file is missing.
            Exception: For general errors during resource loading.
        """
        if self.model is not None and self.classes is not None:
            return

        logger.info("Initializing prediction resources...")

        # Load classes mapping
        if not os.path.exists(self.classes_path):
            error_msg = f"Classes file not found at path: {self.classes_path}"
            logger.error(error_msg)
            raise FileNotFoundError(error_msg)

        try:
            with open(self.classes_path, "r") as f:
                raw_classes = json.load(f)
                # Convert string keys to int and sort by index
                self.classes = {int(k): str(v) for k, v in raw_classes.items()}
                self.classes = dict(sorted(self.classes.items()))
            logger.info("Classes mapping loaded successfully.")
        except Exception as e:
            logger.error(f"Error parsing classes file: {str(e)}")
            raise e

        # Load Keras Model
        if not os.path.exists(self.model_path):
            error_msg = f"Model file not found at path: {self.model_path}"
            logger.error(error_msg)
            raise FileNotFoundError(error_msg)

        try:
            logger.info(f"Loading Keras model from {self.model_path}...")
            # Load model (can take a few seconds)
            self.model = tf.keras.models.load_model(self.model_path)
            logger.info("Model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load Keras model: {str(e)}")
            raise e

    def predict(self, image: np.ndarray) -> Tuple[str, float]:
        """
        Executes the prediction pipeline on the provided raw OpenCV image.
        
        Args:
            image (np.ndarray): The raw image in BGR/RGB numpy array format.
            
        Returns:
            Tuple[str, float]: A tuple containing the class name and the prediction confidence (0.0 to 1.0).
            
        Raises:
            ValueError: If the input image is invalid or empty.
            Exception: If prediction fails.
        """
        if image is None or image.size == 0:
            raise ValueError("Input image is empty or invalid.")

        self.load_resources()
        if self.model is None or self.classes is None:
            raise RuntimeError("Model or classes are not loaded.")

        try:
            # 1. Image preprocessing (RGB conversion, resizing, expansion, preprocessing)
            img = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            img = cv2.resize(img, (self.img_size, self.img_size))
            img = np.expand_dims(img, axis=0)
            img = preprocess_input(img)

            # 2. Run inference
            prediction = self.model.predict(img, verbose=0)
            class_index = int(np.argmax(prediction))
            confidence = float(np.max(prediction))

            logger.info(f"Prediction successful. Class index: {class_index}, Confidence: {confidence:.4f}")

            # 3. Apply confidence threshold
            if confidence < 0.5:
                logger.info(f"Confidence {confidence:.4f} is below threshold 0.5. Returning 'Unknown'.")
                return "Unknown", confidence

            # 4. Resolve class name
            class_name = self.classes.get(class_index, f"Class {class_index}")
            return class_name, confidence

        except Exception as e:
            logger.error(f"Prediction pipeline execution failed: {str(e)}")
            raise e

# Instantiate service singleton
predictor_service = PredictorService()

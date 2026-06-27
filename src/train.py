import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
from tensorflow.keras.applications import EfficientNetV2B0
from tensorflow.keras.applications.efficientnet_v2 import preprocess_input
import os
import json
import numpy as np

# paths
train_dir = "../dataset/train"
test_dir = "../dataset/test"

IMG_SIZE = 224
BATCH_SIZE = 16 
EPOCHS_INITIAL = 15
EPOCHS_FINE = 20

# data generators with enhanced augmentation
train_datagen = ImageDataGenerator(
    preprocessing_function=preprocess_input,
    rotation_range=20,
    width_shift_range=0.1,
    height_shift_range=0.1,
    shear_range=0.1,
    zoom_range=0.15,
    horizontal_flip=True,
    fill_mode='nearest',
    brightness_range=[0.8, 1.2]
)

# Test/Validation generator
test_datagen = ImageDataGenerator(preprocessing_function=preprocess_input)

train_data = train_datagen.flow_from_directory(
    train_dir,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical'
)

val_data = test_datagen.flow_from_directory(
    test_dir,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical'
)

# Save class indices
class_indices = train_data.class_indices
labels = {v: k for k, v in class_indices.items()}
os.makedirs("../models", exist_ok=True)
with open("../models/classes.json", "w") as f:
    json.dump(labels, f)
print(f"Saved class labels: {labels}")

# Calculate class weights
class_counts = {}
valid_image_extensions = ('.jpg', '.jpeg', '.png', '.bmp')
for class_name, index in class_indices.items():
    class_path = os.path.join(train_dir, class_name)
    # Count only valid image files
    class_counts[index] = len([
        f for f in os.listdir(class_path)
        if f.lower().endswith(valid_image_extensions)
    ])

# Calculate balanced class weights with log-smoothing to prevent extreme values
total_samples = sum(class_counts.values())
num_classes = len(class_counts)
# Using balanced weights: n_samples / (n_classes * count)
class_weights = {i: total_samples / (num_classes * count) for i, count in class_counts.items()}

# Cap extreme weights for stability
max_weight = 20.0 
class_weights = {i: min(w, max_weight) for i, w in class_weights.items()}

print(f"Calculated class weights (capped at {max_weight}): {class_weights}")

# Warning for extreme imbalance
if any(count < 50 for count in class_counts.values()):
    print("\n[WARNING] Extreme class imbalance detected!")
    for i, count in class_counts.items():
        if count < 50:
             print(f"  - Class '{labels[i]}' only has {count} samples. Accuracy will be poor for this class.")
    print("  - Recommendation: Collect more images for minority classes.\n")

# Model
base_model = EfficientNetV2B0(
    input_shape=(IMG_SIZE, IMG_SIZE, 3),
    include_top=False,
    weights='imagenet'
)
base_model.trainable = False

model = models.Sequential([
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.BatchNormalization(),
    layers.Dense(512, activation='relu', kernel_regularizer=tf.keras.regularizers.l2(0.001)),
    layers.Dropout(0.5), # Stronger dropout to prevent over-training
    layers.Dense(256, activation='relu', kernel_regularizer=tf.keras.regularizers.l2(0.001)),
    layers.Dropout(0.3),
    layers.Dense(num_classes, activation='softmax')
])

# Compile for initial training with increased label smoothing for overconfidence
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3), # Slightly higher initial LR
    loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=0.05),
    metrics=['accuracy']
)

# Callbacks
callbacks = [
    EarlyStopping(monitor='val_accuracy', patience=10, restore_best_weights=True), # Monitor val_accuracy for better generalization
    ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=5, min_lr=1e-7),
    ModelCheckpoint("../models/jowar_model_best.h5", monitor='val_accuracy', save_best_only=True)
]

print("Starting initial training...")
model.fit(
    train_data,
    validation_data=val_data,
    epochs=EPOCHS_INITIAL,
    callbacks=callbacks,
    class_weight=class_weights
)

# Fine-tuning
print("Unfreezing base model for fine-tuning...")
base_model.trainable = True
# Only unfreeze the last 80 layers
for layer in base_model.layers[:-80]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5), # Lower LR for fine-tuning
    loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=0.05),
    metrics=['accuracy']
)

print("Starting fine-tuning...")
model.fit(
    train_data,
    validation_data=val_data,
    epochs=EPOCHS_FINE,
    callbacks=callbacks,
    class_weight=class_weights
)

# Save final model
model.save("../models/jowar_model.h5")
print("Model and classes saved!")
# Jowar (Sorghum) Disease Detection

This project uses Deep Learning to detect and classify diseases in Jowar (Sorghum) crops. It uses a transfer learning approach with the EfficientNetV2B0 architecture fine-tuned on custom Jowar leaf disease images.

## Supported Diseases

The model classifies Jowar leaves into 7 distinct categories:
- Anthracnose
- Cereal Grain Molds
- Covered Kernel Smut
- Head Smut
- Rust
- Loose Smut
- Healthy (No Disease)

## Model Architecture

- **Base Model**: EfficientNetV2B0 pre-trained on ImageNet
- **Classifier Head**:
  - Global Average Pooling 2D
  - Batch Normalization
  - Dense (512 units, ReLU, L2 Regularization)
  - Dropout (0.5)
  - Dense (256 units, ReLU, L2 Regularization)
  - Dropout (0.3)
  - Dense (Softmax output for 7 classes)
- **Loss Function**: Categorical Crossentropy with Label Smoothing (0.05) to combat overconfidence.

## Directory Structure

```
├── dataset/                  # Dataset directory (gitignored due to size)
│   ├── train/                # Training images organized by class folder
│   └── test/                 # Test/Validation images organized by class folder
├── models/                   # Saved models and class indexes
│   ├── classes.json          # Mapping of class index to name
│   ├── jowar_model.h5        # Main trained model file
│   └── jowar_model_best.h5   # Best performing model file based on validation accuracy
├── src/                      # Source code
│   ├── train.py              # Script to train and fine-tune the model
│   ├── predict.py            # Inference module to load model and predict on an image
│   ├── upload.py             # CLI utility to run prediction on a user-provided image path
│   ├── realtime.py           # Real-time disease detection using webcam
│   └── test_predict.py       # Basic prediction test script
├── requirements.txt          # Python dependencies
└── .gitignore                # Git ignore file
```

## Setup & Usage

### 1. Install Dependencies

Install the required libraries:
```bash
pip install -r requirements.txt
```

### 2. Train the Model

To train the model, organize your training/test datasets into `dataset/train` and `dataset/test` respectively, then run:
```bash
cd src
python train.py
```

This will run an initial training phase (15 epochs) with the base model frozen, followed by fine-tuning (20 epochs) unfreezing the top 80 layers of the EfficientNet base model.

### 3. Run Predictions on an Image File

You can test prediction on a single image file by running:
```bash
cd src
python upload.py
```
And inputting the file path to the image when prompted.

### 4. Real-time Detection via Webcam

To run real-time camera inference:
```bash
cd src
python realtime.py
```
Press `ESC` to close the window.

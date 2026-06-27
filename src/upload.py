import cv2
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from predict import predict_image

image_path = input("Enter image path: ").strip('"')

image_path = os.path.normpath(image_path)

img = cv2.imread(image_path)

if img is None:
    print("Image not found ->", image_path)
    exit()

label, conf = predict_image(img)

if conf < 0.5:
    print("No jowar detected")
else:
    print(f"Disease: {label}")
    print(f"Confidence: {conf:.2f}")

cv2.imshow("Uploaded Image", img)
cv2.waitKey(0)
cv2.destroyAllWindows()
import cv2
from predict import predict_image

img = cv2.imread("../dataset/test/rust/rust1.jpeg")

label, conf = predict_image(img)

print(label, conf)
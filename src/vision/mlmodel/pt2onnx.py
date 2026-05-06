from ultralytics import YOLO

model = YOLO("./pt/tennis.pt")
model.export(format = "onnx")
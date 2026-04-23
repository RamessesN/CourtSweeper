from ultralytics import YOLO
from cv_config import DATA_YAML, MODEL_NAME, DEVICE

def train_model():
    print("Training model...")

    model = YOLO("./weight/yolo26n.pt")       # Loading Pre-trained model

    results = model.train(
        data = DATA_YAML,                     # Dataset configuration file
        epochs = 200,                         # Number of training rounds
        imgsz = 640,                          # Size of the training image
        batch = 16,                           # ADJUST WITH VRAM
        name = MODEL_NAME,                    # Model name
        device = DEVICE,                      # Running device
        workers = 2,                          # ADJUST WITH CORE NUM
        project = "./runs/train_tennis",      # Save model
        exist_ok = False                      # Overwrite same name experiment
    )

    print("Training Finished！")

if __name__ == "__main__":
    train_model()
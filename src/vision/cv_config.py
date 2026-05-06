import os
import torch

# dataset
DATASET_PATH: str = "./dataset/tennis"

# data yaml
DATA_YAML = os.path.join(DATASET_PATH, "data.yaml")

# model
MODEL_NAME: str = "tennis_detection_v1"

# device configuration
DEVICE: str = (
    "cuda" if torch.cuda.is_available() else
    "mps" if torch.mps.is_available() else
    "xpu" if torch.xpu.is_available() else
    "cpu"
)

# result model (weight file)
MODEL_PATH: str = "mlmodel/pt/tennis_v1.pt"
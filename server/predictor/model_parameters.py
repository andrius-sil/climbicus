import os

BASE_PATH = "/app/predictor/model_files"
MODEL_FILE_NAME = "castle_30_vgg_fine_tuned.h5"
MODEL_VERSION = "castle_30_vgg_fine_tuned"
MODEL_PATH = os.path.join(BASE_PATH, MODEL_FILE_NAME)
CLASS_INDICES_PATH = os.path.join(BASE_PATH, "class_indices.pkl")

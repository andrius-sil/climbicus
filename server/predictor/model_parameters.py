import os
import pickle


def load_obj(path):
    """Loads a pickle object"""
    with open(path, "rb") as f:
        return pickle.load(f)


BASE_PATH = "/app/predictor/"
MODEL_FILE_NAME = "castle_30_vgg_fine_tuned.h5"
MODEL_VERSION = "castle_30_vgg_fine_tuned"
MODEL_PATH = os.path.join(BASE_PATH, MODEL_FILE_NAME)
CLASS_INDICES_PATH = os.path.join(BASE_PATH, "class_indices.pkl")

class_indices = load_obj(CLASS_INDICES_PATH)

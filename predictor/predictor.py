import os
import pickle

import numpy as np

from keras.models import load_model
from PIL import Image

model_name = "castle_30_vgg_fine_tuned.h5"
model_path = os.path.join("/opt/project/model_training/", model_name)  # ideally woudl get rid of this opt/project

# TODO: Keras predicting could be slow, look into faster methods
# TODO: When run on a server, the model should always be loaded probably?
# TODO: Check what aspect ratiop Keras is using when resizing


def load_obj(path):
    """Loads the class indices dictionary"""
    with open(path, "rb") as f:
        return pickle.load(f)


def process_image(image_path):
    """
    The input image needs to be a numpy array of shape (150, 150, 3) rescaled by 1.0/255
    """
    img = Image.open(image_path)
    img = img.resize((150, 150), Image.LANCZOS)
    img = np.array(img)
    img = img / 255.0
    img = np.expand_dims(img, axis=0)
    return img


def load_and_predict(model_path, img):
    """Loads the model and class indices, makes a class prediction for a single image"""
    model = load_model(model_path)
    class_indices = load_obj("/opt/project/model_training/class_indices.pkl")

    # predicted_probabilities = model.predict(img)
    predicted_class_index_array = model.predict_classes(img)
    predicted_class_index = predicted_class_index_array[0]
    predicted_class = class_indices[predicted_class_index]
    return predicted_class


image_path = os.path.join("/opt/project/model_training/", "data/categories_castle/test/1/DSC_3878.JPG")
img = process_image(image_path)
result = load_and_predict(model_path, img)
print(f"Predicted class is: {result}")

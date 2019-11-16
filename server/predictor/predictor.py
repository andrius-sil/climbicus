import numpy as np

from PIL import Image
from tensorflow.python.keras.backend import set_session

from app import tf_graph, tf_session


# TODO: Keras predicting could be slow, look into faster methods
# TODO: Check what aspect ratio Keras is using when resizing


def process_image(image_path):
    """
    The input image needs to be a numpy array of shape (150, 150, 3) rescaled by 1.0/255
    """
    img = Image.open(image_path)
    img = img.resize((150, 150), Image.LANCZOS)  # high quality, slow method
    img = np.array(img)
    img = img / 255.0
    img = np.expand_dims(img, axis=0)
    return img


def load_and_predict(image_path, model, class_indices):
    """Makes a class prediction for a single image"""
    img = process_image(image_path)

    global tf_session
    global tf_graph
    with tf_graph.as_default():
        set_session(tf_session)
         predicted_probabilities = model.predict(img)

    predicted_class_index = np.argmax(predicted_probabilities)
    predicted_class = class_indices[predicted_class_index]
    predicted_probability = predicted_probabilities[0, predicted_class_index]
    return predicted_class, predicted_probability

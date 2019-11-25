import operator
import pickle

import numpy as np

import tensorflow as tf
from PIL import Image
from tensorflow.python.keras.backend import set_session
from tensorflow.python.keras.models import load_model

# TODO: Keras predicting could be slow, look into faster methods
# TODO: Check what aspect ratio Keras is using when resizing


class Predictor:
    def load_model(self, model_path, class_indices_path, model_version):
        self.tf_session = tf.compat.v1.Session()
        self.tf_graph = tf.compat.v1.get_default_graph()
        set_session(self.tf_session)
        self.model = load_model(model_path)
        self.model_version = model_version
        self.class_indices = self.load_class_indices(class_indices_path)

    @staticmethod
    def load_class_indices(path):
        """Loads a pickle object"""
        with open(path, "rb") as f:
            return pickle.load(f)

    @staticmethod
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

    def predict_route(self, image_path):
        """Makes a class prediction for a single image"""
        img = self.process_image(image_path)

        # this is required as explained here:
        # https://github.com/tensorflow/tensorflow/issues/28287
        with self.tf_graph.as_default():
            set_session(self.tf_session)
            predicted_probabilities = self.model.predict(img)

        predictor_results = PredictorResults(predicted_probabilities, self.class_indices,  self.model_version)

        return predictor_results

    def get_model_version(self):
        return self.model_version


class PredictorResults:
    def __init__(self, predicted_probabilities, class_indices, model_version):
        predicted_probabilities = predicted_probabilities.squeeze()  # squeeze out the redundant dimension
        predicted_classes_and_probabilities = {
            v: predicted_probabilities[k].astype(float) for k, v in class_indices.items()
        }
        self.model_version = model_version
        self.predicted_classes_and_probabilities = predicted_classes_and_probabilities
        self.sorted_class_ids = self._sort_classes_by_probability()

    def _sort_classes_by_probability(self):
        sorted_class_ids = sorted(
            self.predicted_classes_and_probabilities, key=self.predicted_classes_and_probabilities.get, reverse=True
        )
        return sorted_class_ids

    def get_sorted_class_ids(self, max_results):
        return self.sorted_class_ids[:max_results]

    def get_class_probability(self, class_id):
        return self.predicted_classes_and_probabilities.get(class_id)

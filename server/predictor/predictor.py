import pickle

import numpy as np

import tensorflow as tf
from tensorflow.python.keras.backend import set_session
from tensorflow.python.keras.models import load_model
from tensorflow.python.keras.metrics import top_k_categorical_accuracy
from tensorflow.python.keras.applications.vgg16 import preprocess_input
from tensorflow.python.keras.preprocessing import image

# TODO: Keras predicting could be slow, look into faster methods
# TODO: Check what aspect ratio Keras is using when resizing


class Predictor:
    def load_model(self, model_path, class_indices_path, model_version):
        self.tf_session = tf.compat.v1.Session()
        self.tf_graph = tf.compat.v1.get_default_graph()
        set_session(self.tf_session)
        dependencies = {
            'top_2_categorical_accuracy': self.top_2_categorical_accuracy,
            'top_3_categorical_accuracy': self.top_3_categorical_accuracy,
        }
        self.model = load_model(model_path, custom_objects=dependencies)
        self.model_version = model_version
        self.class_indices = self.load_class_indices(class_indices_path)

    @staticmethod
    def top_3_categorical_accuracy(y_true, y_pred):
        return top_k_categorical_accuracy(y_true, y_pred, k=3)

    @staticmethod
    def top_2_categorical_accuracy(y_true, y_pred):
        return top_k_categorical_accuracy(y_true, y_pred, k=2)

    @staticmethod
    def load_class_indices(path):
        """Loads a pickle object"""
        with open(path, "rb") as f:
            return pickle.load(f)

    @staticmethod
    def process_image(image_path):
        """
        The input image needs to be a numpy array of shape (224, 224, 3) and processed for VGG16
        """
        img = image.load_img(image_path, target_size=(224, 224))
        img = image.img_to_array(img)
        img = np.expand_dims(img, axis=0)
        img = preprocess_input(img)
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
    def __init__(self, probabilities, class_indices, model_version):
        probabilities = probabilities.squeeze()  # squeeze out the redundant dimension
        classes_and_probabilities = {
            v: probabilities[k].astype(float) for k, v in class_indices.items()
        }
        self.model_version = model_version
        self.classes_and_probabilities = classes_and_probabilities
        self.sorted_class_ids = self._sort_classes_by_probability()

    def _sort_classes_by_probability(self):
        sorted_class_ids = sorted(
            self.classes_and_probabilities, key=self.classes_and_probabilities.get, reverse=True
        )
        return sorted_class_ids

    def get_sorted_class_ids(self, max_results):
        return self.sorted_class_ids[:max_results]

    def get_class_probability(self, class_id):
        return self.classes_and_probabilities.get(class_id)

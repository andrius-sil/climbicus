import cv2
import time
import os
import numpy as np
from utilities.data.encoding import nparraybytes_to_nparray

NMATCHES = 5
MODEL_VERSION = "cbir_v1"
MAX_IMG_WIDTH = 512
CV_LOAD_IMAGE_GRAYSCALE = 0
MAX_FEATURES = 450
MATCH_DISTANCE_THRESHOLD = 137
MATCHER = "flann"  # or "bf"


class InvalidImageException(Exception):
    pass


class CBIRPredictor:
    """
    This class defines how the Content Based Image Retrieval predictor:
    1. Processes the image
    2. Finds descriptors
    3. Calculates distances from each image based on descriptors
    """
    def __init__(self):
        self.init_matcher(MATCHER)
        self.orb = cv2.ORB_create(MAX_FEATURES)

    def init_matcher(self, matcher):
        if matcher == "bf":
            self.matcher = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
        elif matcher == "flann":
            index_params = {
                'algorithm': 6,
                'table_number': 1,
                'key_size': 10,
                'multi_probe_level': 1
            }
            search_params = {'checks': 50}
            self.matcher = cv2.FlannBasedMatcher(index_params, search_params)
            
    def process_image(self, fbytes_image):
        """
        The input image needs to be the right format, colour and size
        JPEG compression is left for the app
        """
        img_arr = np.frombuffer(fbytes_image, np.uint8)
        img = cv2.imdecode(img_arr, CV_LOAD_IMAGE_GRAYSCALE)
        if img is None:
            raise InvalidImageException()

        # resizing required for the predictor
        w = img.shape[1]
        h = img.shape[0]
        ratio = w / MAX_IMG_WIDTH
        if ratio > 1:
            w = int(w / ratio)
            h = int(h / ratio)
        dim = (w, h)
        resized = cv2.resize(img, dim, interpolation=cv2.INTER_AREA)
        return resized

    def generate_descriptors(self, img):
        """
        Obtains keypoints and their descriptors for an image
        """
        kp, des = self.orb.detectAndCompute(img, None)
        if des is None:
            raise InvalidImageException()
        return kp, des

    def match_images(self, des_a, des_b):
        """Completes matching for a given set of (array) descriptors"""
        matches = self.matcher.match(des_a, des_b)
        matches = sorted(matches, key = lambda x: x.distance)
        dist = sum([x.distance for x in matches[:NMATCHES]])
        return matches, dist
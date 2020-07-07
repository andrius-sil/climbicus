import cv2
import time
import os
from utilities.data.encoding import nparraybytes_to_nparray

NMATCHES = 5
MODEL_VERSION = "cbir_v1"
MAX_IMG_WIDTH = 512
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

    def generate_descriptors(self, img):
        """
        Obtains keypoints and their descriptors for an image
        """
        _, des = self.orb.detectAndCompute(img, None)
        if des is None:
            raise InvalidImageException()
        return des

    def match_images(self, des_a, des_b):
        """Completes matching for a given set of descriptors"""
        matches = self.matcher.match(nparraybytes_to_nparray(des_a), nparraybytes_to_nparray(des_b))
        matches = sorted(matches, key = lambda x: x.distance)
        dist = sum([x.distance for x in matches[:NMATCHES]])
        return matches, dist
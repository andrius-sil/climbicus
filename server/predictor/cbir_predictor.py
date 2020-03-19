import cv2
import json
import numpy as np

NMATCHES = 10
MODEL_VERSION = "cbir_v1"
MAX_IMG_WIDTH = 512


class CBIRPredictor:
    """
    This class defines how the Content Based Image Retrieval predictor:
    1. Processes the image
    2. Finds descriptors
    3. Calculates distances from each image based on descriptors
    """
    def __init__(self):
        self.matcher = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
        self.orb = cv2.ORB_create()

    def get_model_version(self):
        return MODEL_VERSION

    def process_image(self, imagefile):
        """
        The input image needs to be the right format, colour and size
        JPEG compression is left for the app
        """
        img = np.fromstring(imagefile, np.uint8)
        img = cv2.imdecode(img, cv2.IMREAD_COLOR)
        # img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        # TODO: sort out the colours
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
        _, des = self.orb.detectAndCompute(img, None)
        return des

    def calc_record_distances(self, des, route_images, nmatches):
        """
        Obtains match distances for the query image with all available descriptors
        """
        for i in route_images:
            i_descriptors = np.array(json.loads(i['descriptors'])).astype('uint8')
            matches = self.matcher.match(des, i_descriptors)
            matches = sorted(matches, key=lambda x: x.distance)
            dist = sum([x.distance for x in matches[:nmatches]])
            i['distance'] = dist
        return route_images

    def predict_route(self, imagefile, route_images, top_n_categories):
        """Makes a route predictions for a single image"""
        img = self.process_image(imagefile)
        des = self.generate_descriptors(img)
        route_images = self.calc_record_distances(des, route_images, NMATCHES)
        prediction = CbirPrediction(des, top_n_categories, route_images)
        return prediction


class CbirPrediction:
    """
    This class defines individual prediction made by CBIRPredictor for a provided image
    """
    def __init__(self, des, top_n_categories, route_images):
        self.query_descriptor_json = json.dumps(des.tolist())
        self.top_n_predictions = self.find_top_predictions(route_images, top_n_categories)

    def find_top_predictions(self, route_images, top_n_categories):
        """
        Using distances from each descriptor array, finds n route_id's that match best
        """

        def distinct_with_order(seq):
            """ Distinct elements in list preserving order """
            seen = set()
            seen_add = seen.add
            return [x for x in seq if not (x['route_id'] in seen or seen_add(x['route_id']))]

        route_images_sorted = sorted(route_images, key=lambda x: x['distance'])
        distinct_prediction_route_images = distinct_with_order(route_images_sorted)
        top_n_route_images = distinct_prediction_route_images[:top_n_categories]
        return top_n_route_images

    def get_predicted_routes(self):
        return self.top_n_predictions

    def get_descriptor(self):
        return self.query_descriptor_json


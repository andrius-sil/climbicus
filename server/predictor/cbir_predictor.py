import cv2
import json
import numpy as np

NMATCHES = 10


class CbirPredictor:

    def __init__(self):
        #TODO: need to think about this more
        self.query_descriptor_json = ""

    def process_image(self, imagefile):
        """
        The input image needs to be the right format colour and size
        """
        img = np.fromstring(imagefile, np.uint8)
        img = cv2.imdecode(img, cv2.IMREAD_COLOR)
        # img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        #TODO: sort out the colours
        #TODO: compress image using cv2, but for now the app is enough
        # encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 90]
        # result, encimg = cv2.imencode('.jpg', img, encode_param)
        return img

    def get_descriptors(self, img):
        """
        Obtains keypoints and their descriptors for an image
        """
        # TODO: for now create ORB every time, maybe once is enough?
        orb = cv2.ORB_create()
        kp, des = orb.detectAndCompute(img, None)
        self.query_descriptor_json = json.dumps(des.tolist())
        return des

    def get_distances(self, des, route_images, nmatches):
        """
        Obtains match distances for the query image with all available descriptors
        """
        matcher = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
        #TODO: make sure you don't match with yourself - maybe as a test
        for i in route_images:
            i_descriptors = np.array(json.loads(i['descriptors'])).astype('uint8')
            matches = matcher.match(des, i_descriptors)
            matches = sorted(matches, key=lambda x: x.distance)
            dist = sum([x.distance for x in matches[:nmatches]])
            i['distance'] = dist
        return route_images

    def get_predictions(self, route_images, top_n_categories):
        """
        From distances from each descriptor array, finds toure id that matche best
        """

        def distinct_with_order(seq):
            """ Distinct elements in list preserving order """
            seen = set()
            seen_add = seen.add
            #TODO: check if it's right to use user_route_id here
            return [x for x in seq if not (x['user_route_id'] in seen or seen_add(x['user_route_id']))]

        route_images_sorted = sorted(route_images, key=lambda x: x['distance'])
        # TODO: a test would be good to test this functionality
        distinct_prediction_route_images = distinct_with_order(route_images_sorted)
        top_n_route_images = distinct_prediction_route_images[:top_n_categories]
        return top_n_route_images

    def predict_route(self, imagefile, route_images, top_n_categories):
        """Makes a route prediction for a single image"""
        img = self.process_image(imagefile)
        des = self.get_descriptors(img)
        route_images = self.get_distances(des, route_images, NMATCHES)
        prediction_route_images = self.get_predictions(route_images, top_n_categories)
        return prediction_route_images

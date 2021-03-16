import cv2
import time
import os
from file_processing import get_filenames

def image_detect_and_compute(detector, img_path, grey):
    """Detect and compute interest points and their descriptors."""
    img = cv2.imread(img_path)
    if grey:
        img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    else:
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    kp, des = detector.detectAndCompute(img, None)
    return img, kp, des    


def gen_descriptors(dataset_path, detector_type, no_cats, no_features, grey=True):
    """Generate descriptors for all images organised by category in a given path"""
    descriptors = {}
    # Get all descriptors
    start = time.time()
    if detector_type=='orb':
        detector = cv2.ORB_create(no_features)
    elif detector_type=='sift':
        detector = cv2.xfeatures2d.SIFT_create(nfeatures=no_features)
    else:
        print("Incorrect detector")
    for c in range(1, no_cats+1): 
        c_path = os.path.join(dataset_path, str(c))
        files = get_filenames(c_path)
        for i, f in enumerate(files):
            _, _, des = image_detect_and_compute(detector, os.path.join(dataset_path, f'{c}/{f}'), grey)
            if des is not None:
                descriptors[f'{c}/{f}'] = des
    print(f"Time elapsed generating descriptors: {time.time() - start}")
    return descriptors


def match_img(matcher, descriptors, img_name, des, nmatches):
    """Match one image with a given dict of descriptors"""
    dists = {}
    for file_name, des_i in descriptors.items():
        if img_name!=file_name: # prevent matching on itself
            matches = matcher.match(des, des_i)
            matches = sorted(matches, key = lambda x: x.distance)
            dist = sum([x.distance for x in matches[:nmatches]])
            dists[file_name] = dist
    return dists


def match_images(matcher_type, descriptors, nmatches=5):
    """Completes matching for a given set of descriptors"""
    # TODO: you don't really need to detect and compute again for each image, you have that in the dict. 
    # Match all images ORB
    d = {}
    start = time.time()
    if matcher_type=="BF":
        matcher = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
    elif matcher_type=="Flann":
        index_params = dict(algorithm=6,
                            table_number=1,  # 12
                            key_size=10,  # 20
                            multi_probe_level=1)  # 2
        search_params = dict(checks=50)
        matcher = cv2.FlannBasedMatcher(index_params, search_params)
    else: print("Incorrect matcher")
    for img_name, des in descriptors.items():
        dists = match_img(matcher, descriptors, img_name, des, nmatches)
        d[img_name] = dists
    print(f"Time elapsed matching all images: {time.time() - start}")
    return d


def get_min_dists(d):
    min_dists = {}
    for c_f, v in d.items():
        min_dist_key = min(v, key=v.get)
        min_dist_dist = min(v.values())
        min_dist_c = min_dist_key.split('/')[0]
#         min_dists[c_f] = [min_dist_c, min_dist_dist]
        min_dists[c_f] = [min_dist_key, min_dist_dist]
    return min_dists


def distinct(seq):
    # distinct elements in list preserving order
    seen = set()
    seen_add = seen.add
    return [x for x in seq if not (x in seen or seen_add(x))]


def get_top_n(d, n=3):
    top_n = {}
    for c_f, v in d.items():
        s = sorted(v, key=v.get)
        distinct_s = distinct([i.split('/')[0] for i in s])  # gets the category out of the image file name
        top_n[c_f] = distinct_s[:n]
    return top_n


def find_correct_wrong_dists(min_dists):
    correct = []
    wrong = []
    for c_f, v in min_dists.items():
        if c_f.split('/')[0] == v[0].split('/')[0]:
            correct.append(v[1])  # v[1] is ditsnace v[0] is the predicted f_c
        else:
            wrong.append(v[1]) 
    return correct, wrong
    

def get_stats(d):
    min_dists = get_min_dists(d)
    correct, wrong = find_correct_wrong_dists(min_dists)
    max_correct = max(correct)
    print(f"Max correct: {max_correct}")
    min_wrong = min(wrong)
    print(f"Min wrong: {min_wrong}")
    print(f"Total number of images: {(len(correct)+len(wrong))}")
    print(f"Number wrong: {len(wrong)}")
    number_wrong_below_threshold = len([x for x in wrong if x<max_correct])
    print(f"Number wrong below threshold: {number_wrong_below_threshold}")
    print(f"% wrong below max correct: {round(number_wrong_below_threshold/(len(correct)+len(wrong)), 2)*100}%")
    print(f"% wrong overall: {round(len(wrong)/(len(correct)+len(wrong)), 2)*100}%")
    top_n = get_top_n(d)
    correct_top_3 = []
    wrong_top_3 = []
    for c_f, cats in top_n.items():
        if any(i==c_f.split('/')[0] for i in cats):
            correct_top_3.append(c_f)
        else:
            wrong_top_3.append(c_f)  
    print(f"% wrong overall top 3: {round(len(wrong_top_3)/(len(correct_top_3)+len(wrong_top_3)), 2)*100}%")
    return correct, wrong, correct_top_3, wrong_top_3
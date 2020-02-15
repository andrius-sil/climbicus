import os

BASE_PATH = "/app/predictor/model_files"
MODEL_FILE_NAME = "vgg16_0.0001lr0_200s_0.3drop_class_weight_2020-01-12_10-35-29.h5"
MODEL_VERSION = "vgg16_0.0001lr0_200s_0.3drop_class_weight_2020-01-12_10-35-29"
MODEL_PATH = os.path.join(BASE_PATH, MODEL_FILE_NAME)
CLASS_INDICES_PATH = os.path.join(BASE_PATH, "class_indices_cafe.pkl")

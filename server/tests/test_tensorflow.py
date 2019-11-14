from keras.models import load_model
import os
from app import load_obj
from predictor.predictor import load_and_predict
from run import app
from PIL import Image
import io


base_path = "/app/predictor/"
model_name = "castle_30_vgg_fine_tuned.h5"
MODEL_PATH = os.path.join(base_path, model_name)
CLASS_INDICES_PATH = os.path.join(base_path, "class_indices.pkl")
imagefile = os.path.join(base_path, "test_image_class_1.JPG")


def test_loading_model():
    model = load_model(MODEL_PATH)
    class_indices = load_obj(CLASS_INDICES_PATH)
    predicted_class_id = load_and_predict(imagefile, model, class_indices)
    assert predicted_class_id == "1"


# def test_predict_through_api():
#     client = app.test_client()
#     with open(imagefile) as test:
#         imgStringIO = io.BytesIO(test.read())
#     predicted_class_id = client.post("/predict",
#                                      data=dict({'image': (imgStringIO, 'test.jpg')}),
#                                      content_type="'multipart/form-data'"
#                                      )
#     assert predicted_class_id == '1'

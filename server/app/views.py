from flask import abort, Blueprint, request
from predictor.predictor import load_and_predict

main_blueprint = Blueprint("main_blueprint", __name__)


@main_blueprint.route("/")
def hello_world():
    return "Flask Dockerized"


@main_blueprint.route("/predict", methods=["GET"])
def predict():
    imagefile = request.files.get("image")
    if imagefile is None:
        abort(400, description="Image file is missing")
    predicted_class = load_and_predict(imagefile)
    response = predicted_class
    return response

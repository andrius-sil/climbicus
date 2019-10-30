from flask import Flask, request
from predictor.predictor import load_and_predict

app = Flask(__name__)


@app.route("/", methods=["GET", "POST"])
def predict():
    imagefile = request.files.get("image", "")
    predicted_class = load_and_predict(imagefile)
    return predicted_class

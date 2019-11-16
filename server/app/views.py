from flask import abort, Blueprint, request
from predictor.predictor import load_and_predict, MODEL_VERSION
import os
from app import db
from app.models import RouteImages, UserRouteLog, Routes
import datetime

user_blueprint = Blueprint("user_blueprint", __name__, url_prefix="/users")
general_blueprint = Blueprint("general_blueprint", __name__)


@general_blueprint.route("/")
def hello_world():
    return "Flask Dockerized"


@user_blueprint.route("/<int:user_id>/predict", methods=["POST"])
def predict(user_id):
    imagefile = request.files.get("image")
    if imagefile is None:
        abort(400, description="Image file is missing")
    predicted_class_id, predicted_probability = load_and_predict(imagefile)
    prob = round(predicted_probability.astype(float), 4)
    response = predicted_class_id

    saved_image_path = store_image(imagefile, predicted_class_id)
    route_id = Routes.query.filter_by(class_id=predicted_class_id).one().id
    db.session.add(
        RouteImages(
            route_id=route_id,
            user_id=user_id,
            probability=prob,
            model_version=MODEL_VERSION,
            path=saved_image_path,
        )
    )
    db.session.commit()
    return response


@user_blueprint.route("/<int:user_id>/logbooks/add", methods=["POST"])
def add(user_id):
    status = request.form.get("status")
    predicted_class_id = request.form.get("predicted_class_id")
    gym_id = request.form.get("gym_id")
    if None in [status, predicted_class_id, gym_id]:
        abort(400, description="Request missing required data")

    route_id = Routes.query.filter_by(class_id=predicted_class_id).one().id
    db.session.add(
        UserRouteLog(route_id=route_id, user_id=user_id, gym_id=gym_id, status=status, log_date=datetime.datetime.now())
    )
    db.session.commit()
    return "Route status added to log"


@user_blueprint.route("/<int:user_id>/logbooks/view", methods=["GET"])
def view(user_id):
    results = UserRouteLog.query.filter_by(user_id=user_id).all()
    logbook = {}
    for r in results:
        grade = Routes.query.filter_by(id=r.route_id).one().grade
        logbook[r.id] = {"grade": grade, "log_date": r.log_date, "status": r.status}
    return logbook


def store_image(imagefile, predicted_class):
    # TODO: generate proper id for image
    timestamp = datetime.datetime.now()
    file_name = f"test_image_class_{predicted_class}_{timestamp}.jpg"
    directory = "/.temp"
    if not os.path.exists(directory):
        os.makedirs(directory)
    file_path = f"{directory}/{file_name}"
    imagefile.save(file_path)
    return file_path

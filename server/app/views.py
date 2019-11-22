import datetime
import operator
import os

from app import db, predictor
from app.models import RouteImages, Routes, UserRouteLog
from flask import Blueprint, abort, request, jsonify

users_blueprint = Blueprint("users_blueprint", __name__, url_prefix="/users")
root_blueprint = Blueprint("root_blueprint", __name__)


@root_blueprint.route("/")
def hello_world():
    return "Flask Dockerized"


@users_blueprint.route("/<int:user_id>/predict", methods=["POST"])
def predict(user_id):
    imagefile = request.files.get("image")
    if imagefile is None:
        abort(400, description="Image file is missing")
    try:
        predicted_classes_and_probabilities = predictor.predict_route(imagefile)
    except OSError:
        abort(400, description="Not a valid image")
    except Exception:
        abort(400, description="Unknown Error")
    # for now we store the class_id with max probability to db
    predicted_class_id = max(predicted_classes_and_probabilities.items(), key=operator.itemgetter(1))[0]
    probability = predicted_classes_and_probabilities[predicted_class_id]
    model_version = predictor.get_model_version()

    # will need to filter this by appropriate gym_id
    routes = db.session.query(Routes.class_id, Routes.id, Routes.grade).filter(Routes.gym_id == 1).all()
    routes_dict = {class_id: {"id": id, "grade": grade} for class_id, id, grade in routes}

    route_id = routes_dict.get(predicted_class_id).get("id")
    saved_image_path = store_image(imagefile, predicted_class_id)
    db.session.add(
        RouteImages(
            route_id=route_id,
            user_id=user_id,
            probability=probability,
            model_version=model_version,
            path=saved_image_path,
        )
    )
    db.session.commit()

    def create_route_entry(k, v):
        result = {
            "route_id": routes_dict.get(k).get("id"),
            "predicted_class_id": k,
            "probability": v,
            "grade": routes_dict.get(k).get("grade"),
        }
        return result

    response = {"route_predictions": [create_route_entry(k, v) for k, v in predicted_classes_and_probabilities.items()]}

    return jsonify(response)


@users_blueprint.route("/<int:user_id>/logbooks/add", methods=["POST"])
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


@users_blueprint.route("/<int:user_id>/logbooks/view", methods=["GET"])
def view(user_id):
    results = UserRouteLog.query.filter_by(user_id=user_id).all()
    logbook = {}
    for r in results:
        grade = Routes.query.filter_by(id=r.route_id).one().grade
        logbook[r.id] = {"grade": grade, "log_date": r.log_date, "status": r.status}
    return jsonify(logbook)


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

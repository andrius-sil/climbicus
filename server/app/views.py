from flask import abort, Blueprint, request
from predictor.predictor import load_and_predict
import os
from app import database
from app.models import RouteImages, UserRouteLog, Routes
import datetime

main_blueprint = Blueprint("main_blueprint", __name__)


@main_blueprint.route("/")
def hello_world():
    return "Flask Dockerized"


@main_blueprint.route("/predict", methods=["POST"])
def predict():
    imagefile = request.files.get("image")
    if imagefile is None:
        abort(400, description="Image file is missing")
    predicted_class_id = load_and_predict(imagefile)
    response = predicted_class_id

    saved_image_path = store_image(imagefile, predicted_class_id)
    route_id = Routes.query.filter_by(class_id=predicted_class_id).one().id
    database.add_instance(RouteImages, route_id=route_id, path=saved_image_path)
    return response


@main_blueprint.route("/add_status", methods=["POST"])
def add_route_status():
    status = request.form.get("status")
    predicted_class_id = request.form.get("predicted_class_id")
    user_id = request.form.get("user_id")
    gym_id = request.form.get("gym_id")
    if None in [status, predicted_class_id, user_id, gym_id]:
        abort(400, description="Request missing required data")

    route_id = Routes.query.filter_by(class_id=predicted_class_id).one().id
    database.add_instance(UserRouteLog,
                          route_id=route_id,
                          user_id=user_id,
                          gym_id=gym_id,
                          status=status,
                          log_date=datetime.datetime.now())
    return 'Route status added to log'


@main_blueprint.route("/fetch_logbook", methods=["GET"])
def fetch_logbook():
    user_id = request.form.get("user_id")
    if user_id is None:
        abort(400, description="user_id is missing")
    results = UserRouteLog.query.filter_by(user_id=user_id).all()
    logbook = {}
    for r in results:
        grade = Routes.query.filter_by(id=r.route_id).one().grade
        logbook[r.id] = {'grade': grade,
                         'log_date': r.log_date,
                         'status': r.status}
    return logbook


def store_image(imagefile, predicted_class):
    # TODO: generate proper id for image
    timestamp = datetime.datetime.now()
    file_name = f'test_image_class_{predicted_class}_{timestamp}.jpg'
    directory = '/.temp'
    if not os.path.exists(directory):
        os.makedirs(directory)
    file_path = f'{directory}/{file_name}'
    imagefile.save(file_path)
    return file_path

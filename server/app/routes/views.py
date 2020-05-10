import datetime
import json
import uuid

import werkzeug

from app import db, cbir_predictor, io
from app.models import RouteImages, Routes

from flask import abort, request, Blueprint, jsonify

from app.tasks import upload_test_file_task, upload_file_task
from app.utils.encoding import bytes_to_b64str
from app.utils.io import S3InputOutputProvider
from predictor.cbir_predictor import InvalidImageException

blueprint = Blueprint("routes_blueprint", __name__, url_prefix="/routes")

MAX_NUMBER_OF_PREDICTED_ROUTES = 20


@blueprint.route("/", methods=["GET"])
@blueprint.route("/<int:route_id>", methods=["GET"])
def route_list(route_id=None):
    gym_id = request.json["gym_id"]

    query = db.session.query(Routes).filter(Routes.gym_id == gym_id)
    if route_id:
        query = query.filter(Routes.id == route_id)

    gym_routes = {}
    for route in query.all():
        gym_routes[route.id] = route.api_model

    return jsonify({"routes": gym_routes})


@blueprint.route("/", methods=["POST"])
def add():
    gym_id = request.json["gym_id"]
    user_id = request.json["user_id"]
    lower_grade = request.json["lower_grade"]
    upper_grade = request.json["upper_grade"]
    category = request.json["category"]

    route = Routes(gym_id=gym_id, user_id=user_id, lower_grade=lower_grade, upper_grade=upper_grade, category=category,
                   created_at=datetime.datetime.utcnow())

    db.session.add(route)
    db.session.commit()

    return jsonify({
        "msg": "Route added",
        "route": route.api_model,
    })


@blueprint.route("/predictions_cbir", methods=["POST"])
def predict_cbir():
    json_data = json.loads(request.form["json"])
    user_id = json_data["user_id"]
    category = json_data["category"]
    gym_id = json_data["gym_id"]

    fs_image = request.files.get("image")
    if fs_image is None:
        abort(400, "image file is missing")

    query = db.session.query(RouteImages, Routes) \
        .join(Routes, Routes.id == RouteImages.route_id) \
        .filter(Routes.gym_id == gym_id, Routes.category == category)

    routes_and_images = [{"route_image": route_image, "route": route} for (route_image, route) in query.all()]

    fbytes_image = fs_image.read()
    try:
        cbir_prediction = cbir_predictor.predict_route(fbytes_image, routes_and_images, MAX_NUMBER_OF_PREDICTED_ROUTES)
    except InvalidImageException:
        abort(400, "image file is invalid")
        return
    predicted_routes_and_images = cbir_prediction.get_predicted_routes_and_images()
    descriptor = cbir_prediction.descriptor_bytes()

    sorted_route_and_image_predictions = [{
        "route_image": r["route_image"].api_model,
        "route": r["route"].api_model,
    } for r in predicted_routes_and_images]
    response = {"sorted_route_and_image_predictions": sorted_route_and_image_predictions}
    route_image = store_image(
        fs_image=fs_image,
        user_id=user_id,
        gym_id=gym_id,
        model_version=cbir_predictor.get_model_version(),
        descriptors=descriptor,
    )
    response["route_image"] = route_image.api_model

    return jsonify(response)


def upload_file(file: werkzeug.datastructures.FileStorage, remote_path):
    filepath =  io.provider.upload_filepath(remote_path)

    file.seek(0)
    b64_str = bytes_to_b64str(file.read())

    if isinstance(io.provider, S3InputOutputProvider):
        bucket = io.provider.bucket
        upload_file_task.delay(b64_str, bucket, remote_path, file.content_type)
    else:
        upload_test_file_task.delay(b64_str, filepath)

    return filepath


def store_image(fs_image, user_id, gym_id, model_version, descriptors):
    now = datetime.datetime.utcnow()
    hex_id = uuid.uuid4().hex
    imagepath = f"route_images/from_users/gym_id={gym_id}/year={now.year}/month={now.month:02d}/{hex_id}.jpg"

    saved_image_path = upload_file(fs_image, imagepath)

    route_image = RouteImages(
        user_id=user_id,
        model_version=model_version,
        path=saved_image_path,
        created_at=now,
        descriptors=descriptors,
    )
    db.session.add(route_image)
    db.session.commit()

    return route_image

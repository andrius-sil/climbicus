import datetime
import json
import uuid

from app import db, cbir_predictor, io
from app.models import RouteImages, Routes

from flask import abort, request, Blueprint, jsonify

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
        gym_routes[route.id] = {
            "user_id": route.user_id,
            "grade": route.grade,
            "created_at": route.created_at.isoformat(),
        }

    return jsonify({"routes": gym_routes})


@blueprint.route("/", methods=["POST"])
def add():
    gym_id = request.json["gym_id"]
    user_id = request.json["user_id"]
    grade = request.json["grade"]

    route = Routes(gym_id=gym_id, user_id=user_id, grade=grade, created_at=datetime.datetime.utcnow())

    db.session.add(route)
    db.session.commit()

    return jsonify({
        "id": route.id,
        "created_at": route.created_at.isoformat(),
        "msg": "Route added",
    })


@blueprint.route("/predictions_cbir", methods=["POST"])
def predict_cbir():
    json_data = json.loads(request.form["json"])
    user_id = json_data["user_id"]
    gym_id = json_data["gym_id"]

    fs_image = request.files.get("image")
    if fs_image is None:
        abort(400, "image file is missing")

    results = (
        db.session.query(RouteImages, Routes)
        .join(Routes, Routes.id == RouteImages.route_id)
        .filter(Routes.gym_id == gym_id)
        .all()
    )
    route_images = []
    for route_image, route in results:
        entry = {
            "id": route_image.id,
            "route_id": route_image.route_id,
            "grade": route.grade,
            "descriptors": route_image.descriptors,
        }
        route_images.append(entry.copy())

    fbytes_image = fs_image.read()

    try:
        cbir_prediction = cbir_predictor.predict_route(fbytes_image, route_images, MAX_NUMBER_OF_PREDICTED_ROUTES)
    except InvalidImageException:
        abort(400, "image file is invalid")
        return
    predicted_routes = cbir_prediction.get_predicted_routes()
    descriptor = cbir_prediction.get_descriptor()

    sorted_route_predictions = [{"route_id": r["route_id"], "grade": r["grade"]} for r in predicted_routes]
    response = {"sorted_route_predictions": sorted_route_predictions}
    route_image = store_image(
        fs_image=fs_image,
        user_id=user_id,
        gym_id=gym_id,
        model_version=cbir_predictor.get_model_version(),
        descriptors=descriptor,
    )
    response["route_image"] = route_image.api_model

    return jsonify(response)


def store_image(fs_image, user_id, gym_id, model_version, descriptors):
    now = datetime.datetime.utcnow()
    hex_id = uuid.uuid4().hex
    imagepath = f"route_images/from_users/{gym_id}/{now.year}/{now.month:02d}/{hex_id}.jpg"

    saved_image_path = io.provider.upload_file(fs_image, imagepath)

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

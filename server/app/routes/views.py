import datetime
import json

from app import db, cbir_predictor
from app.models import RouteImages, Routes
from app.utils.image import resize_fbytes_image

from flask import abort, request, Blueprint, jsonify

from app.tasks import store_image
from predictor.cbir_predictor import InvalidImageException

blueprint = Blueprint("routes_blueprint", __name__, url_prefix="/routes")

MAX_NUMBER_OF_PREDICTED_ROUTES = 20
MAX_THUMBNAIL_IMG_WIDTH = 128


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
    area_id = request.json["area_id"]
    lower_grade = request.json["lower_grade"]
    upper_grade = request.json["upper_grade"]
    category = request.json["category"]
    name = request.json["name"]
    colour = request.json["colour"]

    route = Routes(gym_id=gym_id, user_id=user_id, area_id=area_id, lower_grade=lower_grade, upper_grade=upper_grade,
                   category=category, name=name, created_at=datetime.datetime.utcnow(), count_ascents=0,
                   colour=colour)

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

    fbytes_image, file_content_type = fs_image.read(), fs_image.content_type
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
    image_path = store_image(
        fbytes_image=fbytes_image,
        file_content_type=file_content_type,
        dir_name="route_images",
        gym_id=gym_id,
        image_size="full_size"
    )
    thumbnail_fbytes_image = resize_fbytes_image(fbytes_image, MAX_THUMBNAIL_IMG_WIDTH)
    thumbnail_path = store_image(
        fbytes_image=thumbnail_fbytes_image,
        file_content_type=file_content_type,
        dir_name="route_images",
        gym_id=gym_id,
        image_size="thumbnail"
    )

    route_image = RouteImages(
        user_id=user_id,
        model_version=cbir_predictor.get_model_version(),
        path=image_path,
        thumbnail_path=thumbnail_path,
        created_at=datetime.datetime.utcnow(),
        descriptors=descriptor,
    )
    db.session.add(route_image)
    db.session.commit()

    response["route_image"] = route_image.api_model

    return jsonify(response)

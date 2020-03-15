import datetime
import json
import uuid

from app import db, predictor, io
from app.models import RouteImages, Routes

from flask import abort, request, Blueprint, jsonify
from predictor.cbir_predictor import CbirPredictor

blueprint = Blueprint("routes_blueprint", __name__, url_prefix="/routes")

MAX_NUMBER_OF_PREDICTED_ROUTES = 20


@blueprint.route("/", methods=["GET"])
def route_list():
    gym_id = request.json["gym_id"]

    routes = db.session.query(Routes).filter(Routes.gym_id == gym_id).all()

    gym_routes = {}
    for route in routes:
        gym_routes[route.id] = {
            "grade": route.grade,
            "created_at": route.created_at.isoformat(),
        }

    return jsonify({"routes": gym_routes})


@blueprint.route("/predictions", methods=["POST"])
def predict():
    json_data = json.loads(request.form["json"])
    user_id = json_data["user_id"]
    gym_id = json_data["gym_id"]

    imagefile = request.files.get("image")
    if imagefile is None:
        abort(400, "image file is missing")
    try:
        predictor_results = predictor.predict_route(imagefile)
    except OSError:
        abort(400, "not a valid image")

    sorted_class_ids = predictor_results.get_sorted_class_ids(max_results=MAX_NUMBER_OF_PREDICTED_ROUTES)

    routes = db.session.query(Routes).filter(Routes.gym_id == gym_id, Routes.class_id.in_(sorted_class_ids)).all()
    routes = reorder_routes_by_classes(routes, sorted_class_ids)

    sorted_route_predictions = [{"route_id": r.id, "grade": r.grade} for r in routes]
    response = {"sorted_route_predictions": sorted_route_predictions}

    route_image_id = store_image(
        imagefile=imagefile,
        user_id=user_id,
        gym_id=gym_id,
        model_route_id=routes[0].id,  # choosing the highest probability route id
        model_probability=predictor_results.get_class_probability(sorted_class_ids[0]),
        model_version=predictor_results.model_version,
    )
    response["route_image_id"] = route_image_id

    return jsonify(response)


@blueprint.route("/predictions_cbir", methods=["POST"])
def predict_cbir():
    json_data = json.loads(request.form["json"])
    user_id = json_data["user_id"]
    gym_id = json_data["gym_id"]

    imagefile = request.files.get("image")
    if imagefile is None:
        abort(400, "image file is missing")

    results = (
        db.session.query(RouteImages, Routes)
        .join(Routes, Routes.id == RouteImages.user_route_id)
        .filter(Routes.gym_id == gym_id)
        .all()
    )
    route_images = []
    for route_image, route in results:
        entry = {
            "id": route_image.id,
            "user_route_id": route_image.user_route_id,
            "grade": route.grade,
            "descriptors": route_image.descriptors
        }
        route_images.append(entry.copy())

    cbir = CbirPredictor()
    try:
        prediction_route_images = cbir.predict_route(imagefile.read(), route_images, MAX_NUMBER_OF_PREDICTED_ROUTES)
    except OSError:
        abort(400, "not a valid image")

    # the response need to be [{id, grade}, {id, grade}]

    sorted_route_predictions = [{"route_id": r['user_route_id'], "grade": r['grade']} for r in prediction_route_images]
    response = {"sorted_route_predictions": sorted_route_predictions}
    route_image_id = store_image(
        imagefile=imagefile,
        user_id=user_id,
        gym_id=gym_id,
        model_route_id=prediction_route_images[0]['user_route_id'],
        # TODO: fix the model to allow nulls here
        model_probability=-1,
        # TODO: add versioning
        model_version="test",
        descriptors=cbir.query_descriptor_json
    )
    response["route_image_id"] = route_image_id

    return jsonify(response)


def store_image(imagefile, user_id, gym_id, model_route_id, model_probability, model_version, descriptors):
    now = datetime.datetime.utcnow()
    hex_id = uuid.uuid4().hex
    imagepath = f"route_images/from_users/{gym_id}/{now.year}/{now.month:02d}/{hex_id}.jpg"

    saved_image_path = io.provider.upload_file(imagefile, imagepath)

    route_image = RouteImages(
        user_id=user_id,
        model_route_id=model_route_id,
        model_probability=model_probability,
        model_version=model_version,
        path=saved_image_path,
        created_at=now,
        descriptors=descriptors,
    )
    db.session.add(route_image)
    db.session.commit()

    return route_image.id


def reorder_routes_by_classes(routes, sorted_class_ids):
    route_map = {r.class_id: r for r in routes}
    sorted_routes = [route_map[c] for c in sorted_class_ids]
    return sorted_routes

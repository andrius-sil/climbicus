import datetime
import json
import uuid

from app import db, cls_predictor, cbir_predictor, io
from app.models import RouteImages, Routes

from flask import abort, request, Blueprint, jsonify

from app.utils.encoding import bytes_to_b64str

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


@blueprint.route("/", methods=["POST"])
def add():
    gym_id = request.json["gym_id"]
    grade = request.json["grade"]

    route = Routes(gym_id=gym_id, grade=grade, created_at=datetime.datetime.utcnow())

    db.session.add(route)
    db.session.commit()

    return jsonify({
        "id": route.id,
        "created_at": route.created_at.isoformat(),
        "msg": "Route added",
    })


@blueprint.route("/predictions_cls", methods=["POST"])
def predict_cls():
    json_data = json.loads(request.form["json"])
    user_id = json_data["user_id"]
    gym_id = json_data["gym_id"]

    imagefile = request.files.get("image")
    if imagefile is None:
        abort(400, "image file is missing")
    try:
        predictor_results = cls_predictor.predict_route(imagefile)
    except OSError:
        abort(400, "not a valid image")

    sorted_class_ids = predictor_results.get_sorted_class_ids(max_results=MAX_NUMBER_OF_PREDICTED_ROUTES)

    routes = db.session.query(Routes).filter(Routes.gym_id == gym_id, Routes.class_id.in_(sorted_class_ids)).all()
    routes = reorder_routes_by_classes(routes, sorted_class_ids)

    sorted_route_predictions = [{"route_id": r.id, "grade": r.grade} for r in routes]
    response = {"sorted_route_predictions": sorted_route_predictions}

    route_image_id = store_image(
        fs_image=imagefile,
        user_id=user_id,
        gym_id=gym_id,
        model_probability=predictor_results.get_class_probability(sorted_class_ids[0]),
        model_version=predictor_results.model_version,
        descriptors="placeholder",
    )
    response["route_image_id"] = route_image_id

    return jsonify(response)


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

    cbir_prediction = cbir_predictor.predict_route(fbytes_image, route_images, MAX_NUMBER_OF_PREDICTED_ROUTES)
    predicted_routes = cbir_prediction.get_predicted_routes()
    descriptor = cbir_prediction.get_descriptor()

    sorted_route_predictions = [{"route_id": r["route_id"], "grade": r["grade"]} for r in predicted_routes]
    response = {"sorted_route_predictions": sorted_route_predictions}
    route_image_id = store_image(
        fs_image=fs_image,
        user_id=user_id,
        gym_id=gym_id,
        model_version=cbir_predictor.get_model_version(),
        descriptors=descriptor,
    )
    response["route_image_id"] = route_image_id
    response["b64_image"] = bytes_to_b64str(fbytes_image)

    return jsonify(response)


def store_image(fs_image, user_id, gym_id, model_version, descriptors, model_probability=None):
    now = datetime.datetime.utcnow()
    hex_id = uuid.uuid4().hex
    imagepath = f"route_images/from_users/{gym_id}/{now.year}/{now.month:02d}/{hex_id}.jpg"

    saved_image_path = io.provider.upload_file(fs_image, imagepath)

    route_image = RouteImages(
        user_id=user_id,
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

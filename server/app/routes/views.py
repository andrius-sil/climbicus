import datetime
import json
import uuid

from app import db, predictor, io
from app.models import RouteImages, Routes, THE_CASTLE_ID

from flask import abort, request, Blueprint, jsonify

blueprint = Blueprint("routes_blueprint", __name__, url_prefix="/routes")

MAX_NUMBER_OF_PREDICTED_ROUTES = 20


@blueprint.route("/predictions", methods=["POST"])
def predict():
    json_data = json.loads(request.form["json"])
    user_id = json_data["user_id"]

    imagefile = request.files.get("image")
    if imagefile is None:
        abort(400, "image file is missing")
    try:
        predictor_results = predictor.predict_route(imagefile)
    except OSError:
        abort(400, "not a valid image")

    sorted_class_ids = predictor_results.get_sorted_class_ids(max_results=MAX_NUMBER_OF_PREDICTED_ROUTES)

    routes = db.session.query(Routes).filter(Routes.gym_id == THE_CASTLE_ID, Routes.class_id.in_(sorted_class_ids)).all()
    routes = reorder_routes_by_classes(routes, sorted_class_ids)

    sorted_route_predictions = [{"route_id": r.id, "grade": r.grade} for r in routes]
    response = {"sorted_route_predictions": sorted_route_predictions}

    route_image_id = store_image(
        imagefile=imagefile,
        user_id=user_id,
        model_route_id=routes[0].id,  # choosing the highest probability route id
        model_probability=predictor_results.get_class_probability(sorted_class_ids[0]),
        model_version=predictor_results.model_version
    )
    response["route_image_id"] = route_image_id

    return jsonify(response)


def store_image(imagefile, user_id, model_route_id, model_probability, model_version):
    now = datetime.datetime.now()
    hex_id = uuid.uuid4().hex
    imagepath = f"route_images/from_users/{THE_CASTLE_ID}/{now.year}/{now.month:02d}/{hex_id}.jpg"

    saved_image_path = io.provider.upload_file(imagefile, imagepath)

    route_image = RouteImages(
        user_id=user_id,
        model_route_id=model_route_id,
        model_probability=model_probability,
        model_version=model_version,
        path=saved_image_path,
        created_at=now,
    )
    db.session.add(route_image)
    db.session.commit()

    return route_image.id


def reorder_routes_by_classes(routes, sorted_class_ids):
    route_map = {r.class_id: r for r in routes}
    sorted_routes = [route_map[c] for c in sorted_class_ids]
    return sorted_routes

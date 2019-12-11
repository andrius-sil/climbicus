import base64
import datetime
import os

from sqlalchemy import func

from app import db, predictor, io
from app.models import RouteImages, Routes, UserRouteLog

from flask import abort, request, Blueprint, jsonify

blueprint = Blueprint("users_blueprint", __name__, url_prefix="/users")

MAX_NUMBER_OF_PREDICTED_ROUTES = 20


@blueprint.route("/<int:user_id>/predict", methods=["POST"])
def predict(user_id):
    imagefile = request.files.get("image")
    if imagefile is None:
        abort(400, description="Image file is missing")
    try:
        predictor_results = predictor.predict_route(imagefile)
    except OSError:
        abort(400, description="Not a valid image")

    sorted_class_ids = predictor_results.get_sorted_class_ids(max_results=MAX_NUMBER_OF_PREDICTED_ROUTES)

    # will need to filter this by appropriate gym_id
    routes = db.session.query(Routes).filter(Routes.gym_id == 1, Routes.class_id.in_(sorted_class_ids)).all()
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


@blueprint.route("/<int:user_id>/logbooks/add", methods=["POST"])
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


@blueprint.route("/<int:user_id>/logbooks/view", methods=["GET"])
def view(user_id):
    results = UserRouteLog.query.filter_by(user_id=user_id).all()
    logbook = {}
    for r in results:
        grade = Routes.query.filter_by(id=r.route_id).one().grade
        logbook[r.id] = {"grade": grade, "log_date": r.log_date, "status": r.status}
    return jsonify(logbook)


@blueprint.route("/<int:user_id>/route_images", methods=["GET"])
def route_images(user_id):
    if not request.is_json:
        abort(400, "Request data should be in JSON format")
    route_ids = request.json["route_ids"]

    route_id_colname = "model_route_id"
    route_id_col = getattr(RouteImages, route_id_colname)

    subquery = db.session.query(
        RouteImages,
        func.row_number().over(
            order_by=(RouteImages.user_id == user_id).desc(),
            partition_by=route_id_col,
        ).label("rank"),
     ) \
        .filter(route_id_col.in_(route_ids)) \
        .subquery()

    q = db.session.query(RouteImages) \
        .select_entity_from(subquery) \
        .filter(subquery.c.rank == 1)

    images = {}
    for route_image in q:
        filepath = io.provider.download_file(route_image.path)
        with open(filepath, "rb") as f:
            base64_bytes = base64.b64encode(f.read())
            base64_str = base64_bytes.decode("utf-8")
            images[getattr(route_image, route_id_colname)] = base64_str

    return jsonify({"route_images": images})


@blueprint.route("/<int:user_id>/route_match/<int:route_image_id>", methods=["PATCH"])
def route_match(user_id, route_image_id):
    user_match = int(request.form["is_match"])
    user_route_id = request.form.get("route_id")

    route_image = db.session.query(RouteImages).filter_by(id=route_image_id, user_id=user_id).one()
    if user_match == 1:
        route_image.user_route_id = user_route_id
    else:
        route_image.user_route_unmatched = True
    db.session.commit()

    return "Route image updated with user's route id choice"


def store_image(imagefile, user_id, model_route_id, model_probability, model_version):
    # TODO: generate proper id for image
    timestamp = datetime.datetime.now()
    file_name = f"test_image_class_{model_route_id}_{timestamp}.jpg"
    saved_image_path = io.provider.upload_file(imagefile, file_name)

    route_image = RouteImages(
        user_id=user_id,
        model_route_id=model_route_id,
        model_probability=model_probability,
        model_version=model_version,
        path=saved_image_path,
    )
    db.session.add(route_image)
    db.session.commit()

    return route_image.id


def reorder_routes_by_classes(routes, sorted_class_ids):
    route_map = {r.class_id: r for r in routes}
    sorted_routes = [route_map[c] for c in sorted_class_ids]
    return sorted_routes

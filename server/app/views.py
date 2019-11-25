import datetime
import os


from app import db, predictor
from app.models import RouteImages, Routes, UserRouteLog

from flask import abort, request, Blueprint, jsonify

users_blueprint = Blueprint("users_blueprint", __name__, url_prefix="/users")

MAX_NUMBER_OF_PREDICTED_ROUTES = 20


@users_blueprint.route("/<int:user_id>/predict", methods=["POST"])
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

    store_image(
        imagefile=imagefile,
        user_id=user_id,
        model_route_id=routes[0].id,  # choosing the highest probability route id
        model_probability=predictor_results.get_class_probability(sorted_class_ids[0]),
        model_version=predictor_results.model_version
    )

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


def store_image_to_s3(imagefile, model_route_id):
    # TODO: generate proper id for image
    timestamp = datetime.datetime.now()
    file_name = f"test_image_class_{model_route_id}_{timestamp}.jpg"
    directory = "/.temp"
    if not os.path.exists(directory):
        os.makedirs(directory)
    file_path = f"{directory}/{file_name}"
    imagefile.save(file_path)
    return file_path


def store_image(imagefile, user_id, model_route_id, model_probability, model_version):
    saved_image_path = store_image_to_s3(imagefile, model_route_id)

    db.session.add(
        RouteImages(
            user_id=user_id,
            model_route_id=model_route_id,
            model_probability=model_probability,
            model_version=model_version,
            path=saved_image_path,
        )
    )
    db.session.commit()


def reorder_routes_by_classes(routes, sorted_class_ids):
    route_map = {r.class_id: r for r in routes}
    sorted_routes = [route_map[c] for c in sorted_class_ids]
    return sorted_routes

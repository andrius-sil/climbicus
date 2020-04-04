from sqlalchemy import func

from app import db, io
from app.models import RouteImages

from flask import request, Blueprint, jsonify

blueprint = Blueprint("route_images_blueprint", __name__, url_prefix="/route_images")


@blueprint.route("/", methods=["GET"])
def route_images():
    route_ids = request.json["route_ids"]

    subquery = db.session.query(
        RouteImages,
        func.row_number().over(
            order_by=RouteImages.created_at.asc(),
            partition_by=RouteImages.route_id,
        ).label("rank"),
     ) \
        .filter(RouteImages.route_id.in_(route_ids)) \
        .subquery()

    q = db.session.query(RouteImages) \
        .select_entity_from(subquery) \
        .filter(subquery.c.rank == 1)

    images = {route_image.route_id: route_image.api_model for route_image in q}
    return jsonify({"route_images": images})


@blueprint.route("/route/<int:route_id>", methods=["GET"])
def all_route_images(route_id):
    q = db.session.query(RouteImages) \
        .filter(RouteImages.route_id == route_id)

    images = [route_image.api_model for route_image in q]
    return jsonify({"route_images": images})


@blueprint.route("/<int:route_image_id>", methods=["PATCH"])
def route_match(route_image_id):
    user_id = request.json["user_id"]
    user_match = int(request.json["is_match"])
    route_id = request.json["route_id"]

    route_image = db.session.query(RouteImages).filter_by(id=route_image_id, user_id=user_id).one()
    if user_match == 1:
        route_image.route_id = route_id
    else:
        route_image.route_unmatched = True
    db.session.commit()

    return jsonify({
        "msg": "Route image updated with user's route id choice",
        "route_image": route_image.api_model,
    })

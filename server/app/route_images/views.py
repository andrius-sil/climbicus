import base64

from sqlalchemy import func

from app import db, io
from app.models import RouteImages

from flask import request, Blueprint, jsonify

blueprint = Blueprint("route_images_blueprint", __name__, url_prefix="/route_images")


@blueprint.route("/", methods=["GET"])
def route_images():
    user_id = request.json["user_id"]
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
        fbytes = io.provider.download_file(route_image.path)
        base64_bytes = base64.b64encode(fbytes)
        base64_str = base64_bytes.decode("utf-8")

        images[getattr(route_image, route_id_colname)] = {
            "route_image_id": route_image.id,
            "b64_image": base64_str,
        }

    return jsonify({"route_images": images})


@blueprint.route("/<int:route_image_id>", methods=["PATCH"])
def route_match(route_image_id):
    user_id = request.json["user_id"]
    user_match = int(request.json["is_match"])
    user_route_id = request.json["route_id"]

    route_image = db.session.query(RouteImages).filter_by(id=route_image_id, user_id=user_id).one()
    if user_match == 1:
        route_image.user_route_id = user_route_id
    else:
        route_image.user_route_unmatched = True
    db.session.commit()

    return jsonify({"msg": "Route image updated with user's route id choice"})

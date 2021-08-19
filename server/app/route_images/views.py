import datetime

import json
from sqlalchemy import func

from app import db
from app.models import RouteImages

from flask import request, Blueprint, jsonify, abort

from app.routes.views import MAX_THUMBNAIL_IMG_WIDTH
from app.tasks import store_image
from app.utils.image import resize_fbytes_image

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


@blueprint.route("/", methods=["POST"])
def add():
    json_data = json.loads(request.form["json"])
    user_id = json_data["user_id"]
    gym_id = json_data["gym_id"]

    fs_image = request.files.get("image")
    if fs_image is None:
        abort(400, "image file is missing")

    fbytes_image, file_content_type = fs_image.read(), fs_image.content_type

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
        model_version="none",
        path=image_path,
        thumbnail_path=thumbnail_path,
        created_at=datetime.datetime.utcnow(),
        descriptors=b'\x00',
    )

    db.session.add(route_image)
    db.session.commit()

    return jsonify({
        "msg": "Route image added",
        "route_image": route_image.api_model,
    })


@blueprint.route("/<int:route_image_id>", methods=["PATCH"])
def route_match(route_image_id):
    user_id = request.json["user_id"]
    user_match = int(request.json["is_match"])
    route_id = request.json["route_id"]

    route_image = db.session.query(RouteImages).filter_by(id=route_image_id, user_id=user_id).one()
    if user_match == 1:
        route_image.route_id = route_id
        route_image.route_unmatched = False
    else:
        route_image.route_id = None
        route_image.route_unmatched = True
    db.session.commit()

    return jsonify({
        "msg": "Route image updated with user's route id choice",
        "route_image": route_image.api_model,
    })

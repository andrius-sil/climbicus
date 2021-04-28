import json

import datetime
from flask import Blueprint, jsonify, request, abort

from app import db
from app.models import Areas
from app.tasks import store_image
from app.utils.image import resize_fbytes_image

blueprint = Blueprint("areas_blueprint", __name__, url_prefix="/areas")

MAX_THUMBNAIL_IMG_WIDTH = 512


@blueprint.route("/", methods=["GET"])
def areas_list():
    gym_id = request.json["gym_id"]

    query = db.session.query(Areas).filter(Areas.gym_id == gym_id)
    areas = { area.id: area.api_model for area in query.all() }

    return jsonify({"areas": areas})


@blueprint.route("/", methods=["POST"])
def add_area():
    json_data = json.loads(request.form["json"])
    user_id = json_data["user_id"]
    gym_id = json_data["gym_id"]
    name = json_data["name"]

    fs_image = request.files.get("image")
    if fs_image is None:
        abort(400, "image file is missing")
    fbytes_image, file_content_type = fs_image.read(), fs_image.content_type

    # TODO: verify that file is a valid image
    image_path = store_image(
        fbytes_image=fbytes_image,
        file_content_type=file_content_type,
        dir_name="area_images",
        gym_id=gym_id,
        image_size="full_size"
    )
    thumbnail_fbytes_image = resize_fbytes_image(fbytes_image, MAX_THUMBNAIL_IMG_WIDTH)
    thumbnail_image_path = store_image(
        fbytes_image=thumbnail_fbytes_image,
        file_content_type=file_content_type,
        dir_name="area_images",
        gym_id=gym_id,
        image_size="thumbnail"
    )

    area = Areas(gym_id=gym_id, user_id=user_id, name=name, image_path=image_path, thumbnail_image_path=thumbnail_image_path,
                 created_at=datetime.datetime.utcnow())

    db.session.add(area)
    db.session.commit()

    return jsonify({
        "msg": "Area added",
        "area": area.api_model,
    })

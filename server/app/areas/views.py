from flask import Blueprint, jsonify

from app import db
from app.models import Areas

blueprint = Blueprint("areas_blueprint", __name__, url_prefix="/areas")

@blueprint.route("/", methods=["GET"])
def areas_list():
    query = db.session.query(Areas)
    areas = { area.id: area.api_model for area in query.all() }

    return jsonify({"areas": areas})

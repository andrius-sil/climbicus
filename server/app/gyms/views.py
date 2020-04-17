from flask import Blueprint, jsonify

from app import db
from app.models import Gyms

blueprint = Blueprint("gyms_blueprint", __name__, url_prefix="/gyms")

@blueprint.route("/", methods=["GET"])
def gyms_list():
    query = db.session.query(Gyms)
    gyms = { gym.id: gym.api_model for gym in query.all() }

    return jsonify({"gyms": gyms})

from flask import Blueprint, jsonify

from app import db
from app.models import Users

blueprint = Blueprint("users_blueprint", __name__, url_prefix="/users")

@blueprint.route("/", methods=["GET"])
def users_list():
    query = db.session.query(Users)
    users = { user.id: user.api_model for user in query.all() }

    return jsonify({"users": users})

from flask import Blueprint, jsonify, request

from app import db
from app.models import Users

blueprint = Blueprint("users_blueprint", __name__, url_prefix="/users")

@blueprint.route("/", methods=["GET"])
def users_list():
    user_ids = request.json.get("user_ids")

    query = db.session.query(Users)
    if user_ids:
        query = query.filter(Users.id.in_(user_ids))
    users = { user.id: user.api_model for user in query.all() }

    return jsonify({"users": users})

from flask import Blueprint, request, abort, jsonify, current_app
from flask_jwt_extended import create_access_token

from app.app_handlers import no_jwt_required
from app.models import Users

blueprint = Blueprint("root_blueprint", __name__)


@blueprint.route("/login", methods=["POST"])
@no_jwt_required
def login():
    if not request.is_json:
        abort(400, "Request data should be in JSON format")

    email = request.json.get("email", None)
    password = request.json.get("password", None)

    error = None

    user = Users.query.filter_by(email=email).one_or_none()
    if not user or not user.check_password(password):
        error = "incorrect email and password"

    if error:
        abort(401, error)

    current_app.logger.info(f"logging in as '{email}'")

    access_token = create_access_token(identity=user.id)
    return jsonify(
        access_token=access_token,
        user_id=user.id,
    )


@blueprint.route("/", methods=["GET"])
def hello_world():
    return "Keep calm and crimp harder"


@blueprint.route("/internal_server_error", methods=["GET"])
@no_jwt_required
def internal_server_error():
    """
    For testing purposes only.
    """
    raise Exception("wut")

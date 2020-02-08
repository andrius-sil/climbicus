import json

from flask import request, current_app, abort
from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity


def register_handlers(app):
    @app.before_request
    def check_auth_required():
        if app.config["DISABLE_AUTH"]:
            return

        if not request.endpoint:
            return

        view = current_app.view_functions[request.endpoint]
        if not getattr(view, "jwt_auth_required", True):
            return

        verify_jwt_in_request()
        verify_request_data()
        verify_user_identity()


def no_jwt_required(fn):
    fn.jwt_auth_required = False
    return fn


def verify_request_data():
    if not ("json" in request.form or request.is_json):
        abort(400, "request data must be in json or contain json")


def verify_user_identity():
    if "json" in request.form:
        json_data = json.loads(request.form["json"])
    else:
        json_data = request.json

    user_id = json_data.get("user_id")

    if user_id is None:
        abort(400, "'user_id' is missing from the request data")

    if get_jwt_identity() != int(user_id):
        abort(401, "user is not authorized to access the resource")

from flask import request, current_app
from flask_jwt_extended import verify_jwt_in_request


def register_handlers(app):
    @app.before_request
    def check_auth_required():
        if not request.endpoint:
            return

        view = current_app.view_functions[request.endpoint]
        if not getattr(view, "jwt_auth_required", True):
            return

        verify_jwt_in_request()


def no_jwt_required(fn):
    fn.jwt_auth_required = False
    return fn

from flask import Blueprint

main_blueprint = Blueprint("main_blueprint", __name__)


@main_blueprint.route("/")
def hello_world():
    return "Flask Dockerized"

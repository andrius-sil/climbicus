import datetime

from app import db
from app.models import Routes, UserRouteLog

from flask import request, Blueprint, jsonify

blueprint = Blueprint("user_route_log_blueprint", __name__, url_prefix="/user_route_log")


@blueprint.route("/", methods=["POST"])
def add():
    user_id = request.json["user_id"]
    completed = request.json["completed"]
    num_attempts = request.json["num_attempts"]
    route_id = request.json["route_id"]
    gym_id = request.json["gym_id"]

    log_entry = UserRouteLog(route_id=route_id, user_id=user_id, gym_id=gym_id, completed=completed,
                             num_attempts=num_attempts, created_at=datetime.datetime.utcnow())

    db.session.add(log_entry)
    db.session.commit()

    return jsonify({
        "msg": "Route status added to log",
        "user_route_log": log_entry.api_model,
    })


@blueprint.route("/", methods=["GET"])
@blueprint.route("/<int:route_id>", methods=["GET"])
def view(route_id=None):
    user_id = request.json["user_id"]
    gym_id = request.json["gym_id"]

    query = db.session.query(UserRouteLog) \
        .filter_by(user_id=user_id, gym_id=gym_id)
    if route_id:
        query = query.filter_by(route_id=route_id)

    logbook = {}
    for user_route_log in query.all():
        logbook[user_route_log.id] = user_route_log.api_model
    return jsonify(logbook)

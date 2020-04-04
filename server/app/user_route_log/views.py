import datetime

from app import db
from app.models import Routes, UserRouteLog

from flask import request, Blueprint, jsonify

blueprint = Blueprint("user_route_log_blueprint", __name__, url_prefix="/user_route_log")


@blueprint.route("/", methods=["POST"])
def add():
    user_id = request.json["user_id"]
    status = request.json["status"]
    route_id = request.json["route_id"]
    gym_id = request.json["gym_id"]

    log_entry = UserRouteLog(route_id=route_id, user_id=user_id, gym_id=gym_id, status=status,
                             created_at=datetime.datetime.utcnow())

    db.session.add(log_entry)
    db.session.commit()

    return jsonify({
        "id": log_entry.id,
        "created_at": log_entry.created_at.isoformat(),
        "msg": "Route status added to log",
    })


@blueprint.route("/", methods=["GET"])
@blueprint.route("/<int:route_id>", methods=["GET"])
def view(route_id=None):
    user_id = request.json["user_id"]
    gym_id = request.json["gym_id"]

    query = db.session.query(UserRouteLog, Routes) \
        .filter_by(user_id=user_id, gym_id=gym_id)
    if route_id:
        query = query.filter_by(route_id=route_id)
    query = query.join(Routes)

    logbook = {}
    for user_route_log, route in query.all():
        logbook[user_route_log.id] = {
            "route_id": route.id,
            "user_id": route.user_id,
            "grade": route.grade,
            "created_at": user_route_log.created_at.isoformat(),
            "status": user_route_log.status,
        }
    return jsonify(logbook)

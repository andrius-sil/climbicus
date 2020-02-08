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

    db.session.add(
        UserRouteLog(route_id=route_id, user_id=user_id, gym_id=gym_id, status=status,
                     created_at=datetime.datetime.now())
    )
    db.session.commit()
    return "Route status added to log"


@blueprint.route("/", methods=["GET"])
def view():
    user_id = request.json["user_id"]
    gym_id = request.json["gym_id"]

    results = db.session.query(UserRouteLog, Routes) \
        .filter_by(user_id=user_id, gym_id=gym_id) \
        .join(Routes) \
        .all()
    logbook = {}
    for user_route_log, route in results:
        logbook[user_route_log.id] = {
            "route_id": route.id,
            "grade": route.grade,
            "created_at": user_route_log.created_at.isoformat(),
            "status": user_route_log.status,
        }
    return jsonify(logbook)

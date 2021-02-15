import datetime

from app import db
from app.models import Routes, UserRouteLog

from flask import request, Blueprint, jsonify, abort
from sqlalchemy.orm.exc import NoResultFound

blueprint = Blueprint("user_route_log_blueprint", __name__, url_prefix="/user_route_log")


def update_count_ascents(route_id, change_in_count):
    route_entry = db.session.query(Routes).filter_by(id=route_id).one()
    route_entry.count_ascents += change_in_count
    return route_entry


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

    updated_route = update_count_ascents(route_id, num_attempts or 1)
    db.session.commit()

    return jsonify({
        "msg": "Route status added to log",
        "user_route_log": log_entry.api_model,
        "route": updated_route.api_model,
    })


@blueprint.route("/", methods=["GET"])
@blueprint.route("/<int:route_id>", methods=["GET"])
def view(route_id=None):
    user_id = request.json["user_id"]
    gym_id = request.json["gym_id"]

    query = db.session.query(UserRouteLog).filter_by(gym_id=gym_id)
    if route_id:
        query = query.filter_by(route_id=route_id)
    else:
        query = query.filter_by(user_id=user_id)

    logbook = {}
    for user_route_log in query.all():
        logbook[user_route_log.id] = user_route_log.api_model
    return jsonify(logbook)


@blueprint.route("/<int:user_route_log_id>", methods=["DELETE"])
def delete(user_route_log_id=None):

    query = db.session.query(UserRouteLog).filter_by(id=user_route_log_id)
    try:
        user_route_log = query.one()
    except NoResultFound:
        abort(400, "invalid user_route_log_id")

    change_in_count = user_route_log.num_attempts or 1
    updated_route = update_count_ascents(user_route_log.route_id, -change_in_count)
    db.session.commit()

    _ = query.delete()
    db.session.commit()

    return jsonify({
        "msg": "user_route_log entry was successfully deleted",
        "route": updated_route.api_model,
    })

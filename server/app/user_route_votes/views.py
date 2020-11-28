import datetime
import statistics

from app import db
from app.models import Routes, UserRouteVotes, RouteDifficulty

from flask import request, Blueprint, jsonify, abort
from sqlalchemy.exc import DataError, IntegrityError
from sqlalchemy.orm.exc import NoResultFound


blueprint = Blueprint("user_route_votes_blueprint", __name__, url_prefix="/user_route_votes")


def update_avg_route_votes(route_id, quality, difficulty):
    votes = db.session.query(UserRouteVotes).filter_by(route_id=route_id).all()
    route_entry = db.session.query(Routes).filter_by(id=route_id).one()

    if difficulty:
        difficulty_votes = [v.difficulty.value for v in votes if v.difficulty is not None]
        avg_difficulty = round(statistics.mean(difficulty_votes), 0)
        route_entry.avg_difficulty = RouteDifficulty(avg_difficulty)

    if quality:
        quality_votes = [v.quality for v in votes if v.quality is not None]
        avg_quality = round(statistics.mean(quality_votes), 0)
        route_entry.avg_quality = avg_quality

    return route_entry


@blueprint.route("/", methods=["POST"])
def add():
    user_id = request.json["user_id"]
    quality = request.json["quality"]
    difficulty = request.json["difficulty"]
    route_id = request.json["route_id"]
    gym_id = request.json["gym_id"]

    votes_entry = UserRouteVotes(route_id=route_id, user_id=user_id, gym_id=gym_id, quality=quality,
                                 difficulty=difficulty, created_at=datetime.datetime.utcnow())

    db.session.add(votes_entry)
    try:
        db.session.commit()
    except IntegrityError:
        abort(409, "the request does not pass database constraints")
    except DataError:
        abort(400, "the request contains invalid input value")

    updated_route = update_avg_route_votes(route_id, quality, difficulty)
    db.session.commit()

    return jsonify({
        "msg": "Route votes entry added",
        "user_route_votes": votes_entry.api_model,
        "route": updated_route.api_model,
    })

@blueprint.route("/", methods=["GET"])
@blueprint.route("/<int:route_id>", methods=["GET"])
def view(route_id=None):
    user_id = request.json["user_id"]
    gym_id = request.json["gym_id"]

    query = db.session.query(UserRouteVotes) \
        .filter_by(user_id=user_id, gym_id=gym_id)
    if route_id:
        query = query.filter_by(route_id=route_id)

    votes = {}
    for user_route_vote in query.all():
        votes[user_route_vote.id] = user_route_vote.api_model
    return jsonify(votes)


@blueprint.route("/<int:user_route_votes_id>", methods=["PATCH"])
def update(user_route_votes_id=None):
    quality = request.json["quality"]
    difficulty = request.json["difficulty"]

    query = db.session.query(UserRouteVotes).filter_by(id=user_route_votes_id)
    try:
        votes_entry = query.one()
    except NoResultFound:
        abort(400, "invalid user_route_votes_id")

    votes_entry.quality = quality
    votes_entry.difficulty = difficulty
    try:
        db.session.commit()
    except IntegrityError:
        abort(409, "the request does not pass database constraints")
    except DataError:
        abort(400, "the request contains invalid input value")

    updated_route = update_avg_route_votes(votes_entry.route_id, quality, difficulty)
    db.session.commit()

    return jsonify({
        "msg": "Route votes entry updated",
        "user_route_votes": votes_entry.api_model,
        "route": updated_route.api_model,
    })

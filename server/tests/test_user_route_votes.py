from datetime import datetime
from unittest import mock
from unittest.mock import Mock

import pytz

from app.models import Routes, UserRouteVotes
from flask import json


def test_view_votes(client, auth_headers_user1):
    data = {
        "user_id": 1,
        "gym_id": 1,
    }
    resp = client.get("/user_route_votes/", data=json.dumps(data), content_type="application/json",
                      headers=auth_headers_user1)
    assert resp.status_code == 200

    expected_votes = {
        "1": {
            "created_at": "2012-03-02T10:10:10+00:00",
            "difficulty": "soft",
            "gym_id": 1,
            "id": 1,
            "quality": 1.0,
            "route_id": 1,
            "user_id": 1
        },
        "2": {
            "created_at": "2012-03-02T10:10:10+00:00",
            "difficulty": "hard",
            "gym_id": 1,
            "id": 2,
            "quality": 3.0,
            "route_id": 2,
            "user_id": 1
        }
    }

    assert expected_votes == resp.json


def test_view_votes_one_route(client, auth_headers_user1):
    data = {
        "user_id": 1,
        "gym_id": 1,
    }
    resp = client.get("/user_route_votes/1", data=json.dumps(data), content_type="application/json",
                      headers=auth_headers_user1)
    assert resp.status_code == 200

    expected_votes = {
        "1": {
            "created_at": "2012-03-02T10:10:10+00:00",
            "difficulty": "soft",
            "gym_id": 1,
            "id": 1,
            "quality": 1.0,
            "route_id": 1,
            "user_id": 1,
        },
    }

    assert expected_votes == resp.json


def test_update_votes(client, app, auth_headers_user1):
    data = {
        "user_id": 1,
        "user_route_votes_id": 1,
        "quality": 3.0,
        "difficulty": "soft",
    }
    resp = client.patch("/user_route_votes/1", data=json.dumps(data), content_type="application/json",
                      headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["msg"] == "Route votes entry updated"
    assert resp.json["user_route_votes"] == {
        "created_at": "2012-03-02T10:10:10+00:00",
        "difficulty": "soft",
        "gym_id": 1,
        "id": 1,
        "quality": 3.0,
        "route_id": 1,
        "user_id": 1,
    }
    assert resp.json["route"] == {
        "id": 1,
        "gym_id": 1,
        "user_id": 1,
        "area_id": 1,
        "name": "Jug Fest 1",
        "category": "bouldering",
        "count_ascents": 0,
        "lower_grade": "V_V1",
        "upper_grade": "V_V1",
        "avg_difficulty": "soft",
        "avg_quality": 3.0,
        "created_at": "2019-03-04T10:10:10+00:00",
    }

    with app.app_context():
        user_route_log = UserRouteVotes.query.filter_by(id=1).one()
        assert user_route_log.difficulty_name == "soft"
        assert user_route_log.quality == 3.0
        assert user_route_log.user_id == 1
        assert user_route_log.gym_id == 1
        assert user_route_log.route_id == 1
        assert user_route_log.created_at == datetime(2012, 3, 2, 10, 10, 10, tzinfo=pytz.UTC)



@mock.patch("datetime.datetime", Mock(utcnow=lambda: datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)))
def test_add_to_votes(client, app, auth_headers_user2):
    data = {
        "user_id": 2,
        "quality": None,
        "difficulty": "soft",
        "route_id": 1,
        "gym_id": 1,
    }
    resp = client.post("/user_route_votes/", data=json.dumps(data), content_type="application/json",
                       headers=auth_headers_user2)

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["msg"] == "Route votes entry added"
    assert resp.json["user_route_votes"] == {
        "created_at": "2019-03-04T10:10:10+00:00",
        "difficulty": "soft",
        "gym_id": 1,
        "id": 4,
        "quality": None,
        "route_id": 1,
        "user_id": 2,
    }
    assert resp.json["route"] == {
        "id": 1,
        "gym_id": 1,
        "user_id": 1,
        "area_id": 1,
        "name": "Jug Fest 1",
        "category": "bouldering",
        "count_ascents": 0,
        "lower_grade": "V_V1",
        "upper_grade": "V_V1",
        "avg_difficulty": "soft",
        "avg_quality": None,
        "created_at": "2019-03-04T10:10:10+00:00",
    }

    with app.app_context():
        user_route_log = UserRouteVotes.query.filter_by(id=4).one()
        assert user_route_log.difficulty_name == "soft"
        assert user_route_log.quality is None
        assert user_route_log.user_id == 2
        assert user_route_log.gym_id == 1
        assert user_route_log.route_id == 1
        assert user_route_log.created_at == datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)


def test_add_votes_db_unique_constraint(client, app, auth_headers_user1):
    data = {
        "user_id": 1,
        "quality": 3.0,
        "difficulty": "soft",
        "route_id": 1,
        "gym_id": 1,
    }
    resp = client.post("/user_route_votes/", data=json.dumps(data), content_type="application/json",
                       headers=auth_headers_user1)

    assert resp.status_code == 409
    assert resp.is_json
    assert resp.json["msg"] == "the request does not pass database constraints"


def test_add_votes_db_check_constraint(client, app, auth_headers_user1):
    data = {
        "user_id": 1,
        "quality": 4.0,
        "difficulty": "soft",
        "route_id": 2,
        "gym_id": 1,
    }
    resp = client.post("/user_route_votes/", data=json.dumps(data), content_type="application/json",
                       headers=auth_headers_user1)

    assert resp.status_code == 409
    assert resp.is_json
    assert resp.json["msg"] == "the request does not pass database constraints"


def test_add_votes_invalid_value(client, app, auth_headers_user1):
    data = {
        "user_id": 1,
        "quality": 3.0,
        "difficulty": "invalid_value",
        "route_id": 2,
        "gym_id": 1,
    }
    resp = client.post("/user_route_votes/", data=json.dumps(data), content_type="application/json",
                       headers=auth_headers_user1)

    assert resp.status_code == 400
    assert resp.is_json
    assert resp.json["msg"] == "the request contains invalid input value"


def test_update_votes_check_constraint(client, app, auth_headers_user1):
    data = {
        "user_id": 1,
        "user_route_votes_id": 1,
        "quality": 4.0,
        "difficulty": "soft",
    }
    resp = client.patch("/user_route_votes/1", data=json.dumps(data), content_type="application/json",
                       headers=auth_headers_user1)

    assert resp.status_code == 409
    assert resp.is_json
    assert resp.json["msg"] == "the request does not pass database constraints"


def test_update_votes_invalid_value(client, app, auth_headers_user1):
    data = {
        "user_id": 1,
        "user_route_votes_id": 1,
        "quality": 3.0,
        "difficulty": "invalid_value",
    }
    resp = client.patch("/user_route_votes/1", data=json.dumps(data), content_type="application/json",
                       headers=auth_headers_user1)

    assert resp.status_code == 400
    assert resp.is_json
    assert resp.json["msg"] == "the request contains invalid input value"


def test_update_votes_invalid_id(client, app, auth_headers_user1):
    data = {
        "user_id": 1,
        "user_route_votes_id": None,
        "quality": 3.0,
        "difficulty": "soft",
    }
    resp = client.patch("/user_route_votes/100", data=json.dumps(data), content_type="application/json",
                       headers=auth_headers_user1)

    assert resp.status_code == 400
    assert resp.is_json
    assert resp.json["msg"] == "invalid user_route_votes_id"


def test_calc_avg_votes(client, app, auth_headers_user2):
    data = {
        "user_id": 2,
        "quality": 3.0,
        "difficulty": "hard",
        "route_id": 1,
        "gym_id": 1,
    }

    # verify 'before' state of averages
    with app.app_context():
        route_entry = Routes.query.filter_by(id=1).one()
        assert route_entry.avg_difficulty_name is None
        assert route_entry.avg_quality is None
        assert route_entry.user_id == 1
        assert route_entry.gym_id == 1
        assert route_entry.area_id == 1
        assert route_entry.created_at == datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)

    resp = client.post("/user_route_votes/", data=json.dumps(data), content_type="application/json",
                       headers=auth_headers_user2)

    assert resp.status_code == 200
    assert resp.is_json

    with app.app_context():
        route_entry = Routes.query.filter_by(id=1).one()
        assert route_entry.avg_difficulty_name == "fair"
        assert route_entry.avg_quality == 2.0
        assert route_entry.user_id == 1
        assert route_entry.gym_id == 1
        assert route_entry.area_id == 1
        assert route_entry.created_at == datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)


def test_calc_avg_votes_with_nulls(client, app, auth_headers_user1, auth_headers_user2):
    # verify 'before' state of averages
    with app.app_context():
        route_entry = Routes.query.filter_by(id=3).one()
        assert route_entry.avg_difficulty_name is None
        assert route_entry.avg_quality is None
        assert route_entry.user_id == 1
        assert route_entry.gym_id == 1
        assert route_entry.area_id == 1
        assert route_entry.created_at == datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)

    # add a vote entry with nulls
    data = {
        "user_id": 1,
        "quality": None,
        "difficulty": None,
        "route_id": 3,
        "gym_id": 1,
    }

    resp = client.post("/user_route_votes/", data=json.dumps(data), content_type="application/json",
                       headers=auth_headers_user1)

    assert resp.is_json
    assert resp.status_code == 200

    data2 = {
        "user_id": 2,
        "quality": 3.0,
        "difficulty": "soft",
        "route_id": 3,
        "gym_id": 1,
    }

    resp = client.post("/user_route_votes/", data=json.dumps(data2), content_type="application/json",
                       headers=auth_headers_user2)

    assert resp.status_code == 200
    assert resp.is_json

    with app.app_context():
        route_entry = Routes.query.filter_by(id=3).one()
        assert route_entry.avg_difficulty_name == "soft"
        assert route_entry.avg_quality == 3.0
        assert route_entry.user_id == 1
        assert route_entry.gym_id == 1
        assert route_entry.area_id == 1
        assert route_entry.created_at == datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)

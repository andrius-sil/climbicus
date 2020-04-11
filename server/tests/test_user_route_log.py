from datetime import datetime
from unittest import mock
from unittest.mock import Mock

import pytz

from app.models import UserRouteLog
from flask import json


def test_view_logbook(client, auth_headers_user1):
    data = {
        "user_id": 1,
        "gym_id": 1,
    }
    resp = client.get("/user_route_log/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)
    assert resp.status_code == 200

    expected_logbook = {
        "1": {"grade": "7a", "user_route_log": {"completion_status": True, "created_at": "2012-03-03T10:10:10",
                                                "gym_id": 1, "id": 1, "number_of_attempts": None, "route_id": 1,
                                                "user_id": 1}},
        "2": {"grade": "7a", "user_route_log": {"completion_status": False, "created_at": "2012-03-04T10:10:10",
                                                "gym_id": 1, "id": 2, "number_of_attempts": 1, "route_id": 3,
                                                "user_id": 1}},
        "3": {"grade": "7a", "user_route_log": {"completion_status": True, "created_at": "2012-03-02T10:10:10",
                                                "gym_id": 1, "id": 3, "number_of_attempts": 10, "route_id": 1,
                                                "user_id": 1}},
    }

    assert expected_logbook == resp.json


def test_view_logbook_one_route(client, auth_headers_user1):
    data = {
        "user_id": 1,
        "gym_id": 1,
    }
    resp = client.get("/user_route_log/1", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)
    assert resp.status_code == 200

    expected_logbook = {
        "1": {"grade": "7a", "user_route_log": {"completion_status": True, "created_at": "2012-03-03T10:10:10",
                                                "gym_id": 1, "id": 1, "number_of_attempts": None, "route_id": 1,
                                                "user_id": 1}},
        "3": {"grade": "7a", "user_route_log": {"completion_status": True, "created_at": "2012-03-02T10:10:10",
                                                "gym_id": 1, "id": 3, "number_of_attempts": 10, "route_id": 1,
                                                "user_id": 1}},
    }

    assert expected_logbook == resp.json


@mock.patch("datetime.datetime", Mock(utcnow=lambda: datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)))
def test_add_to_logbook(client, app, auth_headers_user1):
    data = {
        "user_id": 1,
        "completion_status": True,
        "number_of_attempts": None,
        "route_id": 1,
        "gym_id": 1,
    }
    resp = client.post("/user_route_log/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["msg"] == "Route status added to log"
    assert resp.json["user_route_log"] == {"completion_status": True, "created_at": "2019-03-04T10:10:10",
                                           "gym_id": 1, "id": 4, "number_of_attempts": None, "route_id": 1,
                                           "user_id": 1}

    with app.app_context():
        user_route_log = UserRouteLog.query.filter_by(id=4).one()
        assert user_route_log.completion_status == True
        assert user_route_log.number_of_attempts is None
        assert user_route_log.user_id == 1
        assert user_route_log.gym_id == 1
        assert user_route_log.route_id == 1
        assert user_route_log.created_at == datetime(2019, 3, 4, 10, 10, 10)

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
        "1": {"route_id": 1, "user_id": 1, "grade": "7a", "status": "red-point", "created_at": "2012-03-03T10:10:10"},
        "2": {"route_id": 3, "user_id": 1, "grade": "7a", "status": "flash", "created_at": "2012-03-04T10:10:10"},
    }

    assert expected_logbook == resp.json


@mock.patch("datetime.datetime", Mock(utcnow=lambda: datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)))
def test_add_to_logbook(client, app, auth_headers_user1):
    data = {
        "user_id": 1,
        "status": "dogged",
        "route_id": 1,
        "gym_id": 1,
    }
    resp = client.post("/user_route_log/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["id"] == 3
    assert resp.json["msg"] == "Route status added to log"
    assert resp.json["created_at"] == "2019-03-04T10:10:10"

    with app.app_context():
        user_route_log = UserRouteLog.query.filter_by(id=3).one()
        assert user_route_log.status == "dogged"
        assert user_route_log.user_id == 1
        assert user_route_log.gym_id == 1
        assert user_route_log.route_id == 1
        assert user_route_log.created_at == datetime(2019, 3, 4, 10, 10, 10)

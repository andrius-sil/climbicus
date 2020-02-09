from app.models import UserRouteLog
from flask import json


def test_view_logbook(client, auth_headers_user1):
    data = {
        "user_id": 1,
        "gym_id": 1,
    }
    resp = client.get("/user_route_log/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)
    assert resp.status_code == 200

    assert resp.json["1"]["route_id"] == 1
    assert resp.json["1"]["grade"] == "7a"
    assert resp.json["1"]["status"] == "red-point"
    assert resp.json["1"]["created_at"] == "2012-03-03T10:10:10"
    assert resp.json["2"]["route_id"] == 3
    assert resp.json["2"]["grade"] == "7a"
    assert resp.json["2"]["status"] == "flash"
    assert resp.json["2"]["created_at"] == "2012-03-04T10:10:10"


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
    assert resp.json["msg"] == "Route status added to log"

    with app.app_context():
        assert UserRouteLog.query.filter_by(status="dogged", user_id=1, gym_id=1).one().status == "dogged"

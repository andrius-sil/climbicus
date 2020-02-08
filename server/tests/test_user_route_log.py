from app.models import UserRouteLog
from flask import json


def test_view_logbook(client, auth_headers):
    logbook = client.get("/user_route_log/1/logbooks/view", headers=auth_headers)
    assert logbook.status_code == 200

    assert logbook.json["1"]["route_id"] == 1
    assert logbook.json["1"]["grade"] == "7a"
    assert logbook.json["1"]["status"] == "red-point"
    assert logbook.json["1"]["created_at"] == "2012-03-03T10:10:10"
    assert logbook.json["2"]["route_id"] == 3
    assert logbook.json["2"]["grade"] == "7a"
    assert logbook.json["2"]["status"] == "flash"
    assert logbook.json["2"]["created_at"] == "2012-03-04T10:10:10"


def test_add_to_logbook(client, app, auth_headers):
    data = { "status": "dogged", "route_id": 1, "gym_id": 1 }
    resp = client.post("/user_route_log/1/logbooks/add", data=json.dumps(data), content_type="application/json", headers=auth_headers)
    assert resp.status_code == 200

    with app.app_context():
        assert UserRouteLog.query.filter_by(status="dogged", user_id=1, gym_id=1).one().status == "dogged"

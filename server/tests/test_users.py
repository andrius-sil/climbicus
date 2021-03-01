from flask import json


def test_users(client, auth_headers_user1):
    data = {
        "user_id": 1,
    }
    resp = client.get("/users/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    expected_users = {
        "1": {"id": 1, "name": "Tester One", "created_at": "2019-03-04T10:10:10+00:00"},
        "2": {"id": 2, "name": "Tester Two", "created_at": "2019-03-04T10:10:10+00:00"},
        "3": {"id": 3, "name": "Tester Three", "created_at": "2019-03-04T10:10:10+00:00"},
    }

    assert resp.json["users"] == expected_users

from flask import json


def test_gyms(client, auth_headers_user1):
    data = {
        "user_id": 1,
    }
    resp = client.get("/gyms/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    expected_gyms = {
        "1": {"id": 1, "name": "The Castle Climbing Centre", "has_bouldering": True, "has_sport": True,
              "created_at": "2019-03-04T10:10:10+00:00"},
        "2": {"id": 2, "name": "VauxWest", "has_bouldering": True, "has_sport": False,
              "created_at": "2020-01-11T10:10:10+00:00"},
    }

    assert resp.json["gyms"] == expected_gyms

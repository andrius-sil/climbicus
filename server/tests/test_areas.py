from flask import json


def test_areas(client, auth_headers_user1):
    data = {
        "user_id": 1,
    }
    resp = client.get("/areas/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    expected_areas = {
        "1": {"id": 1, "gym_id": 1, "user_id": 1, "name": "Cave", "image_path": "area_images/area1.jpg",
              "created_at": "2019-03-04T10:10:10+00:00"},
        "2": {"id": 2, "gym_id": 1, "user_id": 1, "name": "Prow", "image_path": "area_images/area2.jpg",
              "created_at": "2019-03-04T10:10:10+00:00"},
    }

    assert resp.json["areas"] == expected_areas

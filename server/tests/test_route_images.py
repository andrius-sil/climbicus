import pytest

from app.models import RouteImages
from app import db
from flask import json

from app.utils.encoding import b64str_to_bytes, bytes_to_b64str


def _test_image_str(resource_dir, image_name):
    filepath = f"{resource_dir}/route_images/{image_name}"
    with open(filepath, "rb") as f:
        return bytes_to_b64str(f.read())


def test_route_images(client, resource_dir, auth_headers_user2):
    # Request data with invalid '99' route id.
    data = {
        "user_id": 2,
        "route_ids": [1, 2, 3, 99],
    }
    resp = client.get("/route_images/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user2)

    assert resp.status_code == 200
    assert resp.is_json

    expected_route_images = {
        "1": { "id": 1, "route_id": 1, "user_id": 1, "created_at": "2019-03-04T10:10:10",
          "b64_image": _test_image_str(resource_dir, "user1_route1.jpg") },
        "2": { "id": 3, "route_id": 2, "user_id": 2, "created_at": "2019-02-04T10:10:10",
          "b64_image": _test_image_str(resource_dir, "user2_route2_1.jpg") },
        "3": { "id": 5, "route_id": 3, "user_id": 1, "created_at": "2019-03-04T10:10:10",
          "b64_image": _test_image_str(resource_dir, "user1_route3.jpg") },
    }

    assert resp.json["route_images"] == expected_route_images


def test_all_route_images(client, resource_dir, auth_headers_user1):
    data = {
        "user_id": 1,
    }
    resp = client.get("/route_images/route/2", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    expected_route_images = [
        { "id": 2, "route_id": 2, "user_id": 1, "created_at": "2019-03-04T10:10:10",
          "b64_image": _test_image_str(resource_dir, "user1_route2.jpg") },
        { "id": 3, "route_id": 2, "user_id": 2, "created_at": "2019-02-04T10:10:10",
          "b64_image": _test_image_str(resource_dir, "user2_route2_1.jpg") },
        { "id": 4, "route_id": 2, "user_id": 2, "created_at": "2019-02-04T10:10:10",
          "b64_image": _test_image_str(resource_dir, "user2_route2_2.jpg") },
    ]

    assert resp.json["route_images"] == expected_route_images


def test_route_match(client, app, resource_dir, auth_headers_user2):
    data = {
        "user_id": 2,
        "is_match": 1,
        "route_id": 2,
    }
    resp = client.patch("/route_images/4", data=json.dumps(data), content_type="application/json", headers=auth_headers_user2)

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["msg"] == "Route image updated with user's route id choice"

    assert resp.json["route_image"] == {
        "id": 4, "route_id": 2, "user_id": 2, "created_at": "2019-02-04T10:10:10",
        "b64_image": _test_image_str(resource_dir, "user2_route2_2.jpg")
    }

    with app.app_context():
        route_image = db.session.query(RouteImages).filter_by(id=4).one()
        assert route_image.route_id == 2
        assert not route_image.route_unmatched


@pytest.mark.skip(reason="WIP")
def test_route_match_no_match(client, app, auth_headers_user2):
    data = {
        "user_id": 2,
        "is_match": 0,
        "route_id": None,
    }
    resp = client.patch("/route_images/4", data=json.dumps(data), content_type="application/json", headers=auth_headers_user2)

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["msg"] == "Route image updated with user's route id choice"

    with app.app_context():
        route_image = db.session.query(RouteImages).filter_by(id=4).one()
        assert route_image.route_id is None
        assert route_image.route_unmatched

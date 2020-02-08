import base64

from app.models import RouteImages
from app import db
from flask import json


def test_route_images(client, resource_dir, auth_headers_user2):
    routes = {
        1: { "route_image_id": 1, "b64_image": "user1_route1.jpg"},
        2: { "route_image_id": 3, "b64_image": "user2_route2_1.jpg"},
        3: { "route_image_id": 5, "b64_image": "user1_route3.jpg"},
    }

    # Request data with invalid '99' route id.
    data = {
        "user_id": 2,
        "route_ids": list(routes.keys()) + [99],
    }
    resp = client.get("/route_images/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user2)

    assert resp.status_code == 200
    assert resp.is_json

    route_images = resp.json["route_images"]
    for route_id, values in routes.items():
        resp_values = route_images[str(route_id)]

        assert values["route_image_id"] == resp_values["route_image_id"]

        image_bytes = base64.b64decode(resp_values["b64_image"])
        path = values["b64_image"]
        filepath = f"{resource_dir}/route_images/{path}"
        with open(filepath, "rb") as f:
            assert f.read() == image_bytes

        del route_images[str(route_id)]

    # Check that only route images of interest were fetched from the server.
    assert len(route_images) == 0


def test_route_match(client, app, auth_headers_user2):
    data = {
        "user_id": 2,
        "is_match": 1,
        "route_id": 2,
    }
    resp = client.patch("/route_images/4", data=json.dumps(data), content_type="application/json", headers=auth_headers_user2)

    assert resp.status_code == 200

    with app.app_context():
        route_image = db.session.query(RouteImages).filter_by(id=4).one()
        assert route_image.user_route_id == 2
        assert not route_image.user_route_unmatched


def test_route_match_no_match(client, app, auth_headers_user2):
    data = {
        "user_id": 2,
        "is_match": 0,
        "route_id": None,
    }
    resp = client.patch("/route_images/4", data=json.dumps(data), content_type="application/json", headers=auth_headers_user2)

    assert resp.status_code == 200

    with app.app_context():
        route_image = db.session.query(RouteImages).filter_by(id=4).one()
        assert route_image.user_route_id is None
        assert route_image.user_route_unmatched

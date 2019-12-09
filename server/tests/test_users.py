import base64
import math

from app.models import RouteImages, UserRouteLog
from app import db
from flask import json


def test_view_logbook(client, auth_headers):
    logbook = client.get("/users/1/logbooks/view", headers=auth_headers)
    assert logbook.json["1"]["grade"] == "7a"
    assert logbook.json["1"]["status"] == "red-point"
    assert logbook.json["1"]["log_date"] == "Sat, 03 Mar 2012 10:10:10 GMT"


def test_add_to_logbook(client, app, auth_headers):
    client.post("/users/1/logbooks/add", data=dict(status="dogged", predicted_class_id=1, gym_id=1), headers=auth_headers)
    with app.app_context():
        assert UserRouteLog.query.filter_by(status="dogged", user_id=1, gym_id=1).one().status == "dogged"


def test_predict_no_image(client, auth_headers):
    resp = client.post("/users/1/predict", headers=auth_headers)
    assert resp.status_code == 400
    assert b"Image file is missing" in resp.data


def test_predict_with_image(client, resource_dir, auth_headers):
    data = {"image": open(f"{resource_dir}/green_route.jpg", "rb")}

    resp = client.post("/users/1/predict", data=data, headers=auth_headers)

    assert resp.status_code == 200

    with open(f"{resource_dir}/green_route_response.json", 'rb') as f:
        green_route_response = json.load(f)
    assert resp.get_json() == green_route_response


def test_predict_with_invalid_image(client, auth_headers):
    data = {"image": b"thisIsNotAnImage"}

    resp = client.post("/users/1/predict", data=data, headers=auth_headers)
    assert resp.status_code == 400
    assert b"Image file is missing" in resp.data


def test_predict_with_corrupt_image(client, resource_dir, auth_headers):
    """
    Testing with a file which is not a real image.
    """
    data = {"image": open(f"{resource_dir}/corrupt_route.jpg", "rb")}

    resp = client.post("/users/1/predict", data=data, headers=auth_headers)
    assert resp.status_code == 400
    assert b"Not a valid image" in resp.data


def test_predict_with_unknown_image(client, resource_dir, auth_headers):
    """
    Testing with an image of a route unknown to the model.
    """
    data = {"image": open(f"{resource_dir}/unknown_route.jpg", "rb")}

    resp = client.post("/users/1/predict", data=data, headers=auth_headers)
    # For now, the current model still predicts a route with high probability, hence we cannot say "this is unknown
    # route"
    assert resp.status_code == 200

    with open(f"{resource_dir}/unknown_route_response.json", 'rb') as f:
        unknown_route_response = json.load(f)
    assert resp.get_json() == unknown_route_response


def test_storing_image_path_to_db(app, client, resource_dir, auth_headers):
    """
    Testing with an image of a route unknown to the model.
    """
    data = {"image": open(f"{resource_dir}/unknown_route.jpg", "rb")}

    resp = client.post("/users/1/predict", data=data, headers=auth_headers)
    assert resp.status_code == 200

    with app.app_context():
        db_probability = db.session.query(RouteImages).filter_by(model_route_id=15).one_or_none().model_probability

    assert math.isclose(db_probability, 0.95810854434967)


def test_route_images(client, resource_dir, auth_headers):
    routes = {
        "1": "user1_route1.jpg",
        "2": "user2_route2_1.jpg",
        "3": "user1_route3.jpg",
    }

    # Request data with invalid '99' route id.
    data = {
        "route_ids": list(routes.keys()) + ["99"],
    }
    resp = client.get("/users/2/route_images", data=json.dumps(data), content_type="application/json", headers=auth_headers)

    assert resp.status_code == 200
    assert resp.is_json

    route_images = resp.json["route_images"]
    for id, path in routes.items():
        base64_str = route_images[id]
        image_bytes = base64.b64decode(base64_str)

        filepath = f"{resource_dir}/route_images/{path}"
        with open(filepath, "rb") as f:
            assert f.read() == image_bytes

        del route_images[id]

    # Check that only route images of interest were fetched from the server.
    assert len(route_images) == 0


def test_route_match(client, app, auth_headers):
    data = {
        "is_match": 1,
        "route_id": 2,
    }
    resp = client.patch("/users/2/route_match/4", data=data, headers=auth_headers)

    assert resp.status_code == 200

    with app.app_context():
        route_image = db.session.query(RouteImages).filter_by(id=4).one()
        assert route_image.user_route_id == 2
        assert not route_image.user_route_unmatched


def test_route_match_no_match(client, app, auth_headers):
    data = {
        "is_match": 0,
        "route_id": None,
    }
    resp = client.patch("/users/2/route_match/4", data=data, headers=auth_headers)

    assert resp.status_code == 200

    with app.app_context():
        route_image = db.session.query(RouteImages).filter_by(id=4).one()
        assert route_image.user_route_id is None
        assert route_image.user_route_unmatched


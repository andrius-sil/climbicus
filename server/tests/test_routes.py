import math

from app.models import RouteImages
from app import db
from flask import json

def test_routes(client, auth_headers_user1):
    data = {
        "user_id": 1,
        "gym_id": 2,
    }
    resp = client.get("/routes/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    expected_routes = {
        "100": {"grade": "6a", "created_at": "2019-03-04T10:10:10"},
        "101": {"grade": "6a", "created_at": "2019-03-04T10:10:10"},
        "102": {"grade": "6a", "created_at": "2019-03-04T10:10:10"},
    }

    assert expected_routes == resp.json["routes"]


def test_predict_no_image(client, auth_headers_user1):
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
    }
    resp = client.post("/routes/predictions", data=data, headers=auth_headers_user1)

    assert resp.status_code == 400
    assert resp.is_json
    assert resp.json["msg"] == "image file is missing"


def test_predict_with_image(client, resource_dir, auth_headers_user1):
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/green_route.jpg", "rb"),
    }

    resp = client.post("/routes/predictions", data=data, headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    with open(f"{resource_dir}/green_route_response.json", 'rb') as f:
        green_route_response = json.load(f)
    assert resp.get_json() == green_route_response


def test_predict_with_invalid_image(client, auth_headers_user1):
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": b"thisIsNotAnImage",
    }

    resp = client.post("/routes/predictions", data=data, headers=auth_headers_user1)
    assert resp.status_code == 400
    assert resp.is_json
    assert resp.json["msg"] == "image file is missing"


def test_predict_with_corrupt_image(client, resource_dir, auth_headers_user1):
    """
    Testing with a file which is not a real image.
    """
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/corrupt_route.jpg", "rb"),
    }

    resp = client.post("/routes/predictions", data=data, headers=auth_headers_user1)
    assert resp.status_code == 400
    assert resp.is_json
    assert resp.json["msg"] == "not a valid image"


def test_predict_with_unknown_image(client, resource_dir, auth_headers_user1):
    """
    Testing with an image of a route unknown to the model.
    """
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/unknown_route.jpg", "rb"),
    }

    resp = client.post("/routes/predictions", data=data, headers=auth_headers_user1)
    # For now, the current model still predicts a route with high probability, hence we cannot say "this is unknown
    # route"
    assert resp.status_code == 200
    assert resp.is_json

    with open(f"{resource_dir}/unknown_route_response.json", 'rb') as f:
        unknown_route_response = json.load(f)
    assert resp.get_json() == unknown_route_response


def test_storing_image_path_to_db(app, client, resource_dir, auth_headers_user1):
    """
    Testing with an image of a route unknown to the model.
    """
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/unknown_route.jpg", "rb"),
    }

    resp = client.post("/routes/predictions", data=data, headers=auth_headers_user1)
    assert resp.status_code == 200
    assert resp.is_json

    with app.app_context():
        db_probability = db.session.query(RouteImages).filter_by(model_route_id=15).one_or_none().model_probability

    assert math.isclose(db_probability, 0.9979556798934937)

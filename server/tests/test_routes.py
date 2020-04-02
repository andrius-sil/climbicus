import math
from datetime import datetime
from unittest import mock
from unittest.mock import Mock

import pytz

from app.models import RouteImages, Routes
from app import db
from flask import json

from tests.conftest import image_str


def test_routes(client, auth_headers_user1):
    data = {
        "user_id": 1,
        "gym_id": 2,
    }
    resp = client.get("/routes/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    expected_routes = {
        "100": {"user_id": 2, "grade": "6a", "created_at": "2019-03-04T10:10:10"},
        "101": {"user_id": 2, "grade": "6a", "created_at": "2019-03-04T10:10:10"},
        "102": {"user_id": 2, "grade": "6a", "created_at": "2019-03-04T10:10:10"},
    }

    assert expected_routes == resp.json["routes"]


def test_single_route(client, auth_headers_user1):
    data = {
        "user_id": 1,
        "gym_id": 2,
    }
    resp = client.get("/routes/101", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    expected_routes = {
        "101": {"user_id": 2, "grade": "6a", "created_at": "2019-03-04T10:10:10"},
    }

    assert expected_routes == resp.json["routes"]


@mock.patch("datetime.datetime", Mock(utcnow=lambda: datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)))
def test_add_route(client, app, auth_headers_user1):
    data = {
        "user_id": 1,
        "gym_id": 1,
        "grade": "7a",
    }
    resp = client.post("/routes/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["id"] == 103
    assert resp.json["msg"] == "Route added"
    assert resp.json["created_at"] == "2019-03-04T10:10:10"

    with app.app_context():
        route = Routes.query.filter_by(id=103).one()
        assert route.gym_id == 1
        assert route.user_id == 1
        assert route.grade == "7a"
        assert route.created_at == datetime(2019, 3, 4, 10, 10, 10)


def test_predict_no_image(client, auth_headers_user1):
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
    }
    resp = client.post("/routes/predictions_cls", data=data, headers=auth_headers_user1)

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

    resp = client.post("/routes/predictions_cls", data=data, headers=auth_headers_user1)

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

    resp = client.post("/routes/predictions_cls", data=data, headers=auth_headers_user1)
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

    resp = client.post("/routes/predictions_cls", data=data, headers=auth_headers_user1)
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

    resp = client.post("/routes/predictions_cls", data=data, headers=auth_headers_user1)
    # For now, the current model still predicts a route with high probability, hence we cannot say "this is unknown
    # route"
    assert resp.status_code == 200
    assert resp.is_json

    with open(f"{resource_dir}/unknown_route_response.json", 'rb') as f:
        unknown_route_response = json.load(f)
    assert resp.get_json() == unknown_route_response


@mock.patch("datetime.datetime", Mock(utcnow=lambda: datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)))
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

    resp = client.post("/routes/predictions_cls", data=data, headers=auth_headers_user1)
    assert resp.status_code == 200
    assert resp.is_json

    with app.app_context():
        stored_image = db.session.query(RouteImages).filter_by(id=resp.json['route_image_id']).one_or_none()

    assert math.isclose(stored_image.model_probability, 0.9979556798934937)
    assert stored_image.created_at.isoformat() == "2019-03-04T10:10:10"


@mock.patch("datetime.datetime", Mock(utcnow=lambda: datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)))
def test_cbir_predict_with_image(client, resource_dir, auth_headers_user1):
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/green_route.jpg", "rb"),
    }

    resp = client.post("/routes/predictions_cbir", data=data, headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    assert resp.json["sorted_route_predictions"] == [
        { "grade": "7a", "route_id": 2 },
        { "grade": "7a", "route_id": 4 },
        { "grade": "7a", "route_id": 1 },
        { "grade": "7a", "route_id": 3 },
    ]

    assert resp.json["route_image"] == {
        "id": 9, "route_id": None, "user_id": 1, "created_at": "2019-03-04T10:10:10",
        "b64_image": image_str(resource_dir, "green_route.jpg")
    }

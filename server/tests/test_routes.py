from datetime import datetime
from unittest import mock
from unittest.mock import Mock
from uuid import UUID

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
        "100": {"created_at": "2019-03-04T10:10:10", "grade": "6a", "gym_id": 2, "id": 100, "user_id": 2},
        "101": {"created_at": "2019-03-04T10:10:10", "grade": "6a", "gym_id": 2, "id": 101, "user_id": 2},
        "102": {"created_at": "2019-03-04T10:10:10", "grade": "6a", "gym_id": 2, "id": 102, "user_id": 2},
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
        "101": {"created_at": "2019-03-04T10:10:10", "grade": "6a", "gym_id": 2, "id": 101, "user_id": 2},
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
    assert resp.json["msg"] == "Route added"
    assert resp.json["route"] == {"created_at": "2019-03-04T10:10:10", "grade": "7a", "gym_id": 1, "id": 103, "user_id": 1}

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
    resp = client.post("/routes/predictions_cbir", data=data, headers=auth_headers_user1)

    assert resp.status_code == 400
    assert resp.is_json
    assert resp.json["msg"] == "image file is missing"


def test_predict_with_invalid_image(client, auth_headers_user1):
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": b"thisIsNotAnImage",
    }

    resp = client.post("/routes/predictions_cbir", data=data, headers=auth_headers_user1)
    assert resp.status_code == 400
    assert resp.is_json
    assert resp.json["msg"] == "image file is missing"


def test_predict_with_corrupt_image(client, resource_dir, auth_headers_user1):
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/route_images/corrupt_route.jpg", "rb"),
    }

    resp = client.post("/routes/predictions_cbir", data=data, headers=auth_headers_user1)
    assert resp.status_code == 400
    assert resp.is_json
    assert resp.json["msg"] == "image file is invalid"


@mock.patch("datetime.datetime", Mock(utcnow=lambda: datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)))
def test_predict_with_unknown_image(client, resource_dir, auth_headers_user1):
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/route_images/unknown_route.jpg", "rb"),
    }

    resp = client.post("/routes/predictions_cbir", data=data, headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    assert resp.json["sorted_route_predictions"] == [
        {
            'route': {'created_at': '2019-03-04T10:10:10', 'grade': '7a', 'gym_id': 1, 'id': 1, 'user_id': 1},
            'route_image': {'b64_image': image_str(resource_dir, "user1_route1.jpg"), 'created_at': '2019-03-04T10:10:10', 'id': 1, 'route_id': 1, 'user_id': 1},
        },
        {
            'route': {'created_at': '2019-03-04T10:10:10', 'grade': '7a', 'gym_id': 1, 'id': 2, 'user_id': 1},
            'route_image': {'b64_image': image_str(resource_dir, "user1_route2.jpg"), 'created_at': '2019-03-04T10:10:10', 'id': 2, 'route_id': 2, 'user_id': 1},
        },
        {
            'route': {'created_at': '2019-03-04T10:10:10', 'grade': '7a', 'gym_id': 1, 'id': 3, 'user_id': 1},
            'route_image': {'b64_image': image_str(resource_dir, "user1_route3.jpg"), 'created_at': '2019-03-04T10:10:10', 'id': 5, 'route_id': 3, 'user_id': 1},
        },
        {
            'route': {'created_at': '2019-03-04T10:10:10', 'grade': '7a', 'gym_id': 1, 'id': 4, 'user_id': 1},
            'route_image': {'b64_image': image_str(resource_dir, "user1_route4.jpg"), 'created_at': '2019-03-04T10:10:10', 'id': 6, 'route_id': 4, 'user_id': 1},
        },
    ]

    assert resp.json["route_image"] == {
        "id": 9, "route_id": None, "user_id": 1, "created_at": "2019-03-04T10:10:10",
        "b64_image": image_str(resource_dir, "unknown_route.jpg")
    }


@mock.patch("datetime.datetime", Mock(utcnow=lambda: datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)))
@mock.patch("uuid.uuid4", lambda: UUID('12345678123456781234567812345678'))
def test_cbir_predict_with_image(app, client, resource_dir, auth_headers_user1):
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/route_images/green_route.jpg", "rb"),
    }

    resp = client.post("/routes/predictions_cbir", data=data, headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    assert resp.json["sorted_route_predictions"] == [
        {
            'route': {'created_at': '2019-03-04T10:10:10', 'grade': '7a', 'gym_id': 1, 'id': 2, 'user_id': 1},
            'route_image': {'b64_image': image_str(resource_dir, "user2_route2_1.jpg"), 'created_at': '2019-02-04T10:10:10', 'id': 3, 'route_id': 2, 'user_id': 2},
        },
        {
            'route': {'created_at': '2019-03-04T10:10:10', 'grade': '7a', 'gym_id': 1, 'id': 4, 'user_id': 1},
            'route_image': {'b64_image': image_str(resource_dir, "user2_route4_1.jpg"), 'created_at': '2019-02-04T10:10:10', 'id': 7, 'route_id': 4, 'user_id': 2},
        },
        {
            'route': {'created_at': '2019-03-04T10:10:10', 'grade': '7a', 'gym_id': 1, 'id': 1, 'user_id': 1},
            'route_image': {'b64_image': image_str(resource_dir, "user1_route1.jpg"), 'created_at': '2019-03-04T10:10:10', 'id': 1, 'route_id': 1, 'user_id': 1},
        },
        {
            'route': {'created_at': '2019-03-04T10:10:10', 'grade': '7a', 'gym_id': 1, 'id': 3, 'user_id': 1},
            'route_image': {'b64_image': image_str(resource_dir, "user1_route3.jpg"), 'created_at': '2019-03-04T10:10:10', 'id': 5, 'route_id': 3, 'user_id': 1},
        },
    ]

    assert resp.json["route_image"] == {
        "id": 9, "route_id": None, "user_id": 1, "created_at": "2019-03-04T10:10:10",
        "b64_image": image_str(resource_dir, "green_route.jpg")
    }

    with app.app_context():
        stored_image = db.session.query(RouteImages).filter_by(id=9).one()
        assert stored_image.id == 9
        assert stored_image.user_id == 1
        assert stored_image.route_id is None
        assert stored_image.route_unmatched == False
        assert stored_image.model_version == "cbir_v1"
        assert stored_image.path == "/tmp/climbicus_tests/route_images/from_users/1/2019/03/12345678123456781234567812345678.jpg"
        assert stored_image.created_at == datetime(2019, 3, 4, 10, 10, 10)
        assert stored_image.descriptors == json.load(open(f"{resource_dir}/cbir/green_route_descriptor.json"))

from datetime import datetime
from unittest import mock
from unittest.mock import Mock
from uuid import UUID

import pytz

from app.models import RouteImages
from app import db
from flask import json


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
        "1": { "id": 1, "route_id": 1, "user_id": 1, "created_at": "2019-03-04T10:10:10+00:00",
               "path": "route_images/user1_route1.jpg", "thumbnail_path": "route_images/user1_route1.jpg" },
        "2": { "id": 3, "route_id": 2, "user_id": 2, "created_at": "2019-02-04T10:10:10+00:00",
               "path": "route_images/user2_route2_1.jpg", "thumbnail_path": "route_images/user2_route2_1.jpg" },
        "3": { "id": 5, "route_id": 3, "user_id": 1, "created_at": "2019-03-04T10:10:10+00:00",
               "path": "route_images/user1_route3.jpg", "thumbnail_path": "route_images/user1_route3.jpg" },
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
        { "id": 2, "route_id": 2, "user_id": 1, "created_at": "2019-03-04T10:10:10+00:00",
          "path": "route_images/user1_route2.jpg", "thumbnail_path": "route_images/user1_route2.jpg" },
        { "id": 3, "route_id": 2, "user_id": 2, "created_at": "2019-02-04T10:10:10+00:00",
          "path": "route_images/user2_route2_1.jpg", "thumbnail_path": "route_images/user2_route2_1.jpg" },
        { "id": 4, "route_id": 2, "user_id": 2, "created_at": "2019-02-04T10:10:10+00:00",
          "path": "route_images/user2_route2_2.jpg", "thumbnail_path": "route_images/user2_route2_2.jpg" },
    ]

    assert resp.json["route_images"] == expected_route_images


@mock.patch("datetime.datetime", Mock(utcnow=lambda: datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)))
@mock.patch("uuid.uuid4", lambda: UUID('12345678123456781234567812345678'))
def test_add_route_image(client, resource_dir, app, auth_headers_user1):
    json_data = {
        "user_id": 1,
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/route_images/green_route.jpg", "rb"),
    }
    resp = client.post("/route_images/", data=data, headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["msg"] == "Route image added"
    assert resp.json["route_image"] == {'created_at': '2019-03-04T10:10:10+00:00', 'id': 10,
                                        'path': '/tmp/climbicus_tests/route_images/from_users/gym_id=1/year=2019/month=03/full_size/12345678123456781234567812345678.jpg',
                                        'thumbnail_path': '/tmp/climbicus_tests/route_images/from_users/gym_id=1/year=2019/month=03/thumbnail/12345678123456781234567812345678.jpg',
                                        'route_id': None, 'user_id': 1}

    with app.app_context():
        route_image = RouteImages.query.filter_by(id=10).one()
        assert route_image.id == 10
        assert route_image.user_id == 1
        assert route_image.route_id is None
        assert route_image.route_unmatched == False
        assert route_image.model_version == "none"
        assert route_image.path == "/tmp/climbicus_tests/route_images/from_users/gym_id=1/year=2019/month=03" \
                                    "/full_size/12345678123456781234567812345678.jpg"
        assert route_image.thumbnail_path == "/tmp/climbicus_tests/route_images/from_users/gym_id=1/year=2019/month" \
                                              "=03/thumbnail/12345678123456781234567812345678.jpg"
        assert route_image.created_at == datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)


def test_route_match(client, app, resource_dir, auth_headers_user2):
    with app.app_context():
        route_image = db.session.query(RouteImages).filter_by(id=4).one()
        route_image.route_id = None
        route_image.route_unmatched = True
        db.session.commit()

    data = {
        "user_id": 2,
        "is_match": 1,
        "route_id": 3,
    }
    resp = client.patch("/route_images/4", data=json.dumps(data), content_type="application/json", headers=auth_headers_user2)

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["msg"] == "Route image updated with user's route id choice"

    assert resp.json["route_image"] == {
        "id": 4, "route_id": 3, "user_id": 2, "created_at": "2019-02-04T10:10:10+00:00",
        "path": "route_images/user2_route2_2.jpg",
        "thumbnail_path": "route_images/user2_route2_2.jpg",
    }

    with app.app_context():
        route_image = db.session.query(RouteImages).filter_by(id=4).one()
        assert route_image.route_id == 3
        assert not route_image.route_unmatched


def test_route_match_no_match(client, app, resource_dir, auth_headers_user2):
    data = {
        "user_id": 2,
        "is_match": 0,
        "route_id": None,
    }
    resp = client.patch("/route_images/4", data=json.dumps(data), content_type="application/json", headers=auth_headers_user2)

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["msg"] == "Route image updated with user's route id choice"

    assert resp.json["route_image"] == {
        "id": 4, "route_id": None, "user_id": 2, "created_at": "2019-02-04T10:10:10+00:00",
        "path": "route_images/user2_route2_2.jpg",
        "thumbnail_path": "route_images/user2_route2_2.jpg",
    }

    with app.app_context():
        route_image = db.session.query(RouteImages).filter_by(id=4).one()
        assert route_image.route_id is None
        assert route_image.route_unmatched

from datetime import datetime
from unittest import mock
from unittest.mock import Mock
from uuid import UUID

import pytz

from app.models import RouteImages, Routes
from app import db
from flask import json, jsonify

from app.utils.encoding import json_to_nparraybytes
from app import cbir_predictor

def test_routes(client, auth_headers_user1):
    data = {
        "user_id": 1,
        "gym_id": 2,
    }
    resp = client.get("/routes/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    expected_routes = {
        "100": {"avg_difficulty": "fair", "avg_quality": 2.0, "category": "sport", "count_ascents": 10,
                "created_at": "2019-03-04T10:10:10+00:00", "gym_id": 2, "id": 100, "lower_grade": "Font_7A",
                "color": "ff55452c", "points": "[(0,0)]",
                "upper_grade": "Font_7A", "user_id": 2, "name": "Crimpinator 100", "area_id": 2},
        "101": {"avg_difficulty": "fair", "avg_quality": 2.0, "category": "sport", "count_ascents": 10,
                "created_at": "2019-03-04T10:10:10+00:00", "gym_id": 2, "id": 101, "lower_grade": "Font_7A",
                "color": "ff55452c", "points": "[(0,0)]",
                "upper_grade": "Font_7A", "user_id": 2, "name": "Crimpinator 101", "area_id": 2},
        "102": {"avg_difficulty": "fair", "avg_quality": 2.0, "category": "sport", "count_ascents": 10,
                "created_at": "2019-03-04T10:10:10+00:00", "gym_id": 2, "id": 102, "lower_grade": "Font_7A",
                "color": "ff55452c", "points": "[(0,0)]",
                "upper_grade": "Font_7A", "user_id": 2, "name": "Crimpinator 102", "area_id": 2},
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
        "101": {"avg_difficulty": "fair", "avg_quality": 2.0, "category": "sport", "count_ascents": 10,
                "created_at": "2019-03-04T10:10:10+00:00", "gym_id": 2, "id": 101, "lower_grade": "Font_7A",
                "color": "ff55452c", "points": "[(0,0)]",
                "upper_grade": "Font_7A", "user_id": 2, "name": "Crimpinator 101", "area_id": 2},
    }

    assert expected_routes == resp.json["routes"]


@mock.patch("datetime.datetime", Mock(utcnow=lambda: datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)))
def test_add_route(client, app, auth_headers_user1):
    data = {
        "user_id": 1,
        "gym_id": 1,
        "area_id": 2,
        "category": "sport",
        "name": "No Hands Slab",
        "lower_grade": "Font_7A",
        "upper_grade": "Font_7A",
        "color": "ff55452c",
        # "points": "[(10.0,15.0),(12.5,17.5)]",
        "points": ["(10.0,15.0)", "(12.5,17.5)"],
    }
    resp = client.post("/routes/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["msg"] == "Route added"
    assert resp.json["route"] == {"avg_difficulty": None, "avg_quality": None, "category": "sport", "count_ascents": 0,
                                  "created_at": "2019-03-04T10:10:10+00:00", "gym_id": 1, "id": 105,
                                  "lower_grade": "Font_7A", "upper_grade": "Font_7A", "user_id": 1,
                                  "name": "No Hands Slab", "area_id": 2, "color": "ff55452c",
                                  "points": "[(10,15),(12.5,17.5)]"}

    with app.app_context():
        route = Routes.query.filter_by(id=105).one()
        assert route.gym_id == 1
        assert route.user_id == 1
        assert route.area_id == 2
        assert route.lower_grade == "Font_7A"
        assert route.upper_grade == "Font_7A"
        assert route.name == "No Hands Slab"
        assert route.color == "ff55452c"
        assert route.points == "[(10,15),(12.5,17.5)]"
        assert route.created_at == datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)


def test_predict_no_image(client, auth_headers_user1):
    json_data = {
        "user_id": 1,
        "category": "sport",
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
        "category": "sport",
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
        "category": "sport",
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
@mock.patch("uuid.uuid4", lambda: UUID('12345678123456781234567812345678'))
@mock.patch("predictor.cbir_predictor.MATCH_DISTANCE_THRESHOLD", 1000)
def test_predict_with_unknown_image(client, resource_dir, auth_headers_user1):
    cbir_predictor.init_matcher("bf")

    json_data = {
        "user_id": 1,
        "category": "bouldering",
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/route_images/unknown_route.jpg", "rb"),
    }

    resp = client.post("/routes/predictions_cbir", data=data, headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    assert resp.json["sorted_route_and_image_predictions"] == [
        {
            'route': {'avg_difficulty': None, 'avg_quality': None, 'category': 'bouldering', 'count_ascents': 0,
                      'created_at': '2019-03-04T10:10:10+00:00', 'gym_id': 1, 'id': 2,
                      "color": "ff55452c", "points": "[(0,0)]",
                      'lower_grade': 'V_V1', 'upper_grade': 'V_V1', 'user_id': 1, 'name': 'Jug Fest 2', 'area_id': 1},
            'route_image': {'path': "route_images/user2_route2_1.jpg", 'thumbnail_path': "route_images/user2_route2_1.jpg",
                            'created_at': '2019-02-04T10:10:10+00:00', 'id': 3, 'route_id': 2, 'user_id': 2},
        },
        {
            'route': {'avg_difficulty': None, 'avg_quality': None, 'category': 'bouldering', 'count_ascents': 0,
                      'created_at': '2019-03-04T10:10:10+00:00', 'gym_id': 1, 'id': 4,
                      "color": "ff55452c", "points": "[(0,0)]",
                      'lower_grade': 'V_V1', 'upper_grade': 'V_V1', 'user_id': 1, 'name': 'Jug Fest 4', 'area_id': 1},
            'route_image': {'path': "route_images/user2_route4_1.jpg", 'thumbnail_path': "route_images/user2_route4_1.jpg",
                            'created_at': '2019-02-04T10:10:10+00:00', 'id': 7, 'route_id': 4, 'user_id': 2},
        },
        {
            'route': {'avg_difficulty': None, 'avg_quality': None, 'category': 'bouldering', 'count_ascents': 0,
                      'created_at': '2019-03-04T10:10:10+00:00', 'gym_id': 1, 'id': 1,
                      "color": "ff55452c", "points": "[(0,0)]",
                      'lower_grade': 'V_V1', 'upper_grade': 'V_V1', 'user_id': 1, 'name': 'Jug Fest 1', 'area_id': 1},
            'route_image': {'path': "route_images/user1_route1.jpg", 'thumbnail_path': "route_images/user1_route1.jpg",
                            'created_at': '2019-03-04T10:10:10+00:00', 'id': 1, 'route_id': 1, 'user_id': 1},
        },
        {
            'route': {'avg_difficulty': None, 'avg_quality': None, 'category': 'bouldering', 'count_ascents': 0,
                      'created_at': '2019-03-04T10:10:10+00:00', 'gym_id': 1, 'id': 3,
                      "color": "ff55452c", "points": "[(0,0)]",
                      'lower_grade': 'V_V1', 'upper_grade': 'V_V1', 'user_id': 1, 'name': 'Jug Fest 3', 'area_id': 1},
            'route_image': {'path': "route_images/user1_route3.jpg", 'thumbnail_path': "route_images/user1_route3.jpg",
                            'created_at': '2019-03-04T10:10:10+00:00', 'id': 5, 'route_id': 3, 'user_id': 1},
        },
    ]

    assert resp.json["route_image"] == {
        "id": 10, "route_id": None, "user_id": 1, "created_at": "2019-03-04T10:10:10+00:00",
        "path": "/tmp/climbicus_tests/route_images/from_users/gym_id=1/year=2019/month=03"
                "/full_size/12345678123456781234567812345678.jpg",
        "thumbnail_path": "/tmp/climbicus_tests/route_images/from_users/gym_id=1/year=2019/month=03"
                          "/thumbnail/12345678123456781234567812345678.jpg",
    }


@mock.patch("datetime.datetime", Mock(utcnow=lambda: datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)))
@mock.patch("uuid.uuid4", lambda: UUID('12345678123456781234567812345678'))
@mock.patch("predictor.cbir_predictor.MATCH_DISTANCE_THRESHOLD", 1000)
def test_cbir_predict_with_image(app, client, resource_dir, auth_headers_user1):
    cbir_predictor.init_matcher("bf")

    json_data = {
        "user_id": 1,
        "category": "bouldering",
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/route_images/green_route.jpg", "rb"),
    }

    resp = client.post("/routes/predictions_cbir", data=data, headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    assert resp.json["sorted_route_and_image_predictions"] == [
        {
            'route': {'avg_difficulty': None, 'avg_quality': None, 'category': 'bouldering', 'count_ascents': 0,
                      'created_at': '2019-03-04T10:10:10+00:00', 'gym_id': 1, 'id': 2,
                      "color": "ff55452c", "points": "[(0,0)]",
                      'lower_grade': 'V_V1', 'upper_grade': 'V_V1', 'user_id': 1, 'name': 'Jug Fest 2', 'area_id': 1},
            'route_image': {'path': "route_images/user2_route2_2.jpg", 'thumbnail_path': "route_images/user2_route2_2.jpg",
                            'created_at': '2019-02-04T10:10:10+00:00', 'id': 4, 'route_id': 2, 'user_id': 2},
        },
        {
            'route': {'avg_difficulty': None, 'avg_quality': None, 'category': 'bouldering', 'count_ascents': 0,
                      'created_at': '2019-03-04T10:10:10+00:00', 'gym_id': 1, 'id': 4,
                      "color": "ff55452c", "points": "[(0,0)]",
                      'lower_grade': 'V_V1', 'upper_grade': 'V_V1', 'user_id': 1, 'name': 'Jug Fest 4', 'area_id': 1},
            'route_image': {'path': "route_images/user2_route4_2.jpg", 'thumbnail_path': "route_images/user2_route4_2.jpg",
                            'created_at': '2019-02-04T10:10:10+00:00', 'id': 8, 'route_id': 4, 'user_id': 2},
        },
        {
            'route': {'avg_difficulty': None, 'avg_quality': None, 'category': 'bouldering', 'count_ascents': 0,
                      'created_at': '2019-03-04T10:10:10+00:00', 'gym_id': 1, 'id': 1,
                      "color": "ff55452c", "points": "[(0,0)]",
                      'lower_grade': 'V_V1', 'upper_grade': 'V_V1', 'user_id': 1, 'name': 'Jug Fest 1', 'area_id': 1},
            'route_image': {'path': "route_images/user1_route1.jpg", 'thumbnail_path': "route_images/user1_route1.jpg",
                            'created_at': '2019-03-04T10:10:10+00:00', 'id': 1, 'route_id': 1, 'user_id': 1},
        },
        {
            'route': {'avg_difficulty': None, 'avg_quality': None, 'category': 'bouldering', 'count_ascents': 0,
                      'created_at': '2019-03-04T10:10:10+00:00', 'gym_id': 1, 'id': 3,
                      "color": "ff55452c", "points": "[(0,0)]",
                      'lower_grade': 'V_V1', 'upper_grade': 'V_V1', 'user_id': 1, 'name': 'Jug Fest 3', 'area_id': 1},
            'route_image': {'path': "route_images/user1_route3.jpg", 'thumbnail_path': "route_images/user1_route3.jpg",
                            'created_at': '2019-03-04T10:10:10+00:00', 'id': 5, 'route_id': 3, 'user_id': 1},
        },
    ]

    assert resp.json["route_image"] == {
        "id": 10, "route_id": None, "user_id": 1, "created_at": "2019-03-04T10:10:10+00:00",
        "path": "/tmp/climbicus_tests/route_images/from_users/gym_id=1/year=2019/month=03"
                "/full_size/12345678123456781234567812345678.jpg",
        "thumbnail_path": "/tmp/climbicus_tests/route_images/from_users/gym_id=1/year=2019/month=03"
                          "/thumbnail/12345678123456781234567812345678.jpg",
    }

    with app.app_context():
        stored_image = db.session.query(RouteImages).filter_by(id=10).one()
        assert stored_image.id == 10
        assert stored_image.user_id == 1
        assert stored_image.route_id is None
        assert stored_image.route_unmatched == False
        assert stored_image.model_version == "cbir_v1"
        assert stored_image.path == "/tmp/climbicus_tests/route_images/from_users/gym_id=1/year=2019/month=03" \
                                    "/full_size/12345678123456781234567812345678.jpg"
        assert stored_image.thumbnail_path == "/tmp/climbicus_tests/route_images/from_users/gym_id=1/year=2019/month" \
                                              "=03/thumbnail/12345678123456781234567812345678.jpg"
        assert stored_image.created_at == datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)
        with open(f"{resource_dir}/cbir/green_route_descriptor.json") as f:
            assert stored_image.descriptors == json_to_nparraybytes(f.read())


@mock.patch("predictor.cbir_predictor.MATCH_DISTANCE_THRESHOLD", 1000)
def test_flann_cbir_predict_with_image(app, client, resource_dir, auth_headers_user1):
    cbir_predictor.init_matcher("flann")

    json_data = {
        "user_id": 1,
        "category": "bouldering",
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/route_images/green_route.jpg", "rb"),
    }

    resp = client.post("/routes/predictions_cbir", data=data, headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    assert len(resp.json["sorted_route_and_image_predictions"]) == 4


@mock.patch("predictor.cbir_predictor.MATCH_DISTANCE_THRESHOLD", 200)
def test_cbir_apply_threshold(app, client, resource_dir, auth_headers_user1):
    cbir_predictor.init_matcher("bf")

    json_data = {
        "user_id": 1,
        "category": "bouldering",
        "gym_id": 1,
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/route_images/green_route.jpg", "rb"),
    }

    resp = client.post("/routes/predictions_cbir", data=data, headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    assert resp.json["sorted_route_and_image_predictions"] == [
        {
            'route': {'avg_difficulty': None, 'avg_quality': None, 'category': 'bouldering', 'count_ascents': 0,
                      'created_at': '2019-03-04T10:10:10+00:00', 'gym_id': 1, 'id': 2,
                      "color": "ff55452c", "points": "[(0,0)]",
                      'lower_grade': 'V_V1', 'upper_grade': 'V_V1', 'user_id': 1, 'name': 'Jug Fest 2', 'area_id': 1},
            'route_image': {'path': "route_images/user2_route2_2.jpg", 'thumbnail_path': "route_images/user2_route2_2.jpg",
                            'created_at': '2019-02-04T10:10:10+00:00', 'id': 4, 'route_id': 2, 'user_id': 2},
        },
        {
            'route': {'avg_difficulty': None, 'avg_quality': None, 'category': 'bouldering', 'count_ascents': 0,
                      'created_at': '2019-03-04T10:10:10+00:00', 'gym_id': 1, 'id': 4,
                      "color": "ff55452c", "points": "[(0,0)]",
                      'lower_grade': 'V_V1', 'upper_grade': 'V_V1', 'user_id': 1, 'name': 'Jug Fest 4', 'area_id': 1},
            'route_image': {'path': "route_images/user2_route4_2.jpg", 'thumbnail_path': "route_images/user2_route4_2.jpg",
                            'created_at': '2019-02-04T10:10:10+00:00', 'id': 8,
                            'route_id': 4, 'user_id': 2},
        },
    ]


def test_with_deleted(app):
    user_id = 2
    gym_id = 2

    with app.app_context():
        query = db.session.query(Routes).execution_options(include_deleted=True).filter(Routes.gym_id == gym_id,
                                                                                        Routes.user_id==user_id)
        gym_routes = {}
        for route in query.all():
            gym_routes[route.id] = route.api_model
        gym_routes_jsonified = jsonify(gym_routes)

    expected_routes = {
        "100": {"avg_difficulty": "fair", "avg_quality": 2.0, "category": "sport", "count_ascents": 10,
                "created_at": "2019-03-04T10:10:10+00:00", "gym_id": 2, "id": 100, "lower_grade": "Font_7A",
                "color": "ff55452c", "points": "[(0,0)]",
                "upper_grade": "Font_7A", "user_id": 2, "name": "Crimpinator 100", "area_id": 2},
        "101": {"avg_difficulty": "fair", "avg_quality": 2.0, "category": "sport", "count_ascents": 10,
                "created_at": "2019-03-04T10:10:10+00:00", "gym_id": 2, "id": 101, "lower_grade": "Font_7A",
                "color": "ff55452c", "points": "[(0,0)]",
                "upper_grade": "Font_7A", "user_id": 2, "name": "Crimpinator 101", "area_id": 2},
        "102": {"avg_difficulty": "fair", "avg_quality": 2.0, "category": "sport", "count_ascents": 10,
                "created_at": "2019-03-04T10:10:10+00:00", "gym_id": 2, "id": 102, "lower_grade": "Font_7A",
                "color": "ff55452c", "points": "[(0,0)]",
                "upper_grade": "Font_7A", "user_id": 2, "name": "Crimpinator 102", "area_id": 2},
        "103": {"avg_difficulty": "fair", "avg_quality": 2.0, "category": "sport", "count_ascents": 10,
                "created_at": "2019-03-04T10:10:10+00:00", "gym_id": 2, "id": 103, "lower_grade": "Font_8A",
                "color": "ff55452c", "points": "[(0,0)]",
                "upper_grade": "Font_8A", "user_id": 2, "name": "Deleted Route", "area_id": 2,}
    }

    assert expected_routes == gym_routes_jsonified.json


def test_only_deleted(app):
    user_id = 2
    gym_id = 2

    with app.app_context():
        query = db.session.query(Routes).execution_options(include_deleted=True).filter(Routes.gym_id==gym_id,
                                                                                        Routes.user_id==user_id,
                                                                                        Routes.deleted_at!=None)
        gym_routes = {}
        for route in query.all():
            gym_routes[route.id] = route.api_model
        gym_routes_jsonified = jsonify(gym_routes)

    expected_routes = {
        "103": {"avg_difficulty": "fair", "avg_quality": 2.0, "category": "sport", "count_ascents": 10,
                "created_at": "2019-03-04T10:10:10+00:00", "gym_id": 2, "id": 103, "lower_grade": "Font_8A",
                "color": "ff55452c", "points": "[(0,0)]",
                "upper_grade": "Font_8A", "user_id": 2, "name": "Deleted Route", "area_id": 2}
    }

    assert expected_routes == gym_routes_jsonified.json

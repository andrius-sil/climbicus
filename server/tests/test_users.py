import math

from app.models import RouteImages, UserRouteLog
from app import db
from flask import json


def test_view_logbook(client):
    logbook = client.get("/users/1/logbooks/view")
    assert logbook.json["1"]["grade"] == "7a"
    assert logbook.json["1"]["status"] == "red-point"
    assert logbook.json["1"]["log_date"] == "Sat, 03 Mar 2012 10:10:10 GMT"


def test_add_to_logbook(client, app):
    client.post("/users/1/logbooks/add", data=dict(status="dogged", predicted_class_id=1, gym_id=1))
    with app.app_context():
        assert UserRouteLog.query.filter_by(status="dogged", user_id=1, gym_id=1).one().status == "dogged"


def test_predict_no_image(client):
    resp = client.post("/users/1/predict")
    assert resp.status_code == 400
    assert b"Image file is missing" in resp.data


def test_predict_with_image(client, resource_dir):
    data = {"image": open(f"{resource_dir}/green_route.jpg", "rb")}

    resp = client.post("/users/1/predict", data=data)
    with open(f"{resource_dir}/green_route_response.json", 'rb') as f:
        green_route_response = json.load(f)
    assert resp.status_code == 200
    assert resp.get_json() == green_route_response


def test_predict_with_invalid_image(client):
    data = {"image": b"thisIsNotAnImage"}

    resp = client.post("/users/1/predict", data=data)
    assert resp.status_code == 400
    assert b"Image file is missing" in resp.data


def test_predict_with_corrupt_image(client, resource_dir):
    """
    Testing with a file which is not a real image.
    """
    data = {"image": open(f"{resource_dir}/corrupt_route.jpg", "rb")}

    resp = client.post("/users/1/predict", data=data)
    assert resp.status_code == 400
    assert b"Not a valid image" in resp.data


def test_predict_with_unknown_image(client, resource_dir):
    """
    Testing with an image of a route unknown to the model.
    """
    data = {"image": open(f"{resource_dir}/unknown_route.jpg", "rb")}

    resp = client.post("/users/1/predict", data=data)
    # For now, the current model still predicts a route with high probability, hence we cannot say "this is unknown
    # route"
    with open(f"{resource_dir}/unknown_route_response.json", 'rb') as f:
        unknown_route_response = json.load(f)
    assert resp.status_code == 200
    assert resp.get_json() == unknown_route_response


def test_storing_image_path_to_db(app, client, resource_dir):
    """
    Testing with an image of a route unknown to the model.
    """
    data = {"image": open(f"{resource_dir}/unknown_route.jpg", "rb")}

    resp = client.post("/users/1/predict", data=data)
    with app.app_context():
        db_probability = db.session.query(RouteImages).filter_by(model_route_id=15).first().model_probability
    assert resp.status_code == 200
    assert math.isclose(db_probability, 0.95810854434967)

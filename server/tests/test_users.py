from app.models import UserRouteLog


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
    assert resp.data == b"1"


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
    assert resp.data == b"15"

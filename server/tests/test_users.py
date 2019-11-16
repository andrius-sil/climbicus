from app.models import UserRouteLog


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


def test_predict_with_image(client):
    data = {"image": open("resources/green_route.jpg", "rb")}

    resp = client.post("/users/1/predict", data=data)
    assert resp.status_code == 200
    assert resp.data == b"1"


def test_predict_with_invalid_image(client):
    data = {"image": b"thisIsNotAnImage"}

    resp = client.post("/users/1/predict", data=data)
    assert resp.status_code == 400
    assert b"Image file is missing" in resp.data


def test_predict_with_corrupt_image(client):
    data = {"image": open("resources/corrupt_route.jpg", "rb")}

    resp = client.post("/users/1/predict", data=data)
    assert resp.status_code == 400
    assert resp.data == b"Not a valid image"

from app.models import UserRouteLog


def test_index(client):
    r = client.get("/")
    assert b"Flask Dockerized" in r.data


def test_fetch_logbook(client):
    logbook = client.get("/fetch_logbook", data=dict(user_id=1))
    assert logbook.json["1"]["grade"] == "7a"
    assert logbook.json["1"]["status"] == "red-point"
    assert logbook.json["1"]["log_date"] == "Sat, 03 Mar 2012 10:10:10 GMT"


def test_add_route_status(client, app):
    client.post("/add_status", data=dict(status="dogged", predicted_class_id=1, user_id=1, gym_id=1))
    with app.app_context():
        assert UserRouteLog.query.filter_by(status="dogged", user_id=1, gym_id=1).one().status == "dogged"

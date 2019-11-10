def test_index(client):
    r = client.get("/")
    assert b"Flask Dockerized" in r.data


def test_fetch_logbook(client):
    logbook = client.get("/fetch_logbook", data=dict(user_id=1))
    assert logbook["1"]["grade"] == "7a"
    assert logbook["1"]["status"] == "red-point"
    assert logbook["1"]["log_date"] == "2012-03-03 10:10:10"

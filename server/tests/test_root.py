def test_index(client):
    r = client.get("/")
    assert b"Flask Dockerized" in r.data

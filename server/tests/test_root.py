from flask import json


def test_login(app, client):
    data = {
        "email": "test@testing.com",
        "password": "testing",
    }
    resp = client.post("/login", data=json.dumps(data), content_type="application/json")

    assert resp.status_code == 200
    assert resp.is_json
    assert "access_token" in resp.json

def test_login_with_invalid_email(app, client):
    data = {
        "email": "INVALID",
        "password": "testing",
    }
    resp = client.post("/login", data=json.dumps(data), content_type="application/json")

    assert resp.status_code == 401
    assert b"Incorrect email and password" in resp.data

def test_login_with_invalid_password(app, client):
    data = {
        "email": "test@testing.com",
        "password": "INVALID",
    }
    resp = client.post("/login", data=json.dumps(data), content_type="application/json")

    assert resp.status_code == 401
    assert b"Incorrect email and password" in resp.data

def test_index(app, client, auth_headers):
    resp = client.get("/", headers=auth_headers)

    assert resp.status_code == 200
    assert b"Flask Dockerized" in resp.data

def test_index_no_auth(app, client):
    resp = client.get("/")

    assert resp.status_code == 401

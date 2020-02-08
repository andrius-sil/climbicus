from flask import json


def test_login(app, client):
    data = {
        "email": "test1@testing.com",
        "password": "testing1",
    }
    resp = client.post("/login", data=json.dumps(data), content_type="application/json")

    assert resp.status_code == 200
    assert resp.is_json
    assert "access_token" in resp.json
    assert resp.json["user_id"] == 1


def test_login_with_invalid_email(app, client):
    data = {
        "email": "INVALID",
        "password": "testing",
    }
    resp = client.post("/login", data=json.dumps(data), content_type="application/json")

    assert resp.status_code == 401
    assert b"incorrect email and password" in resp.data


def test_login_with_invalid_password(app, client):
    data = {
        "email": "test1@testing.com",
        "password": "INVALID",
    }
    resp = client.post("/login", data=json.dumps(data), content_type="application/json")

    assert resp.status_code == 401
    assert b"incorrect email and password" in resp.data


def test_index(app, client, auth_headers_user1):
    data = {
        "user_id": 1,
    }
    resp = client.get("/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert b"Flask Dockerized" in resp.data


def test_index_no_auth_header(app, client):
    resp = client.get("/")

    assert resp.status_code == 401
    assert b"Missing Authorization Header" in resp.data


def test_index_no_user_id(app, client, auth_headers_user1):
    resp = client.get("/", data=json.dumps({}), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 400
    assert b"'user_id' is missing from the request data" in resp.data


def test_index_no_user_id_form_data(app, client, auth_headers_user1):
    json_data = {
    }
    data = {
        "json": json.dumps(json_data),
    }
    resp = client.get("/", data=data, headers=auth_headers_user1)

    assert resp.status_code == 400
    assert b"'user_id' is missing from the request data" in resp.data


def test_index_auth_header_and_user_id_mismatch(app, client, auth_headers_user1):
    data = {
        "user_id": 2,
    }
    resp = client.get("/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 401
    assert b"user is not authorized to access the resource" in resp.data


def test_index_auth_header_and_user_id_mismatch_form_data(app, client, auth_headers_user1):
    json_data = {
        "user_id": 2,
    }
    data = {
        "json": json.dumps(json_data),
    }
    resp = client.get("/", data=data, headers=auth_headers_user1)

    assert resp.status_code == 401
    assert b"user is not authorized to access the resource" in resp.data

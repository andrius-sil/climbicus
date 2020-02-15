from flask import json


def test_login(client):
    data = {
        "email": "test1@testing.com",
        "password": "testing1",
    }
    resp = client.post("/login", data=json.dumps(data), content_type="application/json")

    assert resp.status_code == 200
    assert resp.is_json
    assert "access_token" in resp.json
    assert resp.json["user_id"] == 1


def test_login_with_invalid_email(client):
    data = {
        "email": "INVALID",
        "password": "testing",
    }
    resp = client.post("/login", data=json.dumps(data), content_type="application/json")

    assert resp.status_code == 401
    assert resp.is_json
    assert resp.json["msg"] == "incorrect email and password"


def test_login_with_invalid_password(client):
    data = {
        "email": "test1@testing.com",
        "password": "INVALID",
    }
    resp = client.post("/login", data=json.dumps(data), content_type="application/json")

    assert resp.status_code == 401
    assert resp.is_json
    assert resp.json["msg"] == "incorrect email and password"


def test_index(client, auth_headers_user1):
    data = {
        "user_id": 1,
    }
    resp = client.get("/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert b"Flask Dockerized" in resp.data


def test_index_no_auth_header(client):
    resp = client.get("/")

    assert resp.status_code == 401
    assert resp.is_json
    assert resp.json["msg"] == "Missing Authorization Header"


def test_index_no_user_id(client, auth_headers_user1):
    resp = client.get("/", data=json.dumps({}), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 400
    assert resp.is_json
    assert resp.json["msg"] == "'user_id' is missing from the request data"


def test_index_no_user_id_form_data(client, auth_headers_user1):
    json_data = {
    }
    data = {
        "json": json.dumps(json_data),
    }
    resp = client.get("/", data=data, headers=auth_headers_user1)

    assert resp.status_code == 400
    assert resp.is_json
    assert resp.json["msg"] == "'user_id' is missing from the request data"


def test_index_auth_header_and_user_id_mismatch(client, auth_headers_user1):
    data = {
        "user_id": 2,
    }
    resp = client.get("/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 401
    assert resp.is_json
    assert resp.json["msg"] == "user is not authorized to access the resource"


def test_index_auth_header_and_user_id_mismatch_form_data(client, auth_headers_user1):
    json_data = {
        "user_id": 2,
    }
    data = {
        "json": json.dumps(json_data),
    }
    resp = client.get("/", data=data, headers=auth_headers_user1)

    assert resp.status_code == 401
    assert resp.is_json
    assert resp.json["msg"] == "user is not authorized to access the resource"


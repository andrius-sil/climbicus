from flask import json

from app.models import Users


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


def test_register_with_verification(client_with_user_verification, app_with_user_verification):
    data = {
        "name": "New Tester",
        "email": "new@tester.com",
        "password": "newpass",
    }
    resp = client_with_user_verification.post("/register", data=json.dumps(data), content_type="application/json")

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["msg"] == "New user created"

    with app_with_user_verification.app_context():
        user = Users.query.filter_by(id=3).one()
        assert user.name == "New Tester"
        assert user.email == "new@tester.com"
        assert user.check_password("newpass")
        assert user.verified == False # the important bit


def test_register(client, app):
    data = {
        "name": "New Tester",
        "email": "new@tester.com",
        "password": "newpass",
    }
    resp = client.post("/register", data=json.dumps(data), content_type="application/json")

    assert resp.status_code == 200
    assert resp.is_json
    assert resp.json["msg"] == "New user created"

    with app.app_context():
        user = Users.query.filter_by(id=3).one()
        assert user.name == "New Tester"
        assert user.email == "new@tester.com"
        assert user.check_password("newpass")
        assert user.verified == True


def test_register_email_already_taken(client, app):
    data = {
        "name": "Existing User",
        "email": "test1@testing.com",
        "password": "newpass",
    }
    resp = client.post("/register", data=json.dumps(data), content_type="application/json")

    assert resp.status_code == 409
    assert resp.is_json
    assert resp.json["msg"] == "User already exists"


def test_index(client, auth_headers_user1):
    data = {
        "user_id": 1,
    }
    resp = client.get("/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert b"Keep calm and crimp harder" in resp.data


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


def test_internal_server_error(client):
    resp = client.get("/internal_server_error")

    assert resp.status_code == 500
    assert resp.is_json
    assert resp.json["msg"] == "wut"

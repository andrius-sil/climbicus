import os

import pytest
from flask_jwt_extended import create_access_token

from app import create_app, db
from app.models import Gyms, RouteImages, Routes, UserRouteLog, Users
from datetime import datetime

DATABASE_CONNECTION_URI = "sqlite:///:memory:"
JWT_SECRET_KEY = "super-secret-key"


@pytest.fixture(scope="session")
def app(resource_dir):
    """Create and configure a new app instance for each test."""
    model_path = f"{resource_dir}/castle_30_test_model.h5"
    class_indices_path = f"{resource_dir}/class_indices.pkl"
    model_version = "castle_test"
    app = create_app(DATABASE_CONNECTION_URI, model_path, class_indices_path, model_version, JWT_SECRET_KEY)

    app.testing = True

    with app.app_context():
        db.session.add(Users(email="test@testing.com", password="testing"))
        db.session.add(Gyms(name="The Castle Climbing Centre"))
        db.session.flush()
        for i in range(1, 31):
            db.session.add(Routes(gym_id=1, class_id=str(i), grade="7a"))
        db.session.flush()
        db.session.add(
            RouteImages(route_id=1, user_id=1, probability=0.5, model_version="first_version", path="placeholder")
        )
        db.session.add(
            UserRouteLog(route_id=1, user_id=1, gym_id=1, status="red-point", log_date=datetime(2012, 3, 3, 10, 10, 10))
        )
        db.session.commit()

    yield app


@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()


@pytest.fixture(scope="session")
def resource_dir():
    return os.path.join(
        os.path.dirname(os.path.realpath(__file__)),
        "resources"
    )

@pytest.fixture(scope="session")
def auth_headers(app):
    with app.app_context():
        access_token = create_access_token(identity="test")
        headers = {
            "Authorization": f"Bearer {access_token}"
        }

        return headers

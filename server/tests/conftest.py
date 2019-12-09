import os

import pytest
from flask_jwt_extended import create_access_token

from app import create_app, db
from app.models import Gyms, RouteImages, Routes, UserRouteLog, Users
from datetime import datetime

from app.utils.io import InputOutputProvider

DATABASE_CONNECTION_URI = "sqlite:///:memory:"
JWT_SECRET_KEY = "super-secret-key"


class TestInputOutputProvider(InputOutputProvider):

    def __init__(self, resource_dir):
        self.resource_dir = resource_dir

    def download_file(self, local_path):
        filepath = f"{self.resource_dir}/route_images/{local_path}"
        return filepath

    def upload_file(self, remote_path):
        raise NotImplementedError()



@pytest.fixture(scope="function")
def app(resource_dir):
    """Create and configure a new app instance for each test."""
    model_path = f"{resource_dir}/castle_30_test_model.h5"
    class_indices_path = f"{resource_dir}/class_indices.pkl"
    model_version = "castle_test"
    app = create_app(DATABASE_CONNECTION_URI, model_path, class_indices_path, model_version, JWT_SECRET_KEY, TestInputOutputProvider(resource_dir))

    app.testing = True

    with app.app_context():
        db.create_all()

        db.session.add(Users(email="test1@testing.com", password="testing1"))
        db.session.add(Users(email="test2@testing.com", password="testing2"))
        db.session.add(Gyms(name="The Castle Climbing Centre"))
        db.session.flush()
        for i in range(1, 31):
            db.session.add(Routes(gym_id=1, class_id=str(i), grade="7a"))
        db.session.flush()
        for i in range(1, 5):
            db.session.add(
                RouteImages(
                    user_route_id=i,
                    model_route_id=i,
                    user_id=1,
                    model_probability=0.5,
                    model_version="first_version",
                    path=f"user1_route{i}.jpg",
                )
            )
            if i % 2 == 0:
                db.session.add(
                    RouteImages(
                        user_route_id=i,
                        model_route_id=i,
                        user_id=2,
                        model_probability=0.5,
                        model_version="first_version",
                        path=f"user2_route{i}_1.jpg",
                    )
                )
                db.session.add(
                    RouteImages(
                        model_route_id=i,
                        user_id=2,
                        model_probability=0.5,
                        model_version="first_version",
                        path=f"user2_route{i}_2.jpg",
                    )
                )
        db.session.add(
            UserRouteLog(route_id=1, user_id=1, gym_id=1, status="red-point", log_date=datetime(2012, 3, 3, 10, 10, 10))
        )
        db.session.commit()

    yield app
    
    with app.app_context():
        db.session.remove()
        db.drop_all()


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


@pytest.fixture(scope="function")
def auth_headers(app):
    with app.app_context():
        access_token = create_access_token(identity="test")
        headers = {
            "Authorization": f"Bearer {access_token}"
        }

        return headers

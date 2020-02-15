import os

import pytest
from flask_jwt_extended import create_access_token

from app import create_app, db
from app.models import Gyms, RouteImages, Routes, UserRouteLog, Users
from datetime import datetime
import pytz

from app.utils.io import InputOutputProvider

DATABASE_CONNECTION_URI = "sqlite:///:memory:"
JWT_SECRET_KEY = "super-secret-key"


class TestInputOutputProvider(InputOutputProvider):

    def __init__(self, resource_dir):
        self.resource_dir = resource_dir
        self.upload_dir = "/tmp/climbicus_tests"

    def download_file(self, remote_path):
        filepath = f"{self.resource_dir}/route_images/{remote_path}"
        with open(filepath, "rb") as f:
            return f.read()

    def upload_file(self, file, remote_path):
        filepath = f"{self.upload_dir}/{remote_path}"
        filedir = os.path.dirname(filepath)
        if not os.path.exists(filedir):
            os.makedirs(filedir)
        file.save(filepath)
        return filepath



@pytest.fixture(scope="function")
def app(resource_dir):
    """Create and configure a new app instance for each test."""
    model_path = f"{resource_dir}/model.h5"
    class_indices_path = f"{resource_dir}/class_indices.pkl"
    model_version = "castle_test"
    app = create_app(DATABASE_CONNECTION_URI, model_path, class_indices_path, model_version, JWT_SECRET_KEY, TestInputOutputProvider(resource_dir))

    app.testing = True

    with app.app_context():
        db.create_all()

        db.session.add(Users(email="test1@testing.com", password="testing1", created_at=datetime(2019, 3, 4, 10, 10, 10,
                                                                                            tzinfo=pytz.UTC)))
        db.session.add(Users(email="test2@testing.com", password="testing2", created_at=datetime(2019, 3, 4, 10, 10, 10,
                                                                                            tzinfo=pytz.UTC)))
        db.session.add(Gyms(name="The Castle Climbing Centre", created_at=datetime(2019, 3, 4, 10, 10, 10,
                                                                                   tzinfo=pytz.UTC)))
        db.session.flush()
        for i in range(1, 47):
            db.session.add(Routes(gym_id=1, class_id=str(i), grade="7a", created_at=datetime(2019, 3, 4, 10, 10, 10,
                                                                                            tzinfo=pytz.UTC)))
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
                    created_at=datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC),
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
                        created_at=datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC),
                    )
                )
                db.session.add(
                    RouteImages(
                        model_route_id=i,
                        user_id=2,
                        model_probability=0.5,
                        model_version="first_version",
                        path=f"user2_route{i}_2.jpg",
                        created_at=datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC),
                    )
                )
        db.session.add_all([
            UserRouteLog(route_id=1, user_id=1, gym_id=1, status="red-point", created_at=datetime(2012, 3, 3, 10, 10,
                                                                                                10, tzinfo=pytz.UTC)),
            UserRouteLog(route_id=3, user_id=1, gym_id=1, status="flash", created_at=datetime(2012, 3, 4, 10, 10, 10,
                                                                                            tzinfo=pytz.UTC)),
        ])
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
def auth_headers_user1(app):
    return _auth_headers(app, identity=1)


@pytest.fixture(scope="function")
def auth_headers_user2(app):
    return _auth_headers(app, identity=2)


def _auth_headers(app, identity):
    with app.app_context():
        access_token = create_access_token(identity=identity)
        headers = {
            "Authorization": f"Bearer {access_token}"
        }

        return headers

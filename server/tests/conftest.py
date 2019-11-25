import os

import pytest
from flask_jwt_extended import create_access_token

from app import create_app, db
from app.models import Gyms, RouteImages, Routes, UserRouteLog, Users
from datetime import datetime

DATABASE_CONNECTION_URI = "sqlite:///:memory:"
JWT_SECRET_KEY = "super-secret-key"


@pytest.fixture(scope="function")
def app(resource_dir):
    """Create and configure a new app instance for each test."""
    model_path = f"{resource_dir}/castle_30_test_model.h5"
    class_indices_path = f"{resource_dir}/class_indices.pkl"
    model_version = "castle_test"
    app = create_app(DATABASE_CONNECTION_URI, model_path, class_indices_path, model_version, JWT_SECRET_KEY)

    app.testing = True

    with app.app_context():
        db.create_all()

        db.session.add(Users(email="test@testing.com", password="testing"))
        db.session.add(Gyms(name="The Castle Climbing Centre"))
        db.session.flush()
        db.session.add(Routes(gym_id=1, class_id=1, grade="6A+"))
        db.session.add(Routes(gym_id=1, class_id=2, grade="7A+"))
        db.session.add(Routes(gym_id=1, class_id=3, grade="7C+"))
        db.session.add(Routes(gym_id=1, class_id=4, grade="8A"))
        db.session.add(Routes(gym_id=1, class_id=5, grade="6B"))
        db.session.add(Routes(gym_id=1, class_id=6, grade="6C"))
        db.session.add(Routes(gym_id=1, class_id=7, grade="7B"))
        db.session.add(Routes(gym_id=1, class_id=8, grade="7B+"))
        db.session.add(Routes(gym_id=1, class_id=9, grade="6A"))
        db.session.add(Routes(gym_id=1, class_id=10, grade="6B"))
        db.session.add(Routes(gym_id=1, class_id=11, grade="7A"))
        db.session.add(Routes(gym_id=1, class_id=12, grade="6A"))
        db.session.add(Routes(gym_id=1, class_id=13, grade="6C"))
        db.session.add(Routes(gym_id=1, class_id=14, grade="5+"))
        db.session.add(Routes(gym_id=1, class_id=15, grade="6A+"))
        db.session.add(Routes(gym_id=1, class_id=16, grade="6B+"))
        db.session.add(Routes(gym_id=1, class_id=17, grade="6C+"))
        db.session.add(Routes(gym_id=1, class_id=18, grade="4+"))
        db.session.add(Routes(gym_id=1, class_id=19, grade="5+"))
        db.session.add(Routes(gym_id=1, class_id=20, grade="6A+"))
        db.session.add(Routes(gym_id=1, class_id=21, grade="6B+"))
        db.session.add(Routes(gym_id=1, class_id=22, grade="6A"))
        db.session.add(Routes(gym_id=1, class_id=23, grade="6B"))
        db.session.add(Routes(gym_id=1, class_id=24, grade="6C"))
        db.session.add(Routes(gym_id=1, class_id=25, grade="7B+"))
        db.session.add(Routes(gym_id=1, class_id=26, grade="6A"))
        db.session.add(Routes(gym_id=1, class_id=27, grade="6C"))
        db.session.add(Routes(gym_id=1, class_id=28, grade="5+"))
        db.session.add(Routes(gym_id=1, class_id=29, grade="6B+"))
        db.session.add(Routes(gym_id=1, class_id=30, grade="7B"))
        db.session.add(Routes(gym_id=1, class_id=31, grade="5"))
        db.session.add(Routes(gym_id=1, class_id=32, grade="7A+"))
        db.session.add(Routes(gym_id=1, class_id=33, grade="5"))
        db.session.add(Routes(gym_id=1, class_id=34, grade="6C"))
        db.session.add(Routes(gym_id=1, class_id=35, grade="5+"))
        db.session.add(Routes(gym_id=1, class_id=36, grade="6A+"))
        db.session.add(Routes(gym_id=1, class_id=37, grade="6C"))
        db.session.add(Routes(gym_id=1, class_id=38, grade="6A+"))
        db.session.add(Routes(gym_id=1, class_id=39, grade="6B+"))
        db.session.add(Routes(gym_id=1, class_id=40, grade="7A"))
        db.session.add(Routes(gym_id=1, class_id=41, grade="5"))
        db.session.add(Routes(gym_id=1, class_id=42, grade="5+"))
        db.session.add(Routes(gym_id=1, class_id=43, grade="6A+"))
        db.session.add(Routes(gym_id=1, class_id=44, grade="6B+"))
        db.session.add(Routes(gym_id=1, class_id=45, grade="7A"))
        db.session.flush()
        db.session.add(
            RouteImages(
                user_route_id=1,
                model_route_id=1,
                user_id=1,
                model_probability=0.5,
                model_version="first_version",
                path="placeholder",
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

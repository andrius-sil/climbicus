import pytest
from app import create_app
from flask_sqlalchemy import SQLAlchemy
from app.models import Gyms, RouteImages, Routes, UserRouteLog, Users
from datetime import datetime

DATABASE_CONNECTION_URI = "sqlite:///:memory:"
_db = SQLAlchemy()


@pytest.fixture(scope="session")
def app():
    """Create and configure a new app instance for each test."""
    app = create_app(DATABASE_CONNECTION_URI)

    with app.app_context():
        _db.session.add(Users(email="bla@bla.com"))
        _db.session.add(Gyms(name="The Castle Climbing Centre"))
        _db.session.flush()
        for i in range(1, 31):
            _db.session.add(Routes(gym_id=1, class_id=str(i), grade="7a"))
        _db.session.flush()
        _db.session.add(
            RouteImages(route_id=1, user_id=1, probability=0.5, model_version="first_version", path="placeholder")
        )
        _db.session.add(
            UserRouteLog(route_id=1, user_id=1, gym_id=1, status="red-point", log_date=datetime(2012, 3, 3, 10, 10, 10))
        )
        _db.session.commit()

    yield app


@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()

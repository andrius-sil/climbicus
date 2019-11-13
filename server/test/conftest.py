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
        _db.session.add_all(
            (
                Users(email="bla@bla.com"),
                Gyms(name="The Castle Climbing Centre"),
                Routes(gym_id=1, class_id="1", grade="7a"),
                RouteImages(route_id=1, path="placeholder"),
                UserRouteLog(
                    route_id=1, user_id=1, gym_id=1, status="red-point", log_date=datetime(2012, 3, 3, 10, 10, 10)
                ),
            )
        )
        _db.session.commit()

    yield app


@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()

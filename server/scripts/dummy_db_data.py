from app import db
from app.models import Gyms, RouteImages, Routes, UserRouteLog, Users
from run import app
from datetime import datetime

# Instructions:
# make docker-down
# make docker-run
# make populate-test-database

with app.app_context():
    db.session.add_all(
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
    db.session.commit()

from app import db
from app.models import Gyms, RouteImages, Routes, UserRouteLog, Users
from run import app

# Instructions:
# docker-compose -f docker-compose.yml down
# Run container in Pycharm
# docker exec -it climbicus_server_1 /bin/bash
# python3 scripts/dummy_db_data.py

with app.app_context():
    db.session.add(Users(email="bla@bla.com"))
    db.session.add(Gyms(name="The Castle Climbing Centre"))
    db.session.add(Routes(gym_id=1, class_id="1", grade="7a"))
    # TODO: get auto increment id not violate Foreign Key constraint
    db.session.commit()
    db.session.add(RouteImages(route_id=1, path="placeholder"))
    db.session.add(UserRouteLog(route_id=1, user_id=1, gym_id=1, status="red-point", log_date="2019-10-10"))
    db.session.commit()

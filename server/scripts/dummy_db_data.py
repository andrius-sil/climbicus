from app import database
from app.models import Gyms, RouteImages, Routes, UserRouteLog, Users
from run import app

# Instructions:
# docker-compose -f docker-compose.yml down
# docker-compose -f docker-compose.yml up
# docker exec -it climbicus_server_1 /bin/bash
# python3 scripts/dummy_db_data.py

with app.app_context():
    database.add_instance(Users, email='bla@bla.com')
    database.add_instance(Gyms, name='The Castle Climbing Centre')
    database.add_instance(Routes, gym_id=1, class_id='1', grade='7a')
    database.add_instance(RouteImages, route_id=1, path='placeholder')
    database.add_instance(UserRouteLog,
                          route_id=1,
                          user_id=1,
                          gym_id=1,
                          status='red-point',
                          log_date='2019-10-10')
from app.models import Gyms, RouteImages, Routes, UserRouteLog, Users


def preload_dummy_data(db):
    db.session.add(Users(email="test@testing.com", password="testing"))
    db.session.add(Gyms(name="The Castle Climbing Centre"))
    db.session.flush()
    for i in range(1, 31):
        db.session.add(Routes(gym_id=1, class_id=str(i), grade="7a"))
    db.session.flush()
    db.session.add(RouteImages(route_id=1, user_id=1, probability=0.5, model_version="first_version",
                               path="placeholder"))
    db.session.add(UserRouteLog(route_id=1, user_id=1, gym_id=1, status="red-point", log_date="2019-10-10"))
    db.session.commit()

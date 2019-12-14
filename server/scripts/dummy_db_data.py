from app.models import Gyms, RouteImages, Routes, UserRouteLog, Users


def preload_dummy_data(db):
    db.session.add(Users(email="test@testing.com", password="testing"))
    db.session.add(Users(email="silas04@gmail.com", password="chorrera"))
    db.session.add(Users(email="keksainis@gmail.com", password="masterbates"))
    db.session.add(Gyms(name="The Castle Climbing Centre"))
    db.session.flush()
    for i in range(1, 31):
        db.session.add(Routes(gym_id=1, class_id=str(i), grade="7a"))
    db.session.flush()
    db.session.add(RouteImages(user_route_id=1, model_route_id=1, user_id=1, model_probability=0.5,
                               model_version="first_version",
                               path="s3://climbicus/route_images/from_users/1/2019/12/2c2f3e3f2a1c4cb0b892468fb012e4b9.jpg"))
    db.session.add(UserRouteLog(route_id=1, user_id=1, gym_id=1, status="red-point", log_date="2019-10-10"))
    db.session.commit()

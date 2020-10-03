import datetime

from flask import abort
from sqlalchemy.exc import IntegrityError

from app.models import Users


def create_db_user(db, name, email, password):
    try:
        user = Users(name=name, email=email, password=password, created_at=datetime.datetime.utcnow())

        db.session.add(user)
        db.session.commit()
    except IntegrityError:
        abort(409, "User already exists")

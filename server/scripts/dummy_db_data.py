import datetime

import pandas as pd
from sqlalchemy.exc import IntegrityError
from werkzeug.exceptions import abort

from app.models import Users, Gyms
from app.utils.encoding import json_to_nparraybytes


def preload_dummy_data(db, tables):
    for cls in db.Model._decl_class_registry.values():
        if not isinstance(cls, type) or not issubclass(cls, db.Model):
            continue

        if tables is not None and cls.__tablename__ not in tables:
            continue

        load_table(db, cls)

    db.session.commit()


def load_table(db, ModelClass):
    def preformat_row(row):
        if "descriptors" in row:
            row["descriptors"] = json_to_nparraybytes(row["descriptors"])
        return row


    table_name = ModelClass.__tablename__
    print(f"\tloading '{table_name}' table")

    table_df = pd.read_csv(f"resources/{table_name}.csv")
    table_df = table_df.where(pd.notnull(table_df), None)
    db.session.add_all([
        ModelClass(**preformat_row(row))
        for _, row in table_df.iterrows()
    ])
    db.session.flush()


def create_user(db, email, password):
    # TODO: move to a function
    try:
        user = Users(email=email, password=password, created_at=datetime.datetime.utcnow())

        db.session.add(user)
        db.session.commit()
    except IntegrityError:
        abort(409, "User already exists")


def create_gym(db, name, has_bouldering, has_sport):
    gym = Gyms(name=name, has_bouldering=has_bouldering, has_sport=has_sport,
               created_at=datetime.datetime.utcnow())

    db.session.add(gym)
    db.session.commit()

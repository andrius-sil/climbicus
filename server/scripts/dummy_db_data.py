import datetime

import pandas as pd

from app.models import Gyms
from app.utils.encoding import json_to_nparraybytes
from app.utils.query import create_db_user


def preload_dummy_data(db, tables, data_source):
    for cls in db.Model._decl_class_registry.values():
        if not isinstance(cls, type) or not issubclass(cls, db.Model):
            continue

        if tables is not None and cls.__tablename__ not in tables:
            continue

        load_table(db, cls, data_source)

    db.session.commit()


def load_table(db, ModelClass, data_source):
    def preformat_row(row):
        if "descriptors" in row:
            row["descriptors"] = json_to_nparraybytes(row["descriptors"])
        return row


    table_name = ModelClass.__tablename__
    print(f"\tloading '{table_name}' table")

    table_df = pd.read_csv(f"resources/{data_source}/{table_name}.csv")
    table_df = table_df.where(pd.notnull(table_df), None)
    db.session.add_all([
        ModelClass(**preformat_row(row))
        for _, row in table_df.iterrows()
    ])
    db.session.flush()


def create_user(db, name, email, password):
    """
    Manually created users will always be 'verified'.
    """
    create_db_user(db, name=name, email=email, password=password, verified=True)


def create_gym(db, name, has_bouldering, has_sport):
    gym = Gyms(name=name, has_bouldering=has_bouldering, has_sport=has_sport,
               created_at=datetime.datetime.utcnow())

    db.session.add(gym)
    db.session.commit()

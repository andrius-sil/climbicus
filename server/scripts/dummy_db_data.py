import csv
import os

from app.models import Gyms, RouteImages, Routes, UserRouteLog, Users

ENV = os.getenv("ENV", "dev")


def preload_dummy_data(db):
    load_table(db, Users)
    load_table(db, Gyms)
    load_table(db, Routes)
    load_table(db, RouteImages)
    load_table(db, UserRouteLog)

    db.session.commit()


def load_table(db, ModelClass):
    def preformat_row(row):
        if "path" in row:
            row["path"] = row["path"].replace("{ENV}", ENV)
        return row

    table_name = ModelClass.__tablename__

    with open(f"resources/{table_name}.csv", "r") as f:
        reader = csv.DictReader(f)
        db.session.add_all([
            ModelClass(**preformat_row(row))
            for row in reader
        ])

    db.session.flush()

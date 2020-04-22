import pandas as pd

from app.models import Gyms, RouteImages, Routes, UserRouteLog, Users


def preload_dummy_data(db):
    load_table(db, Users)
    load_table(db, Gyms)
    load_table(db, Routes)
    load_table(db, RouteImages)
    load_table(db, UserRouteLog)

    db.session.commit()


def load_table(db, ModelClass):
    table_name = ModelClass.__tablename__

    table_df = pd.read_csv(f"resources/{table_name}.csv")
    table_df = table_df.where(pd.notnull(table_df), None)
    db.session.add_all([
        ModelClass(**row)
        for _, row in table_df.iterrows()
    ])
    db.session.flush()

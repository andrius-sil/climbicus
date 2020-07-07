import pandas as pd

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

import pandas as pd
import os

user = os.environ["POSTGRES_USER"]
password = os.environ["POSTGRES_PASSWORD"]
host = os.environ["POSTGRES_HOST"]
database_name = os.environ["POSTGRES_DB"]
port = os.environ["POSTGRES_PORT"]

DATABASE_CONNECTION_URI = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database_name}"
query_path = "../utilities/data/get_data.sql"


def get_data(query_params=None):
    with open(query_path, "r") as fh:
        query = fh.read()
    if query_params:
        query = query.format(**query_params)
    df = pd.read_sql_query(query, con=DATABASE_CONNECTION_URI)
    return df

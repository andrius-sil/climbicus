import os

from app import create_app
from predictor.model_parameters import MODEL_PATH, MODEL_VERSION, CLASS_INDICES_PATH

user = os.environ["POSTGRES_USER"]
password = os.environ["POSTGRES_PASSWORD"]
host = os.environ["POSTGRES_HOST"]
database_name = os.environ["POSTGRES_DB"]
port = os.environ["POSTGRES_PORT"]

DATABASE_CONNECTION_URI = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database_name}"

app = create_app(DATABASE_CONNECTION_URI, MODEL_PATH, CLASS_INDICES_PATH, MODEL_VERSION)

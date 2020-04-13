import os

from werkzeug.middleware.profiler import ProfilerMiddleware

from app import create_app
from app.utils.io import S3InputOutputProvider

user = os.environ["POSTGRES_USER"]
password = os.environ["POSTGRES_PASSWORD"]
host = os.environ["POSTGRES_HOST"]
database_name = os.environ["POSTGRES_DB"]
port = os.environ["POSTGRES_PORT"]

DATABASE_CONNECTION_URI = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database_name}"
JWT_SECRET_KEY = os.environ["JWT_SECRET_KEY"]

DISABLE_AUTH = os.getenv("FLASK_DISABLE_AUTH", False)

ENV = os.getenv("ENV", "dev")
print(f"Running on '{ENV}'")

app = create_app(
    db_connection_uri=DATABASE_CONNECTION_URI,
    jwt_secret_key=JWT_SECRET_KEY,
    io_provider=S3InputOutputProvider(ENV),
    disable_auth=DISABLE_AUTH,
)

FLASK_PROFILE = os.getenv("FLASK_PROFILE", False)
if FLASK_PROFILE:
    app.wsgi_app = ProfilerMiddleware(app.wsgi_app)


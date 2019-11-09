from flask import Flask
from app.views import main_blueprint
from flask_sqlalchemy import SQLAlchemy
import os


user = os.environ["POSTGRES_USER"]
password = os.environ["POSTGRES_PASSWORD"]
host = "db"
database = os.environ["POSTGRES_DB"]
port = "5432"

DATABASE_CONNECTION_URI = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}"

db = SQLAlchemy()


def create_app():
    app = Flask(__name__)

    # Register Blueprints
    app.register_blueprint(main_blueprint)

    app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_CONNECTION_URI
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    db.init_app(app)
    with app.app_context():
        db.create_all()

    return app

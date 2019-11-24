import click
from flask import Flask
from flask.cli import with_appcontext
from flask_jwt_extended import JWTManager
from flask_sqlalchemy import SQLAlchemy

from app.app_handlers import register_handlers
from predictor.predictor import Predictor


db = SQLAlchemy()

predictor = Predictor()


def create_app(db_connection_uri, model_path, class_indices_path, model_version, jwt_secret_key):
    app = Flask(__name__)

    app.config["JWT_SECRET_KEY"] = jwt_secret_key
    app.config["JWT_ACCESS_TOKEN_EXPIRES"] = False
    _ = JWTManager(app)

    from app.views import users_blueprint
    from app import root
    app.register_blueprint(users_blueprint)
    app.register_blueprint(root.blueprint)

    register_handlers(app)

    app.config["SQLALCHEMY_DATABASE_URI"] = db_connection_uri
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    db.init_app(app)

    predictor.load_model(model_path, class_indices_path, model_version)

    app.cli.add_command(recreate_db_cmd)

    return app


@click.command("recreate-db")
@with_appcontext
def recreate_db_cmd():
    db.drop_all()
    db.create_all()
    print("Initialised the database")

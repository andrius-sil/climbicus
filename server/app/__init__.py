from flask import Flask
from flask_jwt_extended import JWTManager
from flask_sqlalchemy import SQLAlchemy

from app.app_handlers import register_handlers
from app.utils.io import InputOutput
from predictor.predictor import Predictor


db = SQLAlchemy()
predictor = Predictor()
io = InputOutput()


def create_app(db_connection_uri, model_path, class_indices_path, model_version, jwt_secret_key, io_provider, disable_auth=False):
    app = Flask(__name__)

    app.config["JWT_SECRET_KEY"] = jwt_secret_key
    app.config["JWT_ACCESS_TOKEN_EXPIRES"] = False
    _ = JWTManager(app)

    from app import root, routes, route_images, user_route_log
    app.register_blueprint(root.blueprint)
    app.register_blueprint(routes.blueprint)
    app.register_blueprint(route_images.blueprint)
    app.register_blueprint(user_route_log.blueprint)

    app.config["DISABLE_AUTH"] = disable_auth

    register_handlers(app)

    app.config["SQLALCHEMY_DATABASE_URI"] = db_connection_uri
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    db.init_app(app)

    predictor.load_model(model_path, class_indices_path, model_version)

    io.load(io_provider)

    from app.commands import recreate_db_cmd
    app.cli.add_command(recreate_db_cmd)

    return app

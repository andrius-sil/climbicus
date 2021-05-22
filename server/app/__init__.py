import boto3
from celery import Celery
from flask import Flask
from flask_jwt_extended import JWTManager
from flask_sqlalchemy import BaseQuery, SQLAlchemy
from flask_migrate import Migrate

from app.app_handlers import register_handlers
from app.utils.io import InputOutput
from predictor.cbir_predictor import CBIRPredictor


def create_celery(app_name=__name__):
    redis_uri = "redis://redis:6379"
    return Celery(
        app_name,
        backend=redis_uri,
        broker=redis_uri,
        include=['app.tasks'],
    )

db = SQLAlchemy()
cbir_predictor = CBIRPredictor()

io = InputOutput()
s3_client = boto3.client("s3")

celery = create_celery()


def init_celery(celery, app):
    celery.conf.update(app.config)

    class ContextTask(celery.Task):
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery.Task = ContextTask



def create_app(db_connection_uri, jwt_secret_key, io_provider, disable_auth=False, enable_user_verification=False):
    app = Flask(__name__)

    app.config["JWT_SECRET_KEY"] = jwt_secret_key
    app.config["JWT_ACCESS_TOKEN_EXPIRES"] = False
    jwt = JWTManager(app)

    from app import root, areas, gyms, routes, route_images, user_route_log, user_route_votes, users
    app.register_blueprint(root.blueprint)
    app.register_blueprint(areas.blueprint)
    app.register_blueprint(gyms.blueprint)
    app.register_blueprint(routes.blueprint)
    app.register_blueprint(route_images.blueprint)
    app.register_blueprint(user_route_log.blueprint)
    app.register_blueprint(users.blueprint)
    app.register_blueprint(user_route_votes.blueprint)

    app.config["DISABLE_AUTH"] = disable_auth
    app.config["ENABLE_USER_VERIFICATION"] = enable_user_verification

    register_handlers(app, jwt)

    app.config["SQLALCHEMY_DATABASE_URI"] = db_connection_uri
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    db.init_app(app)

    migrate = Migrate(app, db)

    io.load(io_provider)

    init_celery(celery, app)

    from app.commands import recreate_db_cmd, create_user_cmd, create_gym_cmd
    app.cli.add_command(recreate_db_cmd)
    app.cli.add_command(create_user_cmd)
    app.cli.add_command(create_gym_cmd)

    return app

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


# from https://blog.miguelgrinberg.com/post/implementing-the-soft-delete-pattern-with-flask-and-sqlalchemy
class QueryWithSoftDelete(BaseQuery):
    _with_deleted = False

    def __new__(cls, *args, **kwargs):
        obj = super(QueryWithSoftDelete, cls).__new__(cls)
        obj._with_deleted = kwargs.pop('_with_deleted', False)
        if len(args) > 0:
            super(QueryWithSoftDelete, obj).__init__(*args, **kwargs)
            return obj.filter_by(deleted_at=None) if not obj._with_deleted else obj
        return obj

    def __init__(self, *args, **kwargs):
        pass

    def with_deleted(self):
        return self.__class__(self._only_full_mapper_zero('get'),
                              session=db.session(), _with_deleted=True)

    def _get(self, *args, **kwargs):
        # this calls the original query.get function from the base class
        return super(QueryWithSoftDelete, self).get(*args, **kwargs)

    def get(self, *args, **kwargs):
        # the query.get method does not like it if there is a filter clause
        # pre-loaded, so we need to implement it using a workaround
        obj = self.with_deleted()._get(*args, **kwargs)
        return obj if obj is None or self._with_deleted or not obj.deleted else None

db = SQLAlchemy(query_class=QueryWithSoftDelete)
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

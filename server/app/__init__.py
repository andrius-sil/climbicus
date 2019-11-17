from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from predictor.predictor import Predictor


db = SQLAlchemy()

predictor = Predictor()


def create_app(db_connection_uri, model_path, class_indices_path, model_version):
    app = Flask(__name__)

    # Register Blueprints
    from app.views import users_blueprint, root_blueprint

    app.register_blueprint(users_blueprint)
    app.register_blueprint(root_blueprint)

    app.config["SQLALCHEMY_DATABASE_URI"] = db_connection_uri
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    db.init_app(app)
    with app.app_context():
        db.create_all()
        predictor.load_model(model_path, class_indices_path, model_version)

    return app

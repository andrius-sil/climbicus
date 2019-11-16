from flask import Flask
from flask_sqlalchemy import SQLAlchemy


db = SQLAlchemy()


def create_app(db_connection_uri):
    app = Flask(__name__)

    # Register Blueprints
    from app.views import user_blueprint, general_blueprint

    app.register_blueprint(user_blueprint)
    app.register_blueprint(general_blueprint)

    app.config["SQLALCHEMY_DATABASE_URI"] = db_connection_uri
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    db.init_app(app)
    with app.app_context():
        db.create_all()

    return app

from flask import Flask
from app.views import main_blueprint
from app.models import DATABASE_CONNECTION_URI, db


def create_app():
    app = Flask(__name__)

    # Register Blueprints
    app.register_blueprint(main_blueprint)

    app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_CONNECTION_URI
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.app_context().push()
    db.init_app(app)
    db.create_all()

    return app

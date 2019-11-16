from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import tensorflow as tf
from tensorflow.python.keras.models import load_model
from tensorflow.python.keras.backend import set_session
from predictor.model_parameters import MODEL_PATH

db = SQLAlchemy()

tf_session = tf.compat.v1.Session()
tf_graph = tf.compat.v1.get_default_graph()
set_session(tf_session)
model = load_model(MODEL_PATH)


def create_app(db_connection_uri):
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

    return app

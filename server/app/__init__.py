from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import os
import tensorflow as tf
from tensorflow.python.keras.models import load_model
from tensorflow.python.keras.backend import set_session
import pickle

user = os.environ["POSTGRES_USER"]
password = os.environ["POSTGRES_PASSWORD"]
host = os.environ["POSTGRES_HOST"]
database_name = os.environ["POSTGRES_DB"]
port = os.environ["POSTGRES_PORT"]

DATABASE_CONNECTION_URI = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database_name}"

db = SQLAlchemy()


def load_obj(path):
    """Loads the class indices dictionary"""
    with open(path, "rb") as f:
        return pickle.load(f)

tf_session = tf.compat.v1.Session()
tf_graph = tf.compat.v1.get_default_graph()

base_path = "/app/predictor/"
model_name = "castle_30_vgg_fine_tuned.h5"
MODEL_PATH = os.path.join(base_path, model_name)
CLASS_INDICES_PATH = os.path.join(base_path, "class_indices.pkl")
set_session(tf_session)
model = load_model(MODEL_PATH)
class_indices = load_obj(CLASS_INDICES_PATH)


def create_app():
    app = Flask(__name__)

    # Register Blueprints
    from app.views import main_blueprint

    app.register_blueprint(main_blueprint)

    app.config["SQLALCHEMY_DATABASE_URI"] = DATABASE_CONNECTION_URI
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    db.init_app(app)
    with app.app_context():
        db.create_all()

    return app


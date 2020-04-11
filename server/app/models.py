from enum import Enum, auto

from sqlalchemy.ext.hybrid import hybrid_property
from werkzeug.security import check_password_hash, generate_password_hash

from app import db, io
from app.utils.encoding import bytes_to_b64str


def model_repr(name, **kwargs):
    fields = ", ".join([f"{field}={value}" for field, value in kwargs.items()])
    return f"<{name}({fields})>"


class Users(db.Model):
    id = db.Column(db.Integer, db.Sequence('user_id_seq'), primary_key=True)
    email = db.Column(db.String, unique=True, nullable=False)
    _password = db.Column(db.String, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False)

    def __repr__(self):
        return model_repr("User", id=self.id, email=self.email)

    @hybrid_property
    def password(self):
        return self._password

    @password.setter
    def password(self, value):
        self._password = generate_password_hash(value)

    def check_password(self, value):
        return check_password_hash(self.password, value)


class Gyms(db.Model):
    id = db.Column(db.Integer, db.Sequence('gym_id_seq'), primary_key=True)
    name = db.Column(db.String, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False)

    def __repr__(self):
        return model_repr("Gym", id=self.id, name=self.name)


class RouteCategory(Enum):
    bouldering = auto()
    sport = auto()


class Routes(db.Model):
    id = db.Column(db.Integer, db.Sequence('route_id_seq'), primary_key=True)
    gym_id = db.Column(db.Integer, db.ForeignKey('gyms.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    category = db.Column(db.Enum(RouteCategory), nullable=False)
    grade = db.Column(db.String, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False)

    @property
    def api_model(self):
        return {
            "id": self.id,
            "gym_id": self.gym_id,
            "user_id": self.user_id,
            "category": self.category.name,
            "grade": self.grade,
            "created_at": self.created_at.isoformat(),
        }

    def __repr__(self):
        return model_repr("Route", id=self.id, gym_id=self.gym_id, category=self.category.name, grade=self.grade)


class RouteImages(db.Model):
    id = db.Column(db.Integer, db.Sequence('route_image_id_seq'), primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)

    """
    Columns indicating user's route choice.
    'route_id' can be NULL indicating that no response was received from a user.
    'route_unmatched' is True when user explicitly indicated that their image doesn't match our "list of routes".
    """
    route_id = db.Column(db.Integer, db.ForeignKey('routes.id'))
    route_unmatched = db.Column(db.Boolean, nullable=False, default=False)

    model_version = db.Column(db.String, nullable=False)
    path = db.Column(db.String, unique=True, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False)
    descriptors = db.Column(db.JSON, nullable=False)

    @property
    def api_model(self):
        fbytes = io.provider.download_file(self.path)
        base64_str = bytes_to_b64str(fbytes)

        return {
            "id": self.id,
            "user_id": self.user_id,
            "route_id": self.route_id,
            "created_at": self.created_at.isoformat(),
            "b64_image": base64_str,
        }

    def __repr__(self):
        return model_repr("RouteImage", id=self.id, user_id=self.user_id, route_id=self.route_id,
                          path=self.path)


class UserRouteLog(db.Model):
    id = db.Column(db.Integer, db.Sequence('user_route_log_id_seq'), primary_key=True)
    route_id = db.Column(db.Integer, db.ForeignKey('routes.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    gym_id = db.Column(db.Integer, db.ForeignKey('gyms.id'), nullable=False)
    completed = db.Column(db.Boolean, nullable=False)
    num_attempts = db.Column(db.Integer)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False)

    @property
    def api_model(self):
        return {
            "id": self.id,
            "route_id": self.route_id,
            "user_id": self.user_id,
            "gym_id": self.gym_id,
            "completed": self.completed,
            "num_attempts": self.num_attempts,
            "created_at": self.created_at.isoformat(),
        }

    def __repr__(self):
        return model_repr("UserRouteLog", id=self.id, route_id=self.route_id, user_id=self.user_id,
                          gym_id=self.gym_id, completed=self.completed,
                          num_attempts=self.num_attempts, created_at=self.created_at)

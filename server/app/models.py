from enum import Enum, auto

from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy import CheckConstraint, UniqueConstraint
from werkzeug.security import check_password_hash, generate_password_hash

from app import db
from app.database.soft_delete_mixin import SoftDeleteMixin
from app.utils.io import s3_cdn_path


def model_repr(_name, **kwargs):
    fields = ", ".join([f"{field}={value}" for field, value in kwargs.items()])
    return f"<{_name}({fields})>"


class Users(db.Model):
    id = db.Column(db.Integer, db.Sequence('user_id_seq'), primary_key=True)
    name = db.Column(db.String, nullable=False)
    email = db.Column(db.String, unique=True, nullable=False)
    _password = db.Column(db.String, nullable=False)
    verified = db.Column(db.Boolean, nullable=False)
    is_admin = db.Column(db.Boolean, nullable=False, default=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False)

    @property
    def api_model(self):
        # Do not put private user information here!
        return {
            "id": self.id,
            "name": self.name,
            "created_at": self.created_at.isoformat(),
        }

    def __repr__(self):
        return model_repr("User", id=self.id, name=self.name, email=self.email)

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
    has_bouldering = db.Column(db.Boolean, nullable=False)
    has_sport = db.Column(db.Boolean, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False)

    @property
    def api_model(self):
        return {
            "id": self.id,
            "name": self.name,
            "has_bouldering": self.has_bouldering,
            "has_sport": self.has_sport,
            "created_at": self.created_at.isoformat(),
        }

    def __repr__(self):
        return model_repr("Gym", id=self.id, name=self.name)


class Areas(db.Model):
    id = db.Column(db.Integer, db.Sequence('area_id_seq'), primary_key=True)
    gym_id = db.Column(db.Integer, db.ForeignKey('gyms.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    name = db.Column(db.String, nullable=False)
    image_path = db.Column(db.String, unique=True, nullable=False)
    thumbnail_image_path = db.Column(db.String, unique=True, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False)

    @property
    def api_model(self):
        return {
            "id": self.id,
            "gym_id": self.gym_id,
            "user_id": self.user_id,
            "name": self.name,
            "created_at": self.created_at.isoformat(),
            "image_path": s3_cdn_path(self.image_path),
            "thumbnail_image_path": s3_cdn_path(self.thumbnail_image_path),
        }

    def __repr__(self):
        return model_repr("Area", id=self.id, gym_id=self.gym_id, name=self.name)


class RouteCategory(Enum):
    bouldering = auto()
    sport = auto()


class GradeSystems:
    systems = {
        'V': ['VB', 'V0-', 'V0', 'V0+', 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8', 'V9', 'V10', 'V11', 'V12',
              'V13', 'V14', 'V15', 'V16', 'V17'],
        'French': ['1', '2', '3', '4', '4a', '4b', '4c', '5a', '5b', '5c', '6a', '6a+', '6b', '6b+', '6c', '6c+', '7a',
                   '7a+', '7b', '7b+', '8a', '8a+', '8b', '8b+', '8c', '8c+'],
        'Font': ['3', '4-', '4', '4+', '5', '5+', '6A', '6A+', '6B', '6B+', '6C', '6C+', '7A', '7A+', '7B', '7B+',
                 '7C', '7C+', '8A', '8A+', '8B', '8B+', '8C', '8C+', '9A'],
    }

    @staticmethod
    def enum_list():
        enum_list = []
        for system, grades in GradeSystems.systems.items():
            for g in grades:
                enum_list.append(f"{system}_{g}")
        return enum_list


grade_enum_values = GradeSystems.enum_list()


class RouteDifficulty(Enum):
    soft = -1.0
    fair = 0.0
    hard = 1.0


class Routes(SoftDeleteMixin, db.Model):
    id = db.Column(db.Integer, db.Sequence('route_id_seq'), primary_key=True)
    gym_id = db.Column(db.Integer, db.ForeignKey('gyms.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    area_id = db.Column(db.Integer, db.ForeignKey('areas.id'), nullable=False)
    name = db.Column(db.String)
    category = db.Column(db.Enum(RouteCategory), nullable=False)
    lower_grade = db.Column(db.Enum(*grade_enum_values, name='lowergrade'), nullable=False)
    upper_grade = db.Column(db.Enum(*grade_enum_values, name='uppergrade'), nullable=False)
    avg_difficulty = db.Column(db.Enum(RouteDifficulty))
    avg_quality = db.Column(db.Float)
    count_ascents = db.Column(db.Integer, nullable=False)
    color = db.Column(db.String, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False)

    __table_args__ = (
        CheckConstraint('avg_quality >= 1.0'),
        CheckConstraint('avg_quality <= 3.0'),
    )

    @property
    def api_model(self):
        return {
            "id": self.id,
            "gym_id": self.gym_id,
            "user_id": self.user_id,
            "area_id": self.area_id,
            "name": self.name,
            "category": self.category.name,
            "lower_grade": self.lower_grade,
            "upper_grade": self.upper_grade,
            "avg_difficulty": self.avg_difficulty_name,
            "avg_quality": self.avg_quality,
            "count_ascents": self.count_ascents,
            "color": self.color,
            "created_at": self.created_at.isoformat(),
        }

    @property
    def avg_difficulty_name(self):
        return self.avg_difficulty.name if self.avg_difficulty else None

    def __repr__(self):
        return model_repr("Route", id=self.id, gym_id=self.gym_id, category=self.category.name, name=self.name,
                          lower_grade=self.lower_grade, upper_grade=self.upper_grade,
                          avg_difficulty=self.avg_difficulty_name, avg_quality=self.avg_quality,
                          count_ascents=self.count_ascents)


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
    thumbnail_path = db.Column(db.String, unique=True, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False)
    descriptors = db.Column(db.LargeBinary, nullable=False)

    @property
    def api_model(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "route_id": self.route_id,
            "created_at": self.created_at.isoformat(),
            "path": s3_cdn_path(self.path),
            "thumbnail_path": s3_cdn_path(self.thumbnail_path),
        }

    def __repr__(self):
        return model_repr("RouteImage", id=self.id, user_id=self.user_id, route_id=self.route_id,
                          path=self.path, thumbnail_path=self.thumbnail_path)


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


class UserRouteVotes(db.Model):
    id = db.Column(db.Integer, db.Sequence('user_route_votes_id_seq'), primary_key=True)
    route_id = db.Column(db.Integer, db.ForeignKey('routes.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    gym_id = db.Column(db.Integer, db.ForeignKey('gyms.id'), nullable=False)
    quality = db.Column(db.Float)
    _difficulty = db.Column(db.Enum(RouteDifficulty))
    created_at = db.Column(db.DateTime(timezone=True), nullable=False)
    __table_args__ = (
        CheckConstraint('quality >= 1.0'),
        CheckConstraint('quality <= 3.0'),
        UniqueConstraint('user_id', 'route_id'),
    )

    @property
    def api_model(self):
        return {
            "id": self.id,
            "route_id": self.route_id,
            "user_id": self.user_id,
            "gym_id": self.gym_id,
            "quality": self.quality,
            "difficulty": self.difficulty_name,
            "created_at": self.created_at.isoformat(),
        }

    @hybrid_property
    def difficulty(self):
        return self._difficulty

    @difficulty.setter
    def difficulty(self, value):
        """
        Explicitly converting to enumerated type,
        so that ORM code has the right types without running COMMIT.
        """
        try:
            final_value = RouteDifficulty[value]
        except KeyError:
            # Let DB constraints deal with invalid values.
            final_value = value

        self._difficulty = final_value

    @property
    def difficulty_name(self):
        return self.difficulty.name if self.difficulty else None

    def __repr__(self):
        return model_repr("UserRouteLog", id=self.id, route_id=self.route_id, user_id=self.user_id,
                          gym_id=self.gym_id, quality=self.quality, difficulty=self.difficulty_name,
                          created_at=self.created_at)

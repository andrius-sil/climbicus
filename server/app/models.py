from app import db


class Users(db.Model):
    id = db.Column(db.Integer, db.Sequence('user_id_seq'), primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)


class Gyms(db.Model):
    id = db.Column(db.Integer, db.Sequence('gym_id_seq'), primary_key=True)
    name = db.Column(db.String(120), nullable=False)


class Routes(db.Model):
    id = db.Column(db.Integer, db.Sequence('route_id_seq'), primary_key=True)
    gym_id = db.Column(db.Integer, db.ForeignKey('gyms.id'), nullable=False)
    # TODO: class_id and id should have a 1-1 relationship
    class_id = db.Column(db.String(120), unique=True, nullable=False)
    # TODO: preset list of possible grades
    grade = db.Column(db.String(120), nullable=False)

    def get_class_id_dict(self, routes):
        routes_dict = {r.class_id: {"id": r.id, "grade": r.grade} for r in routes}
        return routes_dict

    def create_route_entry(self, class_id, probability, routes_dict):
        result = {
            "route_id": routes_dict.get(class_id).get("id"),
            "predicted_class_id": class_id,
            "probability": probability,
            "grade": routes_dict.get(class_id).get("grade"),
        }
        return result


class RouteImages(db.Model):
    id = db.Column(db.Integer, db.Sequence('route_image_id_seq'), primary_key=True)
    route_id = db.Column(db.Integer, db.ForeignKey('routes.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    probability = db.Column(db.Float, nullable=False)
    model_version = db.Column(db.String(120), nullable=False)
    path = db.Column(db.String(120), unique=True, nullable=False)


class UserRouteLog(db.Model):
    id = db.Column(db.Integer, db.Sequence('user_route_lod_id_seq'), primary_key=True)
    route_id = db.Column(db.Integer, db.ForeignKey('routes.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    gym_id = db.Column(db.Integer, db.ForeignKey('gyms.id'), nullable=False)
    status = db.Column(db.String(120), nullable=False)
    log_date = db.Column(db.DateTime, nullable=False)

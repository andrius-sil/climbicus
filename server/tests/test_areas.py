from datetime import datetime
from flask import json
from unittest import mock
from unittest.mock import Mock
from uuid import UUID

import pytz

from app import db
from app.models import Areas


def test_areas(client, auth_headers_user1):
    data = {
        "user_id": 1,
        "gym_id": 1,
    }
    resp = client.get("/areas/", data=json.dumps(data), content_type="application/json", headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    expected_areas = {
        "1": {"id": 1, "gym_id": 1, "user_id": 1, "name": "Cave", "image_path": "area_images/area1.jpg",
              "created_at": "2019-03-04T10:10:10+00:00"},
        "2": {"id": 2, "gym_id": 1, "user_id": 1, "name": "Prow", "image_path": "area_images/area2.jpg",
              "created_at": "2019-03-04T10:10:10+00:00"},
    }

    assert resp.json["areas"] == expected_areas


@mock.patch("datetime.datetime", Mock(utcnow=lambda: datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)))
@mock.patch("uuid.uuid4", lambda: UUID('12345678123456781234567812345678'))
def test_add_area(app, client, resource_dir, auth_headers_user1):
    json_data = {
        "user_id": 1,
        "gym_id": 1,
        "name": "Area 51",
    }
    data = {
        "json": json.dumps(json_data),
        "image": open(f"{resource_dir}/area_images/area1.jpg", "rb"),
    }

    resp = client.post("/areas/", data=data, headers=auth_headers_user1)

    assert resp.status_code == 200
    assert resp.is_json

    assert resp.json["area"] == {
        "id": 3, "gym_id": 1, "user_id": 1, "name": "Area 51", "created_at": "2019-03-04T10:10:10+00:00",
        "image_path": "/tmp/climbicus_tests/area_images/from_users/gym_id=1/year=2019/month=03/12345678123456781234567812345678.jpg",
    }

    with app.app_context():
        stored_area = db.session.query(Areas).filter_by(id=3).one()
        assert stored_area.id == 3
        assert stored_area.gym_id == 1
        assert stored_area.user_id == 1
        assert stored_area.name == "Area 51"
        assert stored_area.image_path == "/tmp/climbicus_tests/area_images/from_users/gym_id=1/year=2019/month=03/12345678123456781234567812345678.jpg"
        assert stored_area.created_at == datetime(2019, 3, 4, 10, 10, 10, tzinfo=pytz.UTC)

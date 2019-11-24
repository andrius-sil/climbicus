import click
from flask.cli import with_appcontext

from app import db
from scripts.dummy_db_data import preload_dummy_data


@click.command("recreate-db")
@with_appcontext
def recreate_db_cmd():
    db.drop_all()
    db.create_all()
    print("Initialised the database")

    preload_dummy_data(db)
    print("Preloaded dummy data in the database")

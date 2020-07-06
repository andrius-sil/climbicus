import click
from flask.cli import with_appcontext

from app import db
from scripts.dummy_db_data import preload_dummy_data


@click.command("recreate-db")
@click.option("--tables", type=str)
@with_appcontext
def recreate_db_cmd(tables):
    db.drop_all()
    db.create_all()
    print("Initialised the database")

    if tables is not None:
        tables = tables.split(",")
    preload_dummy_data(db, tables)
    print("Preloaded dummy data in the database")

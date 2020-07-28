import click
from flask.cli import with_appcontext

from app import db
from scripts.dummy_db_data import preload_dummy_data, create_user, create_gym


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


@click.command("create-user")
@click.option("--email", type=str)
@click.option("--password", type=str)
@with_appcontext
def create_user_cmd(email, password):
    create_user(db, email, password)
    print(f"Created new user '{email}'")


@click.command("create-gym")
@click.option("--name", type=str)
@click.option("--bouldering/--no-bouldering", default=False)
@click.option("--sport/--no-sport", default=False)
@with_appcontext
def create_gym_cmd(name, bouldering, sport):
    create_gym(db, name, bouldering, sport)
    print(f"Created new gym '{name}'")

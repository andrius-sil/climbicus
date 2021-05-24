"""new_columns

Revision ID: 591b578d9e5f
Revises: 54491634c745
Create Date: 2021-05-24 20:09:27.253554

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '591b578d9e5f'
down_revision = '54491634c745'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('routes', sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True))

    op.add_column('users', sa.Column('is_admin', sa.Boolean(), nullable=True))
    op.execute("UPDATE users SET is_admin=false")
    op.alter_column('users', 'is_admin', nullable=False)


def downgrade():
    op.drop_column('users', 'is_admin')
    op.drop_column('routes', 'deleted_at')

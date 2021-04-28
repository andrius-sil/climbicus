"""thumbnails

Revision ID: 54491634c745
Revises: 
Create Date: 2021-04-27 20:42:25.353038

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '54491634c745'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('areas', sa.Column('thumbnail_image_path', sa.String(), nullable=True))
    op.execute("UPDATE areas SET thumbnail_image_path=image_path")
    op.alter_column('areas', 'thumbnail_image_path', nullable=False)

    op.add_column('route_images', sa.Column('thumbnail_path', sa.String(), nullable=True))
    op.execute("UPDATE route_images SET thumbnail_path=replace(path, 'month=04/', 'month=04/thumbnail/')")
    op.alter_column('route_images', 'thumbnail_path', nullable=False)


def downgrade():
    op.drop_column('route_images', 'thumbnail_path')
    op.drop_column('areas', 'thumbnail_image_path')

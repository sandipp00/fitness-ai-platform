"""Add admin flag, token version and profile timezone."""
from alembic import op
import sqlalchemy as sa

revision = "0002_auth_and_timezone"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("users") as batch:
        batch.add_column(sa.Column("is_admin", sa.Boolean(), nullable=False, server_default=sa.false()))
        batch.add_column(sa.Column("token_version", sa.Integer(), nullable=False, server_default="0"))
    with op.batch_alter_table("profiles") as batch:
        batch.add_column(sa.Column("timezone", sa.String(64), nullable=False, server_default="UTC"))


def downgrade() -> None:
    with op.batch_alter_table("profiles") as batch:
        batch.drop_column("timezone")
    with op.batch_alter_table("users") as batch:
        batch.drop_column("token_version")
        batch.drop_column("is_admin")

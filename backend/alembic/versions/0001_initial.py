"""Initial Fitness AI Platform schema."""
from alembic import op
import sqlalchemy as sa

revision = "0001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table("users",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table("profiles",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("age", sa.Integer(), nullable=True),
        sa.Column("height_cm", sa.Float(), nullable=True),
        sa.Column("weight_kg", sa.Float(), nullable=True),
        sa.Column("goal", sa.String(80), nullable=False),
        sa.Column("activity_level", sa.String(40), nullable=False),
        sa.UniqueConstraint("user_id"),
    )

    op.create_table("activity",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("day", sa.Date(), nullable=False),
        sa.Column("steps", sa.Integer(), nullable=False),
        sa.Column("active_minutes", sa.Integer(), nullable=False),
        sa.Column("calories_burned", sa.Float(), nullable=False),
        sa.Column("distance_km", sa.Float(), nullable=False),
        sa.UniqueConstraint("user_id", "day", name="uq_activity_user_day"),
    )
    op.create_index("ix_activity_user_id", "activity", ["user_id"])
    op.create_index("ix_activity_day", "activity", ["day"])

    op.create_table("workouts",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("day", sa.Date(), nullable=False),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
        sa.Column("calories_burned", sa.Float(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
    )
    op.create_index("ix_workouts_user_id", "workouts", ["user_id"])
    op.create_index("ix_workouts_day", "workouts", ["day"])

    op.create_table("sleep",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("day", sa.Date(), nullable=False),
        sa.Column("duration_hours", sa.Float(), nullable=False),
        sa.Column("quality", sa.Integer(), nullable=False),
        sa.UniqueConstraint("user_id", "day", name="uq_sleep_user_day"),
    )
    op.create_index("ix_sleep_user_id", "sleep", ["user_id"])
    op.create_index("ix_sleep_day", "sleep", ["day"])

    op.create_table("weight",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("day", sa.Date(), nullable=False),
        sa.Column("weight_kg", sa.Float(), nullable=False),
    )
    op.create_index("ix_weight_user_id", "weight", ["user_id"])
    op.create_index("ix_weight_day", "weight", ["day"])

    op.create_table("water",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("day", sa.Date(), nullable=False),
        sa.Column("liters", sa.Float(), nullable=False),
        sa.UniqueConstraint("user_id", "day", name="uq_water_user_day"),
    )
    op.create_index("ix_water_user_id", "water", ["user_id"])
    op.create_index("ix_water_day", "water", ["day"])

    op.create_table("resources",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("category", sa.String(80), nullable=False),
        sa.Column("source", sa.String(255), nullable=False),
        sa.Column("url", sa.String(1000), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
    )

    op.create_table("workout_plans",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("week_start", sa.Date(), nullable=False),
        sa.Column("goal", sa.String(80), nullable=False),
        sa.Column("level", sa.String(40), nullable=False),
        sa.Column("plan_json", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
    )
    op.create_index("ix_workout_plans_user_id", "workout_plans", ["user_id"])
    op.create_index("ix_workout_plans_week_start", "workout_plans", ["week_start"])

    op.create_table("progress_snapshots",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("day", sa.Date(), nullable=False),
        sa.Column("steps", sa.Integer(), nullable=False),
        sa.Column("active_minutes", sa.Integer(), nullable=False),
        sa.Column("sleep_hours", sa.Float(), nullable=False),
        sa.Column("activity_score", sa.Integer(), nullable=False),
        sa.Column("sleep_score", sa.Integer(), nullable=False),
        sa.Column("recovery_score", sa.Integer(), nullable=False),
        sa.UniqueConstraint("user_id", "day", name="uq_progress_user_day"),
    )
    op.create_index("ix_progress_snapshots_user_id", "progress_snapshots", ["user_id"])
    op.create_index("ix_progress_snapshots_day", "progress_snapshots", ["day"])


def downgrade() -> None:
    op.drop_table("progress_snapshots")
    op.drop_table("workout_plans")
    op.drop_table("resources")
    op.drop_table("water")
    op.drop_table("weight")
    op.drop_table("sleep")
    op.drop_table("workouts")
    op.drop_table("activity")
    op.drop_table("profiles")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")

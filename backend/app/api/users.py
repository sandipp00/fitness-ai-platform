import json
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..deps import get_current_user
from ..models import (
    Activity,
    Profile,
    ProgressSnapshot,
    Sleep,
    User,
    Water,
    Weight,
    Workout,
    WorkoutPlan,
)
from ..schemas import DeleteAccountIn, ProfileIn, ProfileOut, TimezoneIn
from ..security import verify_password

router = APIRouter()

# Every table holding per-user rows; used by export and account deletion.
USER_DATA_MODELS = {
    "activity": Activity,
    "sleep": Sleep,
    "workouts": Workout,
    "weight": Weight,
    "water": Water,
    "workout_plans": WorkoutPlan,
    "progress_snapshots": ProgressSnapshot,
}


def _ensure_profile(user: User, db: Session) -> Profile:
    if user.profile is None:
        user.profile = Profile(user_id=user.id)
        db.commit()
    return user.profile


def _profile_out(user: User, profile: Profile) -> ProfileOut:
    return ProfileOut(
        user_id=user.id,
        name=profile.name,
        age=profile.age,
        height_cm=profile.height_cm,
        weight_kg=profile.weight_kg,
        goal=profile.goal,
        activity_level=profile.activity_level,
        timezone=profile.timezone or "UTC",
    )


def _row_to_dict(row) -> dict:
    data = {}
    for column in row.__table__.columns:
        value = getattr(row, column.name)
        if column.name == "plan_json" and value:
            value = json.loads(value)
        elif hasattr(value, "isoformat"):
            value = value.isoformat()
        data[column.name] = value
    data.pop("user_id", None)
    return data


@router.get("/me", response_model=ProfileOut)
def get_profile(user=Depends(get_current_user), db: Session = Depends(get_db)):
    return _profile_out(user, _ensure_profile(user, db))


@router.put("/me", response_model=ProfileOut)
def update_profile(payload: ProfileIn, user=Depends(get_current_user), db: Session = Depends(get_db)):
    profile = _ensure_profile(user, db)
    # Only fields the client sent are changed, so older clients that do not
    # know about e.g. `timezone` cannot reset it to the default.
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(profile, key, value)
    db.commit()
    return _profile_out(user, profile)


@router.put("/me/timezone", response_model=ProfileOut)
def update_timezone(payload: TimezoneIn, user=Depends(get_current_user), db: Session = Depends(get_db)):
    profile = _ensure_profile(user, db)
    profile.timezone = payload.timezone
    db.commit()
    return _profile_out(user, profile)


@router.get("/me/export")
def export_my_data(user=Depends(get_current_user), db: Session = Depends(get_db)):
    """Machine-readable copy of everything stored about the user."""
    profile = _ensure_profile(user, db)
    data = {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "account": {"email": user.email, "created_at": user.created_at.isoformat() if user.created_at else None},
        "profile": _profile_out(user, profile).model_dump(exclude={"user_id"}),
    }
    for name, model in USER_DATA_MODELS.items():
        rows = db.query(model).filter(model.user_id == user.id).order_by(model.id).all()
        data[name] = [_row_to_dict(row) for row in rows]
    return data


@router.delete("/me", status_code=204)
def delete_account(payload: DeleteAccountIn, user=Depends(get_current_user), db: Session = Depends(get_db)):
    """Permanently delete the account and all of its health data."""
    if not verify_password(payload.password, user.password_hash):
        raise HTTPException(403, "Password is incorrect")
    for model in USER_DATA_MODELS.values():
        db.query(model).filter(model.user_id == user.id).delete(synchronize_session=False)
    db.delete(user)  # cascades to the profile
    db.commit()

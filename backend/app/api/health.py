from datetime import date
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..database import get_db
from ..deps import get_current_user
from ..models import Sleep, Weight, Water, Activity, ProgressSnapshot
from ..schemas import SleepIn, WeightIn, WaterIn, ActivityIn, HealthSyncIn
from ..services.analytics import activity_score, sleep_score, recovery_score

router = APIRouter()


def _activity_for_day(db: Session, user_id: int, day: date):
    return db.query(Activity).filter(Activity.user_id == user_id, Activity.day == day).first()


def _sleep_for_day(db: Session, user_id: int, day: date):
    return db.query(Sleep).filter(Sleep.user_id == user_id, Sleep.day == day).first()


def _snapshot_for_day(db: Session, user_id: int, day: date):
    return db.query(ProgressSnapshot).filter(
        ProgressSnapshot.user_id == user_id,
        ProgressSnapshot.day == day,
    ).first()


def _refresh_snapshot(db: Session, user_id: int, day: date):
    activity_row = _activity_for_day(db, user_id, day)
    sleep_row = _sleep_for_day(db, user_id, day)
    if not activity_row and not sleep_row:
        return
    values = {
        "steps": activity_row.steps if activity_row else 0,
        "active_minutes": activity_row.active_minutes if activity_row else 0,
        "sleep_hours": sleep_row.duration_hours if sleep_row else 0,
        "activity_score": activity_score(activity_row.steps if activity_row else 0, activity_row.active_minutes if activity_row else 0),
        "sleep_score": sleep_score(sleep_row.duration_hours if sleep_row else 0, sleep_row.quality if sleep_row else 3),
        "recovery_score": recovery_score(
            activity_score(activity_row.steps if activity_row else 0, activity_row.active_minutes if activity_row else 0),
            sleep_score(sleep_row.duration_hours if sleep_row else 0, sleep_row.quality if sleep_row else 3),
        ),
    }
    snapshot = _snapshot_for_day(db, user_id, day)
    if snapshot is None:
        db.add(ProgressSnapshot(user_id=user_id, day=day, **values))
    else:
        for key, value in values.items():
            setattr(snapshot, key, value)


@router.post("/activity")
def add_activity(payload: ActivityIn, user=Depends(get_current_user), db: Session = Depends(get_db)):
    row = _activity_for_day(db, user.id, payload.day)
    if row is None:
        row = Activity(user_id=user.id, **payload.model_dump())
        db.add(row)
    else:
        for key, value in payload.model_dump().items():
            setattr(row, key, value)
    _refresh_snapshot(db, user.id, payload.day)
    db.commit()
    db.refresh(row)
    return {"id": row.id, **payload.model_dump()}


@router.post("/sleep")
def add_sleep(payload: SleepIn, user=Depends(get_current_user), db: Session = Depends(get_db)):
    row = _sleep_for_day(db, user.id, payload.day)
    if row is None:
        row = Sleep(user_id=user.id, **payload.model_dump())
        db.add(row)
    else:
        for key, value in payload.model_dump().items():
            setattr(row, key, value)
    _refresh_snapshot(db, user.id, payload.day)
    db.commit()
    db.refresh(row)
    return {"id": row.id, **payload.model_dump()}


@router.post("/weight")
def add_weight(payload: WeightIn, user=Depends(get_current_user), db: Session = Depends(get_db)):
    row = Weight(user_id=user.id, **payload.model_dump())
    db.add(row)
    db.commit()
    db.refresh(row)
    return {"id": row.id, **payload.model_dump()}


@router.post("/water")
def add_water(payload: WaterIn, user=Depends(get_current_user), db: Session = Depends(get_db)):
    row = db.query(Water).filter(Water.user_id == user.id, Water.day == payload.day).first()
    if row is None:
        row = Water(user_id=user.id, **payload.model_dump())
        db.add(row)
    else:
        row.liters = payload.liters
    db.commit()
    db.refresh(row)
    return {"id": row.id, **payload.model_dump()}


@router.post("/sync")
def sync_health_data(payload: HealthSyncIn, user=Depends(get_current_user), db: Session = Depends(get_db)):
    """Upsert normalized daily health data from Health Connect/HealthKit adapters."""
    day = payload.day
    activity = payload.activity
    sleep = payload.sleep

    if activity:
        row = _activity_for_day(db, user.id, day)
        values = activity.model_dump()
        if row is None:
            db.add(Activity(user_id=user.id, day=day, **values))
        else:
            for key, value in values.items():
                setattr(row, key, value)

    if sleep.duration_hours > 0:
        row = _sleep_for_day(db, user.id, day)
        values = sleep.model_dump()
        if row is None:
            db.add(Sleep(user_id=user.id, day=day, **values))
        else:
            for key, value in values.items():
                setattr(row, key, value)

    _refresh_snapshot(db, user.id, day)
    db.commit()
    return {"status": "synced", "day": day, "source": payload.source}

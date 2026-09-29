from datetime import date
import json
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import Profile, WorkoutPlan, ProgressSnapshot, Activity, Sleep
from ..services.analytics import recovery_score, activity_score, sleep_score
from ..services.trends import historical_summary
from ..services.workout_planner import build_adaptive_plan
from ..services.personalization_model import personalization_model

router = APIRouter()


@router.get("/trends")
def trends(
    days: int = 28,
    user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    days = min(90, max(7, days))
    return historical_summary(db, user.id, days)


@router.get("/workout-plan")
def workout_plan(
    user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = db.query(Profile).filter(Profile.user_id == user.id).first()
    activities = (
        db.query(Activity)
        .filter(Activity.user_id == user.id)
        .order_by(Activity.day.desc())
        .limit(28)
        .all()
    )
    sleeps = (
        db.query(Sleep)
        .filter(Sleep.user_id == user.id)
        .order_by(Sleep.day.desc())
        .limit(28)
        .all()
    )

    avg_steps = sum(x.steps for x in activities) / len(activities) if activities else 0
    avg_active = (
        sum(x.active_minutes for x in activities) / len(activities)
        if activities else 0
    )
    avg_sleep = sum(x.duration_hours for x in sleeps) / len(sleeps) if sleeps else 0
    recovery = recovery_score(activities[0] if activities else None,
                              sleeps[0] if sleeps else None)

    goal = profile.goal if profile and profile.goal else "general fitness"
    level = "beginner"
    summary = historical_summary(db, user.id, 28)
    ml_result = personalization_model.predict(summary["series"])

    plan = build_adaptive_plan(
        goal=goal,
        level=level,
        avg_steps=avg_steps,
        avg_active_minutes=avg_active,
        avg_sleep_hours=avg_sleep,
        recovery_score=recovery,
        ml_level=ml_result.recommended_level,
        ml_explanation=ml_result.explanation,
    )
    plan["personalization"] = {
        "model_version": ml_result.model_version,
        "readiness": ml_result.readiness,
        "adherence_probability": ml_result.adherence_probability,
        "explanation": ml_result.explanation,
    }

    row = WorkoutPlan(
        user_id=user.id,
        week_start=date.today(),
        goal=goal,
        level=level,
        plan_json=json.dumps(plan),
    )
    db.add(row)
    db.commit()

    return {"plan": plan, "id": row.id}


@router.get("/progress")
def progress(
    user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(ProgressSnapshot)
        .filter(ProgressSnapshot.user_id == user.id)
        .order_by(ProgressSnapshot.day.desc())
        .limit(30)
        .all()
    )
    return {
        "items": [
            {
                "day": x.day.isoformat(),
                "steps": x.steps,
                "active_minutes": x.active_minutes,
                "sleep_hours": x.sleep_hours,
                "activity_score": x.activity_score,
                "sleep_score": x.sleep_score,
                "recovery_score": x.recovery_score,
            }
            for x in rows
        ]
    }


@router.get("/personalization")
def personalization(
    user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    summary = historical_summary(db, user.id, 28)
    result = personalization_model.predict(summary["series"])
    return {
        "model_version": result.model_version,
        "readiness": result.readiness,
        "adherence_probability": result.adherence_probability,
        "recommended_level": result.recommended_level,
        "explanation": result.explanation,
        "features": summary["averages"],
    }

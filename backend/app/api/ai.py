from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..database import get_db
from ..deps import get_current_user
from ..models import Activity, Sleep, Profile
from ..services.analytics import activity_score, sleep_score, recovery_score
from ..services.recommendations import build_recommendations
from ..services.coach import answer as coach_answer

router = APIRouter()


def _context(user, db: Session) -> dict:
    profile = db.query(Profile).filter(Profile.user_id == user.id).first()
    activity = (
        db.query(Activity)
        .filter(Activity.user_id == user.id)
        .order_by(Activity.day.desc())
        .first()
    )
    sleep = (
        db.query(Sleep)
        .filter(Sleep.user_id == user.id)
        .order_by(Sleep.day.desc())
        .first()
    )

    steps = activity.steps if activity else 0
    active_minutes = activity.active_minutes if activity else 0
    calories = activity.calories_burned if activity else 0.0
    sleep_hours = sleep.duration_hours if sleep else 0.0
    quality = sleep.quality if sleep else 3

    return {
        "goal": profile.goal if profile and profile.goal else "general fitness",
        "steps": steps,
        "active_minutes": active_minutes,
        "calories_burned": calories,
        "sleep_hours": sleep_hours,
        "sleep_quality": quality,
        "activity_score": activity_score(steps, active_minutes),
        "sleep_score": sleep_score(sleep_hours, quality),
        "recovery_score": recovery_score(activity, sleep),
    }


@router.post("/chat")
def chat(payload: dict, user=Depends(get_current_user), db: Session = Depends(get_db)):
    question = str(payload.get("message", "")).strip()
    if not question:
        return {"answer": "Ask me a fitness or wellness question.", "sources": []}

    result = coach_answer(question, _context(user, db))
    return {
        "answer": result["answer"],
        "mode": result["mode"],
        "sources": result["sources"],
        "disclaimer": (
            "Wellness information only; not medical diagnosis or treatment."
        ),
    }


@router.get("/recommendations")
def recommendations(user=Depends(get_current_user), db: Session = Depends(get_db)):
    context = _context(user, db)
    items = build_recommendations(
        steps=context["steps"],
        active_minutes=context["active_minutes"],
        sleep_hours=context["sleep_hours"],
        recovery_score=context["recovery_score"],
        goal=context["goal"],
    )
    return {
        "scores": {
            "activity": context["activity_score"],
            "sleep": context["sleep_score"],
            "recovery": context["recovery_score"],
        },
        "metrics": {
            "steps": context["steps"],
            "active_minutes": context["active_minutes"],
            "calories_burned": context["calories_burned"],
            "sleep_hours": context["sleep_hours"],
        },
        "recommendations": [item.__dict__ for item in items],
        "disclaimer": (
            "Wellness guidance only; this is not medical diagnosis or treatment."
        ),
    }

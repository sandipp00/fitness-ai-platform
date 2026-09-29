from datetime import date
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..database import get_db
from ..deps import get_current_user
from ..models import Activity, Sleep, Workout, Water, Weight
from ..services.analytics import activity_score, sleep_score, recovery_score, recommendations

router = APIRouter()

@router.get("")
def dashboard(user=Depends(get_current_user), db: Session = Depends(get_db)):
    today = date.today()
    a = db.query(Activity).filter(Activity.user_id == user.id, Activity.day == today).first()
    s = db.query(Sleep).filter(Sleep.user_id == user.id, Sleep.day == today).first()
    w = db.query(Weight).filter(Weight.user_id == user.id).order_by(Weight.day.desc()).first()
    water = db.query(Water).filter(Water.user_id == user.id, Water.day == today).first()
    workouts = db.query(Workout).filter(Workout.user_id == user.id, Workout.day == today).all()

    a_score = activity_score(a.steps, a.active_minutes) if a else 0
    s_score = sleep_score(s.duration_hours, s.quality) if s else 0
    r_score = recovery_score(a_score, s_score) if a and s else s_score if s else 0

    goal = user.profile.goal if user.profile else "improve_fitness"
    return {
        "date": today,
        "activity": {
            "steps": a.steps if a else 0,
            "active_minutes": a.active_minutes if a else 0,
            "calories_burned": a.calories_burned if a else 0,
            "distance_km": a.distance_km if a else 0,
        },
        "sleep": {"hours": s.duration_hours if s else 0, "quality": s.quality if s else 0},
        "weight_kg": w.weight_kg if w else None,
        "water_liters": water.liters if water else 0,
        "workouts_today": len(workouts),
        "scores": {
            "activity": a_score,
            "sleep": s_score,
            "recovery": r_score,
        },
        "recommendations": recommendations(a_score, s_score, goal),
    }

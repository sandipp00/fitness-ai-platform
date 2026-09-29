from datetime import date, timedelta
from statistics import mean
from sqlalchemy.orm import Session
from ..models import Activity, Sleep


def _avg(values):
    values = [v for v in values if v is not None]
    return round(mean(values), 2) if values else 0.0


def historical_summary(db: Session, user_id: int, days: int = 28) -> dict:
    start = date.today() - timedelta(days=days - 1)

    activities = (
        db.query(Activity)
        .filter(Activity.user_id == user_id, Activity.day >= start)
        .order_by(Activity.day.asc())
        .all()
    )
    sleeps = (
        db.query(Sleep)
        .filter(Sleep.user_id == user_id, Sleep.day >= start)
        .order_by(Sleep.day.asc())
        .all()
    )

    activity_by_day = {x.day: x for x in activities}
    sleep_by_day = {x.day: x for x in sleeps}

    series = []
    for offset in range(days):
        day = start + timedelta(days=offset)
        a = activity_by_day.get(day)
        s = sleep_by_day.get(day)
        series.append({
            "day": day.isoformat(),
            "steps": a.steps if a else 0,
            "active_minutes": a.active_minutes if a else 0,
            "sleep_hours": round(s.duration_hours, 2) if s else 0,
        })

    recorded_activity = [x for x in activities]
    recorded_sleep = [x for x in sleeps]

    avg_steps = _avg([x.steps for x in recorded_activity])
    avg_active = _avg([x.active_minutes for x in recorded_activity])
    avg_sleep = _avg([x.duration_hours for x in recorded_sleep])

    # Compare the most recent 7 days with the previous 7 days when enough
    # history exists. This is a trend signal, not a prediction.
    recent = series[-7:]
    previous = series[-14:-7] if len(series) >= 14 else []

    def delta(key):
        a = _avg([x[key] for x in recent])
        b = _avg([x[key] for x in previous])
        return round(a - b, 2) if previous else 0.0

    return {
        "days": days,
        "averages": {
            "steps": avg_steps,
            "active_minutes": avg_active,
            "sleep_hours": avg_sleep,
        },
        "recent_vs_previous": {
            "steps": delta("steps"),
            "active_minutes": delta("active_minutes"),
            "sleep_hours": delta("sleep_hours"),
        },
        "series": series,
    }

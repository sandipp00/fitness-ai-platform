from dataclasses import dataclass
from statistics import mean
from typing import Sequence


@dataclass(frozen=True)
class DailyMetric:
    steps: float
    active_minutes: float
    sleep_hours: float


def _avg(values):
    values = [float(v) for v in values if v is not None]
    return mean(values) if values else 0.0


def build_features(series: Sequence[dict]) -> dict:
    rows = list(series)
    if not rows:
        return {
            "avg_steps_7d": 0.0,
            "avg_active_7d": 0.0,
            "avg_sleep_7d": 0.0,
            "steps_consistency": 0.0,
            "active_consistency": 0.0,
            "sleep_consistency": 0.0,
            "activity_trend": 0.0,
            "sleep_trend": 0.0,
            "adherence_ratio": 0.0,
        }

    recent = rows[-7:]
    prior = rows[-14:-7]

    def values(key, data):
        return [float(x.get(key, 0) or 0) for x in data]

    def consistency(key):
        vals = values(key, recent)
        if not vals:
            return 0.0
        avg = _avg(vals)
        if avg == 0:
            return 0.0
        return max(0.0, min(1.0, 1.0 - (max(vals) - min(vals)) / max(avg, 1)))

    def trend(key):
        a = _avg(values(key, recent))
        b = _avg(values(key, prior))
        if not prior:
            return 0.0
        return (a - b) / max(abs(b), 1.0)

    active = values("active_minutes", recent)
    adherence = sum(1 for x in active if x >= 20) / max(len(active), 1)

    return {
        "avg_steps_7d": round(_avg(values("steps", recent)), 3),
        "avg_active_7d": round(_avg(active), 3),
        "avg_sleep_7d": round(_avg(values("sleep_hours", recent)), 3),
        "steps_consistency": round(consistency("steps"), 3),
        "active_consistency": round(consistency("active_minutes"), 3),
        "sleep_consistency": round(consistency("sleep_hours"), 3),
        "activity_trend": round(trend("active_minutes"), 3),
        "sleep_trend": round(trend("sleep_hours"), 3),
        "adherence_ratio": round(adherence, 3),
    }


FEATURE_NAMES = [
    "avg_steps_7d",
    "avg_active_7d",
    "avg_sleep_7d",
    "steps_consistency",
    "active_consistency",
    "sleep_consistency",
    "activity_trend",
    "sleep_trend",
    "adherence_ratio",
]

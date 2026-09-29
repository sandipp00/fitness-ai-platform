from datetime import date, timedelta


def build_adaptive_plan(
    *,
    goal: str,
    level: str,
    avg_steps: float,
    avg_active_minutes: float,
    avg_sleep_hours: float,
    recovery_score: int,
    ml_level: str | None = None,
    ml_explanation: str | None = None,
) -> dict:
    goal = goal or "general fitness"
    level = level or "beginner"
    if ml_level in {"recovery", "foundation", "progressive"}:
        strategy_override = ml_level
    else:
        strategy_override = None

    if strategy_override == "recovery" or recovery_score < 50 or (avg_sleep_hours and avg_sleep_hours < 6.5):
        intensity = "recovery"
        sessions = [
            {"day": "Day 1", "type": "Walking", "minutes": 20, "intensity": "easy"},
            {"day": "Day 2", "type": "Mobility", "minutes": 15, "intensity": "easy"},
            {"day": "Day 3", "type": "Rest", "minutes": 0, "intensity": "rest"},
            {"day": "Day 4", "type": "Walking", "minutes": 25, "intensity": "easy"},
            {"day": "Day 5", "type": "Mobility", "minutes": 15, "intensity": "easy"},
            {"day": "Day 6", "type": "Optional easy activity", "minutes": 20, "intensity": "easy"},
            {"day": "Day 7", "type": "Rest", "minutes": 0, "intensity": "rest"},
        ]
    elif strategy_override == "foundation" or avg_active_minutes < 30:
        intensity = "foundation"
        sessions = [
            {"day": "Day 1", "type": "Full-body strength", "minutes": 25, "intensity": "easy"},
            {"day": "Day 2", "type": "Walk", "minutes": 25, "intensity": "easy"},
            {"day": "Day 3", "type": "Rest", "minutes": 0, "intensity": "rest"},
            {"day": "Day 4", "type": "Full-body strength", "minutes": 25, "intensity": "easy"},
            {"day": "Day 5", "type": "Walk", "minutes": 30, "intensity": "moderate"},
            {"day": "Day 6", "type": "Mobility", "minutes": 15, "intensity": "easy"},
            {"day": "Day 7", "type": "Rest", "minutes": 0, "intensity": "rest"},
        ]
    else:
        intensity = "progressive"
        sessions = [
            {"day": "Day 1", "type": "Strength", "minutes": 40, "intensity": "moderate"},
            {"day": "Day 2", "type": "Cardio", "minutes": 30, "intensity": "moderate"},
            {"day": "Day 3", "type": "Mobility", "minutes": 15, "intensity": "easy"},
            {"day": "Day 4", "type": "Strength", "minutes": 40, "intensity": "moderate"},
            {"day": "Day 5", "type": "Cardio", "minutes": 30, "intensity": "moderate"},
            {"day": "Day 6", "type": "Optional activity", "minutes": 25, "intensity": "easy"},
            {"day": "Day 7", "type": "Rest", "minutes": 0, "intensity": "rest"},
        ]

    return {
        "week_start": date.today().isoformat(),
        "goal": goal,
        "level": level,
        "strategy": intensity,
        "reason": (
            f"Plan adapted from average activity of {avg_active_minutes:.0f} "
            f"active minutes/day, {avg_steps:.0f} steps/day, "
            f"{avg_sleep_hours:.1f} hours sleep, and recovery score "
            f"{recovery_score}/100."
            + (f" ML signal: {ml_explanation}" if ml_explanation else "")
        ),
        "sessions": sessions,
        "safety": (
            "Adjust or stop activity for pain, dizziness, unusual shortness "
            "of breath, or other concerning symptoms and seek appropriate "
            "professional care when needed."
        ),
    }

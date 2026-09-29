from statistics import mean

def clamp(value: float, low=0, high=100):
    return max(low, min(high, round(value, 1)))

def activity_score(steps: int, active_minutes: int) -> float:
    step_score = min(steps / 10000, 1) * 70
    minute_score = min(active_minutes / 60, 1) * 30
    return clamp(step_score + minute_score)

def sleep_score(hours: float, quality: int) -> float:
    duration = max(0, 100 - abs(hours - 8) * 18)
    quality_score = quality / 5 * 100
    return clamp(duration * 0.6 + quality_score * 0.4)

def recovery_score(activity: float, sleep: float) -> float:
    return clamp(activity * 0.35 + sleep * 0.65)

def recommendations(activity: float, sleep: float, goal: str):
    recs = []
    if activity < 50:
        recs.append("Add a short walk or light activity session today.")
    if sleep < 60:
        recs.append("Prioritize a consistent sleep window and recovery today.")
    if goal == "lose_weight":
        recs.append("Keep nutrition consistent with your planned calorie target.")
    elif goal == "gain_muscle":
        recs.append("Prioritize progressive resistance training and adequate protein.")
    else:
        recs.append("Keep building consistency across activity, sleep, and recovery.")
    return recs

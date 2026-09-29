from dataclasses import dataclass


@dataclass(frozen=True)
class Recommendation:
    category: str
    title: str
    message: str
    priority: str


def build_recommendations(
    *,
    steps: int,
    active_minutes: int,
    sleep_hours: float,
    recovery_score: int,
    goal: str,
) -> list[Recommendation]:
    items: list[Recommendation] = []

    if sleep_hours > 0 and sleep_hours < 7:
        items.append(Recommendation(
            "sleep",
            "Protect your sleep",
            "Your latest sleep duration is below 7 hours. Consider a consistent "
            "sleep window and reduce late-day stimulation.",
            "high",
        ))

    if steps < 5000:
        items.append(Recommendation(
            "activity",
            "Add light movement",
            "Your step count is still below 5,000. A short walk can increase "
            "daily movement without requiring a hard workout.",
            "medium",
        ))

    if active_minutes < 30:
        items.append(Recommendation(
            "activity",
            "Build active minutes",
            "You have fewer than 30 active minutes recorded today. Add an easy "
            "walk, mobility session, or short workout if it fits your goal.",
            "medium",
        ))

    if recovery_score < 50 and sleep_hours >= 7:
        items.append(Recommendation(
            "recovery",
            "Keep intensity moderate",
            "Your current recovery score is low despite adequate sleep. Favor "
            "easy movement and recovery work today rather than automatically "
            "increasing training intensity.",
            "high",
        ))

    if not items:
        items.append(Recommendation(
            "consistency",
            "Keep the routine",
            f"Your recent signals are consistent with your {goal} goal. "
            "Focus on maintaining a sustainable routine rather than making "
            "large changes from a single day.",
            "low",
        ))

    return items[:5]

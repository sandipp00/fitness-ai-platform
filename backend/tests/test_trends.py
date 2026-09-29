from app.services.workout_planner import build_adaptive_plan


def test_low_recovery_uses_recovery_plan():
    plan = build_adaptive_plan(
        goal="general fitness",
        level="beginner",
        avg_steps=4000,
        avg_active_minutes=20,
        avg_sleep_hours=6,
        recovery_score=40,
    )
    assert plan["strategy"] == "recovery"


def test_normal_activity_uses_progressive_plan():
    plan = build_adaptive_plan(
        goal="general fitness",
        level="beginner",
        avg_steps=8000,
        avg_active_minutes=45,
        avg_sleep_hours=7.5,
        recovery_score=80,
    )
    assert plan["strategy"] == "progressive"

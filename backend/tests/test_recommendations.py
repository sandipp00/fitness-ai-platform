from app.services.recommendations import build_recommendations


def test_low_sleep_generates_sleep_recommendation():
    items = build_recommendations(
        steps=7000,
        active_minutes=40,
        sleep_hours=5.5,
        recovery_score=70,
        goal="general fitness",
    )
    assert any(item.category == "sleep" for item in items)


def test_low_activity_generates_movement_recommendation():
    items = build_recommendations(
        steps=2500,
        active_minutes=10,
        sleep_hours=8,
        recovery_score=70,
        goal="general fitness",
    )
    assert any(item.category == "activity" for item in items)

from app.services.ml_features import build_features
from app.services.personalization_model import personalization_model


def test_features_are_built_from_history():
    series = [
        {"steps": 6000, "active_minutes": 30, "sleep_hours": 7}
        for _ in range(7)
    ]
    features = build_features(series)
    assert features["avg_steps_7d"] == 6000
    assert features["avg_active_7d"] == 30
    assert features["adherence_ratio"] == 1


def test_personalization_returns_bounded_signal():
    series = [
        {"steps": 7000, "active_minutes": 35, "sleep_hours": 7.5}
        for _ in range(14)
    ]
    result = personalization_model.predict(series)
    assert 0 <= result.readiness <= 100
    assert 0 <= result.adherence_probability <= 100
    assert result.recommended_level in {"recovery", "foundation", "progressive"}

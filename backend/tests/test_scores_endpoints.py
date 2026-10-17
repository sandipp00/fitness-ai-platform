from datetime import date


def _hit_score_endpoints(client, headers):
    r = client.get("/api/ai/recommendations", headers=headers)
    assert r.status_code == 200, r.text
    recovery = r.json()["scores"]["recovery"]
    assert isinstance(recovery, (int, float))

    r = client.post("/api/ai/chat", json={"message": "How should I train today?"}, headers=headers)
    assert r.status_code == 200, r.text

    r = client.get("/api/analytics/workout-plan", headers=headers)
    assert r.status_code == 200, r.text
    return recovery


def test_score_endpoints_without_data(client, new_user):
    _hit_score_endpoints(client, new_user()["headers"])


def test_score_endpoints_with_data(client, new_user):
    headers = new_user()["headers"]
    r = client.post(
        "/api/health-data/sync",
        json={
            "day": date.today().isoformat(),
            "source": "health_connect",
            "activity": {"steps": 8000, "active_minutes": 45},
            "sleep": {"duration_hours": 7.5, "quality": 4},
        },
        headers=headers,
    )
    assert r.status_code == 200, r.text
    assert _hit_score_endpoints(client, headers) > 0

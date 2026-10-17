import uuid
from datetime import date

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def _auth_headers():
    email = f"scores-{uuid.uuid4().hex[:8]}@example.com"
    response = client.post(
        "/api/auth/register", json={"email": email, "password": "password123"}
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _hit_score_endpoints(headers):
    r = client.get("/api/ai/recommendations", headers=headers)
    assert r.status_code == 200, r.text
    recovery = r.json()["scores"]["recovery"]
    assert isinstance(recovery, (int, float))

    r = client.post("/api/ai/chat", json={"message": "How should I train today?"}, headers=headers)
    assert r.status_code == 200, r.text

    r = client.get("/api/analytics/workout-plan", headers=headers)
    assert r.status_code == 200, r.text
    return recovery


def test_score_endpoints_without_data():
    _hit_score_endpoints(_auth_headers())


def test_score_endpoints_with_data():
    headers = _auth_headers()
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
    assert _hit_score_endpoints(headers) > 0

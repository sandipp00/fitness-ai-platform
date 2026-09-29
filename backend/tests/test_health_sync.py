from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_endpoint_requires_auth():
    response = client.post(
        "/api/health-data/sync",
        json={
            "day": "2026-09-30",
            "source": "health_connect",
            "activity": {"steps": 1000},
        },
    )
    assert response.status_code in (401, 403)

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_register_and_profile():
    email = "test@example.com"
    response = client.post("/api/auth/register", json={"email": email, "password": "password123"})
    assert response.status_code in (200, 409)
    token = response.json()["access_token"] if response.status_code == 200 else None
    if token:
        r = client.get("/api/users/me", headers={"Authorization": f"Bearer {token}"})
        assert r.status_code == 200

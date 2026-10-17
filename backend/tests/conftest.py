import uuid

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.security import login_limiter


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture(autouse=True)
def reset_login_limiter():
    login_limiter.clear()
    yield
    login_limiter.clear()


@pytest.fixture
def new_user(client):
    """Register a fresh user; returns a dict with email, password, tokens and headers."""

    def _create():
        email = f"user-{uuid.uuid4().hex[:10]}@example.com"
        password = "password123"
        response = client.post("/api/auth/register", json={"email": email, "password": password})
        assert response.status_code == 200, response.text
        tokens = response.json()
        return {
            "email": email,
            "password": password,
            "tokens": tokens,
            "headers": {"Authorization": f"Bearer {tokens['access_token']}"},
        }

    return _create

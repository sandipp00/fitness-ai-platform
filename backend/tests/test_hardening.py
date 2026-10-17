import os
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

from app.database import SessionLocal
from app.models import Profile, User, WorkoutPlan
from app.services import coach
from app.config import settings

BACKEND_DIR = Path(__file__).resolve().parents[1]


def _sync(client, headers, day, activity=None, sleep=None):
    body = {"day": day, "source": "test"}
    if activity is not None:
        body["activity"] = activity
    if sleep is not None:
        body["sleep"] = sleep
    response = client.post("/api/health-data/sync", json=body, headers=headers)
    assert response.status_code == 200, response.text


def _set_admin(email, value=True):
    with SessionLocal() as db:
        db.query(User).filter(User.email == email).update({"is_admin": value})
        db.commit()


# --- health data -----------------------------------------------------------

def test_sleep_only_sync_keeps_existing_activity(client, new_user):
    user = new_user()
    _sync(client, user["headers"], "2026-01-10", activity={"steps": 9000, "active_minutes": 40})
    _sync(client, user["headers"], "2026-01-10", sleep={"duration_hours": 7.5, "quality": 4})

    rows = client.get("/api/activity", headers=user["headers"]).json()
    assert [(r["day"], r["steps"], r["active_minutes"]) for r in rows] == [("2026-01-10", 9000, 40)]


def test_second_activity_post_for_same_day_updates_instead_of_500(client, new_user):
    user = new_user()
    body = {"day": "2026-01-11", "steps": 1000, "active_minutes": 5, "calories_burned": 50, "distance_km": 1}
    assert client.post("/api/activity", json=body, headers=user["headers"]).status_code == 200
    body["steps"] = 2500
    assert client.post("/api/activity", json=body, headers=user["headers"]).status_code == 200

    rows = client.get("/api/activity", headers=user["headers"]).json()
    assert len(rows) == 1 and rows[0]["steps"] == 2500


def test_dashboard_uses_users_timezone(client, new_user):
    user = new_user()
    tz = "Pacific/Kiritimati"  # UTC+14: usually a different date than the server
    r = client.put("/api/users/me/timezone", json={"timezone": tz}, headers=user["headers"])
    assert r.status_code == 200 and r.json()["timezone"] == tz

    local_today = datetime.now(ZoneInfo(tz)).date().isoformat()
    _sync(client, user["headers"], local_today, activity={"steps": 4321, "active_minutes": 10})

    dashboard = client.get("/api/dashboard", headers=user["headers"]).json()
    assert dashboard["date"] == local_today
    assert dashboard["activity"]["steps"] == 4321


def test_unknown_timezone_is_rejected(client, new_user):
    user = new_user()
    r = client.put("/api/users/me/timezone", json={"timezone": "Mars/Olympus"}, headers=user["headers"])
    assert r.status_code == 422


def test_profile_update_without_timezone_keeps_it(client, new_user):
    user = new_user()
    client.put("/api/users/me/timezone", json={"timezone": "Asia/Kolkata"}, headers=user["headers"])
    r = client.put("/api/users/me", json={"name": "Sam", "goal": "lose_weight"}, headers=user["headers"])
    assert r.status_code == 200
    assert r.json()["timezone"] == "Asia/Kolkata" and r.json()["name"] == "Sam"


def test_workout_plan_is_stored_once_per_week(client, new_user):
    user = new_user()
    first = client.get("/api/analytics/workout-plan", headers=user["headers"])
    second = client.get("/api/analytics/workout-plan", headers=user["headers"])
    assert first.status_code == second.status_code == 200
    assert first.json()["id"] == second.json()["id"]
    with SessionLocal() as db:
        user_id = db.query(User).filter(User.email == user["email"]).one().id
        assert db.query(WorkoutPlan).filter(WorkoutPlan.user_id == user_id).count() == 1


# --- users / account ---------------------------------------------------------

def test_get_me_recovers_when_profile_is_missing(client, new_user):
    user = new_user()
    with SessionLocal() as db:
        user_id = db.query(User).filter(User.email == user["email"]).one().id
        db.query(Profile).filter(Profile.user_id == user_id).delete()
        db.commit()
    r = client.get("/api/users/me", headers=user["headers"])
    assert r.status_code == 200 and r.json()["timezone"] == "UTC"


def test_users_cannot_see_each_others_data(client, new_user):
    alice, bob = new_user(), new_user()
    _sync(client, alice["headers"], "2026-02-01", activity={"steps": 12345}, sleep={"duration_hours": 8, "quality": 5})

    assert client.get("/api/activity", headers=bob["headers"]).json() == []
    export = client.get("/api/users/me/export", headers=bob["headers"]).json()
    assert export["activity"] == [] and export["sleep"] == []
    trends = client.get("/api/analytics/trends", headers=bob["headers"]).json()
    assert all(day["steps"] == 0 for day in trends["series"])


def test_export_contains_my_data(client, new_user):
    user = new_user()
    _sync(client, user["headers"], "2026-02-02", activity={"steps": 777}, sleep={"duration_hours": 6.5, "quality": 3})
    export = client.get("/api/users/me/export", headers=user["headers"]).json()
    assert export["account"]["email"] == user["email"]
    assert export["activity"][0]["steps"] == 777
    assert export["sleep"][0]["duration_hours"] == 6.5
    assert "user_id" not in export["activity"][0]


def test_delete_account_removes_everything(client, new_user):
    user = new_user()
    _sync(client, user["headers"], "2026-02-03", activity={"steps": 100})

    wrong = client.request("DELETE", "/api/users/me", json={"password": "nope-nope"}, headers=user["headers"])
    assert wrong.status_code == 403

    r = client.request("DELETE", "/api/users/me", json={"password": user["password"]}, headers=user["headers"])
    assert r.status_code == 204
    assert client.get("/api/users/me", headers=user["headers"]).status_code == 401
    login = client.post("/api/auth/login", json={"email": user["email"], "password": user["password"]})
    assert login.status_code == 401
    with SessionLocal() as db:
        assert db.query(User).filter(User.email == user["email"]).first() is None


# --- auth ----------------------------------------------------------------

def test_refresh_token_flow(client, new_user):
    user = new_user()
    tokens = user["tokens"]
    assert tokens["refresh_token"] and tokens["expires_in"] > 0

    r = client.post("/api/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert r.status_code == 200
    new_access = r.json()["access_token"]
    assert client.get("/api/users/me", headers={"Authorization": f"Bearer {new_access}"}).status_code == 200

    # Token types are not interchangeable.
    assert client.post("/api/auth/refresh", json={"refresh_token": tokens["access_token"]}).status_code == 401
    as_access = {"Authorization": f"Bearer {tokens['refresh_token']}"}
    assert client.get("/api/users/me", headers=as_access).status_code == 401


def test_logout_all_revokes_existing_tokens(client, new_user):
    user = new_user()
    assert client.post("/api/auth/logout-all", headers=user["headers"]).status_code == 204
    assert client.get("/api/users/me", headers=user["headers"]).status_code == 401
    r = client.post("/api/auth/refresh", json={"refresh_token": user["tokens"]["refresh_token"]})
    assert r.status_code == 401


def test_login_is_rate_limited(client, new_user):
    user = new_user()
    bad = {"email": user["email"], "password": "wrong-password"}
    for _ in range(settings.login_max_attempts):
        assert client.post("/api/auth/login", json=bad).status_code == 401
    blocked = client.post("/api/auth/login", json={"email": user["email"], "password": user["password"]})
    assert blocked.status_code == 429
    assert int(blocked.headers["Retry-After"]) > 0


def test_password_longer_than_bcrypt_limit_is_rejected(client):
    r = client.post("/api/auth/register", json={"email": "long@example.com", "password": "é" * 40})
    assert r.status_code == 422


def test_production_refuses_default_secret(tmp_path):
    env = {k: v for k, v in os.environ.items() if k not in {"SECRET_KEY", "ENVIRONMENT"}}
    env["PYTHONPATH"] = str(BACKEND_DIR)
    # Run outside backend/ so no .env file is picked up.
    result = subprocess.run(
        [sys.executable, "-c", "import app.config"],
        cwd=tmp_path, env=env, capture_output=True, text=True,
    )
    assert result.returncode != 0
    assert "SECRET_KEY" in result.stderr


# --- resources & AI ------------------------------------------------------

RESOURCE = {
    "title": "Walking basics",
    "category": "activity",
    "source": "Kinetiq",
    "url": "https://example.org/walking",
    "summary": "Walk more.",
}


def test_only_admins_can_publish_resources(client, new_user):
    user = new_user()
    assert client.post("/api/resources", json=RESOURCE, headers=user["headers"]).status_code == 403

    _set_admin(user["email"])
    r = client.post("/api/resources", json=RESOURCE, headers=user["headers"])
    assert r.status_code == 200, r.text
    assert r.json()["url"] == RESOURCE["url"]


def test_chat_input_is_validated(client, new_user):
    user = new_user()
    too_long = client.post("/api/ai/chat", json={"message": "x" * 2001}, headers=user["headers"])
    assert too_long.status_code == 422
    missing = client.post("/api/ai/chat", json={}, headers=user["headers"])
    assert missing.status_code == 422


def test_chat_falls_back_when_openai_fails(client, new_user, monkeypatch):
    user = new_user()

    class BrokenOpenAI:
        def __init__(self, **kwargs):
            raise TimeoutError("provider down")

    monkeypatch.setattr(settings, "openai_api_key", "test-key")
    monkeypatch.setattr(coach, "OpenAI", BrokenOpenAI)
    r = client.post("/api/ai/chat", json={"message": "How should I train?"}, headers=user["headers"])
    assert r.status_code == 200
    assert r.json()["mode"] == "grounded_fallback"


def test_responses_carry_request_id(client):
    r = client.get("/health", headers={"X-Request-ID": "abc123"})
    assert r.headers["X-Request-ID"] == "abc123"
    assert client.get("/health").headers["X-Request-ID"]

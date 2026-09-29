# Fitness AI Platform

A production-oriented fitness, nutrition, wellness and recovery platform with a Flutter client, FastAPI backend, health-data synchronization, analytics, adaptive workout planning, RAG-grounded AI coaching, and ML personalization.

## Current stage

**Advanced MVP / pre-production prototype.** The core product loop is implemented; production deployment, real-device validation, migrations/observability, and ML evaluation remain before a public launch.

## Architecture

Flutter → Health Connect / HealthKit → background sync → FastAPI → PostgreSQL → analytics + ML personalization → adaptive workout planner → AI Coach + trusted-resource RAG.

## Run backend locally

```bash
cd backend
python -m venv .venv
# Windows PowerShell: .venv\\Scripts\\Activate.ps1
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

API docs: `http://127.0.0.1:8000/docs`

## Run with Docker

```bash
docker compose up --build
```

## Run Flutter

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For a physical phone, replace the URL with the computer's LAN IP. See `mobile/README.md`.

## Health data

The mobile app uses the `health` Flutter plugin for Google Health Connect on Android and Apple HealthKit on iOS. Current synchronization includes steps, active energy, distance, exercise time and sleep. Health Connect permissions and native setup are documented in `docs/health-connect-setup.md`.

## AI safety

The AI coach is designed for general wellness education and planning. It must not diagnose conditions, prescribe medication, or replace qualified medical care. The personalization model is an engineering prototype and is not clinically validated.

## Deployment

A Render Blueprint is included as `render.yaml`. The production container runs database migrations before serving traffic. Set `CORS_ORIGINS` and `OPENAI_API_KEY` as deployment secrets. The backend exposes `/health` for liveness and `/health/ready` for database readiness.

See `docs/production-checklist.md` before public release.


## Release verification

```bash
cd backend
python scripts/predeploy_check.py
python -m compileall -q app tests scripts
pytest -q
```

The full test suite must be run in an environment with the pinned dependencies installed.

# Deployment

## Render

The repository contains `render.yaml` for a Docker-based API and managed PostgreSQL database.

1. Push the repository to GitHub.
2. In Render, create a Blueprint from the repository.
3. Set `CORS_ORIGINS` to the exact origins that need browser access. A native Flutter mobile app generally does not require CORS, but web builds do.
4. Add `OPENAI_API_KEY` only if the hosted AI Coach should use OpenAI. Keep it server-side.
5. Wait for `/health/ready` to become healthy.
6. Use the deployed API URL as the Flutter `API_BASE_URL`.

The container runs `alembic upgrade head` before starting Uvicorn.

## Local production-like Docker

```bash
docker compose up --build
```

The local Compose service intentionally keeps `ENVIRONMENT=development`, so `create_all()` is available for convenience. A production deployment uses Alembic migrations.

## Flutter release

```bash
cd mobile
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-API-DOMAIN
```

Before release, generate native folders and apply Health Connect / HealthKit configuration from `docs/health-connect-setup.md`.

## Pre-deployment verification

From `backend/` run:

```bash
python scripts/predeploy_check.py
python -m compileall -q app tests scripts
pytest -q
```

The last command requires the dependencies in `requirements.txt` to be installed. The deployment image runs `alembic upgrade head` before Uvicorn starts.

## GitHub

The current project is packaged and ready to push to a new repository. The GitHub integration available in this workspace can update existing repositories, but repository creation is not exposed, so create the new repository first and then push the project contents. Do not commit `.env`, API keys, signing keys, or production database credentials.

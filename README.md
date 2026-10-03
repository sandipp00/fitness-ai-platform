# Fitness AI Platform

A production-oriented **fitness, nutrition, wellness and recovery platform** with a Flutter mobile client, FastAPI backend, health-data synchronization, analytics, adaptive workout planning, RAG-grounded AI coaching, and ML personalization.

## Current stage

**Advanced MVP / pre-production prototype.**

The core product loop is implemented and the backend is deployed. The project is still being hardened before a public release: real-device validation, production observability, database/migration verification, security review, and ML evaluation remain part of the release checklist.

## Product architecture

The platform follows a mobile-first architecture:

```text
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                     │
│                                                             │
│  Home │ Health │ Stats │ Coach │ Profile                  │
│                                                             │
│  Recommendations │ Workout Plan │ Personalization         │
└──────────────────────────┬──────────────────────────────────┘
                           │ REST API
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                       FastAPI Backend                       │
│                                                             │
│ Auth │ Users │ Activity │ Workouts │ Health │ Dashboard    │
│ Resources │ AI Coach │ Analytics │ Personalization         │
└───────────────┬───────────────────────┬─────────────────────┘
                │                       │
                ▼                       ▼
        PostgreSQL / SQLite       AI + Analytics Layer
                                ┌───────────────────────────┐
                                │ RAG resource retrieval     │
                                │ AI coaching                │
                                │ Recommendations            │
                                │ Trend analytics            │
                                │ ML personalization         │
                                │ Adaptive workout planning  │
                                └───────────────────────────┘
```

### Health-data flow

```text
Health Connect / HealthKit
          │
          ▼
Flutter health service
          │
          ▼
Background / manual sync
          │
          ▼
FastAPI health endpoints
          │
          ▼
Persisted health/activity data
          │
          ▼
Dashboard + trends + personalization
          │
          ▼
Recommendations + workout planning + AI Coach
```

## Mobile UI architecture

The Flutter app uses a bottom-navigation structure for the primary product areas:

| Navigation | Responsibility |
|---|---|
| **Home** | Recovery overview, today's metrics, workout summary and recommendations |
| **Health** | Health-data permissions, synchronization and activity/health metrics |
| **Stats** | Progress, trends and historical analytics |
| **Coach** | AI wellness coaching and conversational guidance |
| **Profile** | Personalization settings and user profile data |

Secondary workflows are opened from the main experience:

- **Recommendations** — personalized fitness recommendations.
- **Workout Plan** — adaptive workout planning.
- **Personalization** — profile and personalization controls.

The current mobile code is intentionally kept close to the existing repository structure rather than introducing unnecessary architectural layers:

```text
mobile/
└── lib/
    ├── main.dart
    ├── screens/
    │   ├── auth_screen.dart
    │   ├── dashboard_screen.dart
    │   ├── health_screen.dart
    │   ├── recommendations_screen.dart
    │   ├── coach_screen.dart
    │   ├── progress_screen.dart
    │   ├── workout_plan_screen.dart
    │   └── personalization_screen.dart
    ├── services/
    │   ├── api_client.dart
    │   ├── session.dart
    │   ├── health_connect_service.dart
    │   ├── health_sync_service.dart
    │   └── background_sync.dart
    ├── models/
    │   └── dashboard_data.dart
    └── widgets/
        └── metric_card.dart
```

The UI direction uses a soft wellness-focused visual system with rounded cards, teal/mint surfaces, recovery-focused hero content, metric cards and persistent bottom navigation.

## Backend API

The FastAPI backend exposes the core product domains:

| Area | Endpoints |
|---|---|
| Authentication | `/api/auth/register`, `/api/auth/login` |
| Users | `/api/users/me` |
| Activity | `/api/activity` |
| Workouts | `/api/workouts` |
| Health data | `/api/health-data/sleep`, `/api/health-data/weight`, `/api/health-data/water`, `/api/health-data/sync` |
| Dashboard | `/api/dashboard` |
| Resources | `/api/resources` |
| AI Coach | `/api/ai/chat`, `/api/ai/recommendations` |
| Analytics | `/api/analytics/trends`, `/api/analytics/workout-plan`, `/api/analytics/progress`, `/api/analytics/personalization` |

Health endpoints:

- `GET /health` — liveness check.
- `GET /health/ready` — database readiness check.

## Health data

The mobile client uses the `health` Flutter plugin for:

- Google Health Connect on Android.
- Apple HealthKit on iOS.

Current synchronization covers steps, active energy, distance, exercise time and sleep. Native permissions and setup are documented in [`docs/health-connect-setup.md`](docs/health-connect-setup.md).

Background synchronization is supported through the mobile sync services. Production behavior should still be validated on physical Android and iOS devices.

## AI and personalization

The platform combines several AI/data components:

- **AI Coach** — conversational wellness guidance.
- **RAG** — retrieval from trusted fitness/wellness resources before generating grounded guidance.
- **Recommendations** — personalized fitness recommendations.
- **Trend analytics** — historical activity and progress analysis.
- **ML personalization** — engineering-prototype personalization features.
- **Adaptive workout planner** — workout planning based on user context and available activity data.

The personalization model is an engineering prototype and is **not clinically validated**.

### AI safety

The AI coach is designed for general wellness education and planning. It must not diagnose medical conditions, prescribe medication, or replace qualified medical care.

## Database

### Local development

The backend can run with its local SQLite fallback:

```text
SQLite → local development
```

### Production

The Render deployment is configured to use PostgreSQL through `DATABASE_URL`:

```text
Flutter
   │
   ▼
FastAPI
   │
   ▼
PostgreSQL
```

Database migrations are managed with Alembic.

## Run the backend locally

```bash
cd backend
python -m venv .venv

# Windows PowerShell
.venv\\Scripts\\Activate.ps1

# macOS/Linux
# source .venv/bin/activate

pip install -r requirements.txt
uvicorn app.main:app --reload
```

Local API documentation:

```text
http://127.0.0.1:8000/docs
```

## Run with Docker

```bash
docker compose up --build
```

The production backend container runs the Alembic migrations before starting Uvicorn.

## Run the Flutter app

### Android emulator

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### Physical Android device

Replace the API URL with the computer's LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
```

The backend must be reachable from the phone.

See [`mobile/README.md`](mobile/README.md) for mobile-specific setup.

## Production deployment

A Render Blueprint is included in [`render.yaml`](render.yaml).

The deployment configuration includes:

- Docker-based FastAPI service.
- PostgreSQL database.
- Alembic migrations at container startup.
- Generated `SECRET_KEY`.
- Production environment configuration.
- Configurable CORS origins.
- Server-side OpenAI API key configuration.
- Database readiness health check.

The currently deployed backend exposes:

```text
https://fitness-ai-platform-0ym8.onrender.com
```

Health check:

```text
https://fitness-ai-platform-0ym8.onrender.com/health
```

Do not put `OPENAI_API_KEY` in the Flutter application. AI provider credentials belong on the backend.

## Repository structure

```text
fitness-ai-platform/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   ├── services/
│   │   ├── main.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── models.py
│   │   └── schemas.py
│   ├── alembic/
│   ├── scripts/
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
│
├── mobile/
│   ├── lib/
│   ├── android/
│   ├── pubspec.yaml
│   └── README.md
│
├── docs/
│   ├── architecture.md
│   ├── roadmap.md
│   ├── clean-architecture.md
│   ├── live-data-flow.md
│   ├── health-connect-setup.md
│   ├── privacy-and-health-data.md
│   ├── ai-coach.md
│   ├── personalization.md
│   ├── ml-personalization.md
│   └── production-checklist.md
│
├── .github/workflows/
├── docker-compose.yml
├── render.yaml
└── README.md
```

## Release verification

Run the following before considering a release candidate:

```bash
cd backend

python scripts/predeploy_check.py
python -m compileall -q app tests scripts
pytest -q
```

The full test suite must be run in an environment with the project's pinned dependencies installed.

## Production checklist

Before public release, verify:

- [ ] Real Android device validation.
- [ ] iOS device validation.
- [ ] Health Connect / HealthKit permissions.
- [ ] Background sync behavior.
- [ ] PostgreSQL migrations.
- [ ] Authentication and authorization.
- [ ] CORS configuration.
- [ ] Secret management.
- [ ] API error handling.
- [ ] Logging and observability.
- [ ] Rate limiting and abuse protection.
- [ ] AI/RAG evaluation.
- [ ] ML personalization evaluation.
- [ ] Privacy and health-data handling.
- [ ] Backup and recovery strategy.

See [`docs/production-checklist.md`](docs/production-checklist.md) for the detailed release checklist.

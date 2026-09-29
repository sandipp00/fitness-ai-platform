from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from .database import Base, engine
from .config import settings
from .api import auth, users, activity, workouts, health, dashboard, resources, ai, analytics

# Keep create_all for local development. Production deployments should run the
# migration command before starting the API.
if settings.environment != "production":
    Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Fitness AI Platform API",
    version="0.3.0",
    description="Fitness tracking, analytics, recommendations and AI-ready health platform.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(activity.router, prefix="/api/activity", tags=["activity"])
app.include_router(workouts.router, prefix="/api/workouts", tags=["workouts"])
app.include_router(health.router, prefix="/api/health-data", tags=["health-data"])
app.include_router(dashboard.router, prefix="/api/dashboard", tags=["dashboard"])
app.include_router(resources.router, prefix="/api/resources", tags=["resources"])
app.include_router(ai.router, prefix="/api/ai", tags=["ai"])
app.include_router(analytics.router, prefix="/api/analytics", tags=["analytics"])


@app.get("/health")
def health_check():
    return {"status": "ok", "service": "fitness-ai-platform", "version": app.version}


@app.get("/health/ready")
def readiness_check():
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))
    return {"status": "ready", "database": "ok"}

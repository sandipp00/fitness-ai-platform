"""Initialize the database for local/dev environments.

Production deployments should use a migration tool and run migrations before
starting the API. This script is intentionally safe for a fresh database.
"""
from app.database import Base, engine
import app.models  # noqa: F401

Base.metadata.create_all(bind=engine)
print("Database schema initialized.")

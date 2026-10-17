from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

DEV_SECRET_KEY = "dev-only-change-me"


class Settings(BaseSettings):
    secret_key: str = Field(default=DEV_SECRET_KEY, min_length=16)
    database_url: str = "sqlite:///./fitness.db"
    openai_api_key: str | None = None
    openai_model: str = "gpt-5.6-luna"
    openai_timeout_seconds: float = Field(default=20, gt=0, le=120)
    access_token_expire_minutes: int = Field(default=30, ge=5, le=1440)
    refresh_token_expire_days: int = Field(default=30, ge=1, le=365)
    login_max_attempts: int = Field(default=10, ge=1)
    login_window_seconds: int = Field(default=900, ge=1)
    cors_origins: str = ""
    # Secure by default: an unset ENVIRONMENT is treated as production, so a
    # deploy that forgets it can never run with the development secret.
    environment: str = "production"
    log_level: str = "INFO"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore", case_sensitive=False)

    @field_validator("environment")
    @classmethod
    def normalize_environment(cls, value: str) -> str:
        value = value.strip().lower()
        allowed = {"development", "test", "production"}
        if value not in allowed:
            raise ValueError(f"environment must be one of: {sorted(allowed)}")
        return value

    @property
    def cors_origin_list(self) -> list[str]:
        return [item.strip() for item in self.cors_origins.split(",") if item.strip()]


settings = Settings()

if settings.environment == "production" and (
    settings.secret_key == DEV_SECRET_KEY or len(settings.secret_key) < 32
):
    raise ValueError(
        "SECRET_KEY must be a random value of at least 32 characters. "
        "For local development set ENVIRONMENT=development."
    )

if settings.environment == "production" and any(
    origin.startswith("http://localhost") or origin == "*"
    for origin in settings.cors_origin_list
):
    raise ValueError("Production CORS_ORIGINS must contain only explicit trusted origins.")

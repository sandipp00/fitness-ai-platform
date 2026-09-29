from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    secret_key: str = Field(default="dev-only-change-me", min_length=16)
    database_url: str = "sqlite:///./fitness.db"
    openai_api_key: str | None = None
    openai_model: str = "gpt-5.6-luna"
    access_token_expire_minutes: int = Field(default=60, ge=5, le=1440)
    cors_origins: str = "http://localhost:3000,http://localhost:8080"
    environment: str = "development"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore", case_sensitive=False)

    @field_validator("environment")
    @classmethod
    def normalize_environment(cls, value: str) -> str:
        value = value.strip().lower()
        allowed = {"development", "test", "production"}
        if value not in allowed:
            raise ValueError(f"environment must be one of: {sorted(allowed)}")
        return value

    @field_validator("secret_key")
    @classmethod
    def validate_secret_key(cls, value: str) -> str:
        if value == "dev-only-change-me" and cls.model_fields.get("environment") is not None:
            # The production-specific guard below runs after settings construction.
            return value
        return value

    @property
    def cors_origin_list(self) -> list[str]:
        return [item.strip() for item in self.cors_origins.split(",") if item.strip()]


settings = Settings()

if settings.environment == "production" and (
    settings.secret_key == "dev-only-change-me" or len(settings.secret_key) < 32
):
    raise ValueError("Production SECRET_KEY must be a random value of at least 32 characters.")

if settings.environment == "production" and any(
    origin.strip() in {"*", "http://localhost:3000", "http://localhost:8080"}
    for origin in settings.cors_origin_list
):
    raise ValueError("Production CORS_ORIGINS must contain only explicit trusted origins.")

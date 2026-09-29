from datetime import date
from typing import Any
from pydantic import BaseModel, EmailStr, Field, ConfigDict, HttpUrl


class RegisterIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class LoginIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


class ProfileIn(BaseModel):
    name: str = Field(default="User", min_length=1, max_length=120)
    age: int | None = Field(default=None, ge=13, le=120)
    height_cm: float | None = Field(default=None, gt=0, le=250)
    weight_kg: float | None = Field(default=None, gt=0, le=500)
    goal: str = Field(default="improve_fitness", min_length=1, max_length=80)
    activity_level: str = Field(default="moderate", min_length=1, max_length=40)


class ProfileOut(ProfileIn):
    model_config = ConfigDict(from_attributes=True)
    user_id: int


class ActivityIn(BaseModel):
    day: date
    steps: int = Field(ge=0, le=200000)
    active_minutes: int = Field(ge=0, le=1440)
    calories_burned: float = Field(ge=0, le=50000)
    distance_km: float = Field(ge=0, le=1000)


class WorkoutIn(BaseModel):
    day: date
    name: str = Field(min_length=1, max_length=120)
    duration_minutes: int = Field(ge=0, le=1440)
    calories_burned: float = Field(ge=0, le=50000)
    notes: str | None = Field(default=None, max_length=2000)


class SleepIn(BaseModel):
    day: date
    duration_hours: float = Field(ge=0, le=24)
    quality: int = Field(ge=1, le=5)


class WeightIn(BaseModel):
    day: date
    weight_kg: float = Field(gt=0, le=500)


class WaterIn(BaseModel):
    day: date
    liters: float = Field(ge=0, le=20)


class ResourceIn(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    category: str = Field(min_length=1, max_length=80)
    source: str = Field(min_length=1, max_length=255)
    url: HttpUrl
    summary: str = Field(min_length=1, max_length=5000)


class ChatIn(BaseModel):
    message: str = Field(min_length=1, max_length=2000)


class ActivitySyncIn(BaseModel):
    steps: int = Field(default=0, ge=0, le=200000)
    active_minutes: int = Field(default=0, ge=0, le=1440)
    calories_burned: float = Field(default=0, ge=0, le=50000)
    distance_km: float = Field(default=0, ge=0, le=1000)


class SleepSyncIn(BaseModel):
    duration_hours: float = Field(default=0, ge=0, le=24)
    quality: int = Field(default=3, ge=1, le=5)


class HealthSyncIn(BaseModel):
    day: date
    source: str = Field(default="unknown", min_length=1, max_length=80)
    activity: ActivitySyncIn = Field(default_factory=ActivitySyncIn)
    sleep: SleepSyncIn = Field(default_factory=SleepSyncIn)

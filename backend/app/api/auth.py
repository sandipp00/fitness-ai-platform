from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from ..config import settings
from ..database import get_db
from ..deps import get_current_user
from ..models import User, Profile
from ..schemas import RegisterIn, LoginIn, RefreshIn, TokenOut
from ..security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    login_limiter,
)

router = APIRouter()


def _tokens_for(user: User) -> TokenOut:
    subject = str(user.id)
    return TokenOut(
        access_token=create_access_token(subject, user.token_version),
        refresh_token=create_refresh_token(subject, user.token_version),
        expires_in=settings.access_token_expire_minutes * 60,
    )


@router.post("/register", response_model=TokenOut)
def register(payload: RegisterIn, db: Session = Depends(get_db)):
    email = payload.email.lower()
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(409, "Email already registered")
    user = User(email=email, password_hash=hash_password(payload.password))
    db.add(user)
    try:
        db.flush()
        db.add(Profile(user_id=user.id))
        db.commit()
    except IntegrityError:
        # A concurrent registration with the same email won the race.
        db.rollback()
        raise HTTPException(409, "Email already registered")
    return _tokens_for(user)


@router.post("/login", response_model=TokenOut)
def login(payload: LoginIn, request: Request, db: Session = Depends(get_db)):
    email = payload.email.lower()
    keys = (f"email:{email}", f"ip:{request.client.host if request.client else 'unknown'}")
    retry_after = login_limiter.retry_after(*keys)
    if retry_after:
        raise HTTPException(
            429,
            "Too many failed login attempts. Try again later.",
            headers={"Retry-After": str(retry_after)},
        )

    user = db.query(User).filter(User.email == email).first()
    if not user or not verify_password(payload.password, user.password_hash):
        login_limiter.record_failure(*keys)
        raise HTTPException(401, "Invalid email or password")
    login_limiter.reset(keys[0])
    return _tokens_for(user)


@router.post("/refresh", response_model=TokenOut)
def refresh(payload: RefreshIn, db: Session = Depends(get_db)):
    try:
        subject, version = decode_token(payload.refresh_token, expected_type="refresh")
        user = db.get(User, int(subject))
    except (ValueError, TypeError):
        user = None
        version = None
    if not user or user.token_version != version:
        raise HTTPException(401, "Invalid refresh token")
    return _tokens_for(user)


@router.post("/logout-all", status_code=204)
def logout_all(user=Depends(get_current_user), db: Session = Depends(get_db)):
    """Revoke every access and refresh token issued to this account."""
    user.token_version += 1
    db.commit()

import threading
import time
from collections import defaultdict, deque
from datetime import datetime, timedelta, timezone

import bcrypt
from jose import jwt, JWTError

from .config import settings

ALGORITHM = "HS256"
# bcrypt only uses the first 72 bytes. Registration rejects longer passwords;
# truncating here keeps hashes made by the previous passlib setup verifiable.
BCRYPT_MAX_BYTES = 72


def _password_bytes(password: str) -> bytes:
    return password.encode("utf-8")[:BCRYPT_MAX_BYTES]


def hash_password(password: str) -> str:
    return bcrypt.hashpw(_password_bytes(password), bcrypt.gensalt()).decode("ascii")


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(_password_bytes(password), password_hash.encode("ascii"))
    except ValueError:
        return False


def _create_token(subject: str, token_type: str, version: int, expires_delta: timedelta) -> str:
    expires = datetime.now(timezone.utc) + expires_delta
    claims = {"sub": subject, "type": token_type, "ver": version, "exp": expires}
    return jwt.encode(claims, settings.secret_key, algorithm=ALGORITHM)


def create_access_token(subject: str, version: int = 0) -> str:
    return _create_token(
        subject, "access", version, timedelta(minutes=settings.access_token_expire_minutes)
    )


def create_refresh_token(subject: str, version: int = 0) -> str:
    return _create_token(
        subject, "refresh", version, timedelta(days=settings.refresh_token_expire_days)
    )


def decode_token(token: str, expected_type: str = "access") -> tuple[str, int]:
    """Return (subject, token_version) or raise ValueError."""
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])
    except JWTError as exc:
        raise ValueError("Invalid token") from exc
    subject = payload.get("sub")
    # Tokens issued before refresh support carry no type and act as access tokens.
    if not subject or payload.get("type", "access") != expected_type:
        raise ValueError("Invalid token")
    return subject, int(payload.get("ver", 0))


class LoginRateLimiter:
    """In-process sliding-window limiter for failed logins.

    Keys are tracked per email and per client IP. This is per worker process;
    run a single API instance or move this to Redis when scaling out.
    """

    def __init__(self):
        self._failures: dict[str, deque] = defaultdict(deque)
        self._lock = threading.Lock()

    def _prune(self, key: str, now: float):
        window = self._failures[key]
        while window and now - window[0] > settings.login_window_seconds:
            window.popleft()

    def retry_after(self, *keys: str) -> int:
        now = time.monotonic()
        with self._lock:
            waits = []
            for key in keys:
                self._prune(key, now)
                window = self._failures[key]
                if len(window) >= settings.login_max_attempts:
                    waits.append(int(settings.login_window_seconds - (now - window[0])) + 1)
            return max(waits, default=0)

    def record_failure(self, *keys: str):
        now = time.monotonic()
        with self._lock:
            for key in keys:
                self._failures[key].append(now)

    def reset(self, *keys: str):
        with self._lock:
            for key in keys:
                self._failures.pop(key, None)

    def clear(self):
        with self._lock:
            self._failures.clear()


login_limiter = LoginRateLimiter()

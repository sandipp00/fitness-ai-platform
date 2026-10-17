from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


def is_valid_timezone(name: str) -> bool:
    try:
        ZoneInfo(name)
        return True
    except (ZoneInfoNotFoundError, ValueError):
        return False


def user_today(user) -> date:
    """Today's date in the user's own timezone (server runs in UTC)."""
    name = user.profile.timezone if user.profile and user.profile.timezone else "UTC"
    try:
        return datetime.now(ZoneInfo(name)).date()
    except (ZoneInfoNotFoundError, ValueError):
        return datetime.now(ZoneInfo("UTC")).date()


def week_start(day: date) -> date:
    return day - timedelta(days=day.weekday())

"""Grant or revoke admin rights (needed to publish shared resources).

Usage: python -m scripts.make_admin user@example.com [--revoke]
"""
import sys

from app.database import SessionLocal
from app.models import User


def main(argv: list[str]) -> int:
    if not argv or argv[0].startswith("-"):
        print(__doc__)
        return 2
    email = argv[0].lower()
    revoke = "--revoke" in argv[1:]
    with SessionLocal() as db:
        user = db.query(User).filter(User.email == email).first()
        if user is None:
            print(f"No user with email {email}")
            return 1
        user.is_admin = not revoke
        db.commit()
    print(f"{email} is_admin={not revoke}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

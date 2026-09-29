"""Static pre-deployment checks that do not require network access."""
from pathlib import Path
import ast

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app"

for path in APP.rglob("*.py"):
    ast.parse(path.read_text(encoding="utf-8"), filename=str(path))

required = [
    ROOT / "alembic.ini",
    ROOT / "alembic" / "env.py",
    ROOT / "alembic" / "versions" / "0001_initial.py",
    ROOT / "Dockerfile",
    ROOT / "requirements.txt",
]
missing = [str(p.relative_to(ROOT)) for p in required if not p.exists()]
if missing:
    raise SystemExit(f"Missing deployment files: {missing}")

print("Pre-deployment static checks passed.")

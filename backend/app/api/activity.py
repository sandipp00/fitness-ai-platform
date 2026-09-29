from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..database import get_db
from ..deps import get_current_user
from ..models import Activity
from ..schemas import ActivityIn

router = APIRouter()

@router.post("")
def add_activity(payload: ActivityIn, user=Depends(get_current_user), db: Session = Depends(get_db)):
    row = Activity(user_id=user.id, **payload.model_dump())
    db.add(row); db.commit(); db.refresh(row)
    return {"id": row.id, **payload.model_dump()}

@router.get("")
def list_activity(user=Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(Activity).filter(Activity.user_id == user.id).order_by(Activity.day.desc()).limit(30).all()

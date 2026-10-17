from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..database import get_db
from ..deps import get_current_user, require_admin
from ..models import Resource
from ..schemas import ResourceIn

router = APIRouter()

@router.post("")
def add_resource(payload: ResourceIn, user=Depends(require_admin), db: Session = Depends(get_db)):
    # Resources are shown to every user, so only admins may publish them.
    values = payload.model_dump()
    values["url"] = str(values["url"])
    row = Resource(**values); db.add(row); db.commit(); db.refresh(row)
    return row

@router.get("")
def list_resources(category: str | None = None, user=Depends(get_current_user), db: Session = Depends(get_db)):
    query = db.query(Resource)
    if category:
        query = query.filter(Resource.category == category)
    return query.order_by(Resource.id.desc()).limit(100).all()

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..database import get_db
from ..deps import get_current_user
from ..models import Profile
from ..schemas import ProfileIn, ProfileOut

router = APIRouter()

@router.get("/me", response_model=ProfileOut)
def get_profile(user=Depends(get_current_user), db: Session = Depends(get_db)):
    profile = user.profile
    return ProfileOut(
        user_id=user.id,
        name=profile.name,
        age=profile.age,
        height_cm=profile.height_cm,
        weight_kg=profile.weight_kg,
        goal=profile.goal,
        activity_level=profile.activity_level,
    )

@router.put("/me", response_model=ProfileOut)
def update_profile(payload: ProfileIn, user=Depends(get_current_user), db: Session = Depends(get_db)):
    profile = user.profile or Profile(user_id=user.id)
    for key, value in payload.model_dump().items():
        setattr(profile, key, value)
    db.add(profile)
    db.commit()
    return ProfileOut(user_id=user.id, **payload.model_dump())

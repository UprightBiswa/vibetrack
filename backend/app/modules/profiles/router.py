from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.core.security import CurrentUser, get_current_user


class ProfileResponse(BaseModel):
    user_id: str
    email: str | None
    username: str | None
    home_city: str | None
    aura_points: int


router = APIRouter()


@router.get('/me', response_model=ProfileResponse)
async def get_my_profile(user: CurrentUser = Depends(get_current_user)) -> ProfileResponse:
    return ProfileResponse(
        user_id=user.user_id,
        email=user.email,
        username=None,
        home_city=None,
        aura_points=0,
    )

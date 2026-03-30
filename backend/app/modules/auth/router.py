from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.core.security import CurrentUser, get_current_user


class AuthMeResponse(BaseModel):
    user_id: str
    email: str | None
    role: str | None


router = APIRouter()


@router.get('/me', response_model=AuthMeResponse)
async def get_me(user: CurrentUser = Depends(get_current_user)) -> AuthMeResponse:
    return AuthMeResponse(user_id=user.user_id, email=user.email, role=user.role)

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.security import CurrentUser, get_current_user
from app.modules.profiles.schemas import ProfileResponse, UpdateProfileRequest
from app.modules.profiles.service import ProfileService

router = APIRouter()


@router.get('/me', response_model=ProfileResponse)
async def get_my_profile(
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> ProfileResponse:
    profile = await ProfileService(session).get_or_create_profile(user)
    return ProfileResponse.model_validate(profile)


@router.put('/me', response_model=ProfileResponse)
async def update_my_profile(
    payload: UpdateProfileRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> ProfileResponse:
    profile = await ProfileService(session).update_profile(user, payload)
    return ProfileResponse.model_validate(profile)

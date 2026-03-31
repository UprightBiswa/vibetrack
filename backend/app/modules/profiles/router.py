from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.security import CurrentUser, get_current_user
from app.modules.profiles.schemas import AddAuraRequest, ProfileResponse, UpdateProfileRequest
from app.modules.profiles.service import ProfileService

router = APIRouter()


@router.get('/me', response_model=ProfileResponse)
async def get_my_profile(
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> ProfileResponse:
    profile = await ProfileService(session).get_or_create_profile(user)
    return ProfileResponse.model_validate(profile)


@router.get('/{profile_id}', response_model=ProfileResponse)
async def get_profile_by_id(
    profile_id: str,
    session: AsyncSession = Depends(get_db_session),
) -> ProfileResponse:
    profile = await ProfileService(session).get_profile_by_id(profile_id)
    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Profile not found',
        )
    return ProfileResponse.model_validate(profile)


@router.put('/me', response_model=ProfileResponse)
async def update_my_profile(
    payload: UpdateProfileRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> ProfileResponse:
    profile = await ProfileService(session).update_profile(user, payload)
    return ProfileResponse.model_validate(profile)


@router.post('/me/aura', response_model=ProfileResponse)
async def add_profile_aura(
    payload: AddAuraRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> ProfileResponse:
    profile = await ProfileService(session).add_aura(user, payload.delta)
    return ProfileResponse.model_validate(profile)

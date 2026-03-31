from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.security import CurrentUser, get_current_user
from app.modules.profiles.schemas import (
    AddAuraRequest,
    LeaderboardEntryResponse,
    ProfileRankResponse,
    ProfileResponse,
    UpdateProfileRequest,
)
from app.modules.profiles.service import ProfileService

router = APIRouter()


@router.get('/me', response_model=ProfileResponse)
async def get_my_profile(
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> ProfileResponse:
    profile = await ProfileService(session).get_or_create_profile(user)
    return ProfileResponse.model_validate(profile)


@router.get('/me/rank', response_model=ProfileRankResponse)
async def get_my_rank(
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> ProfileRankResponse:
    service = ProfileService(session)
    profile = await service.get_or_create_profile(user)
    rank = await service.get_global_rank(profile.id)
    if rank is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Profile not found')
    return ProfileRankResponse(profile_id=profile.id, aura_points=profile.aura_points, global_rank=rank)


@router.get('/leaderboard', response_model=list[LeaderboardEntryResponse])
async def get_leaderboard(
    limit: int = 20,
    session: AsyncSession = Depends(get_db_session),
) -> list[LeaderboardEntryResponse]:
    return await ProfileService(session).list_leaderboard(limit=min(max(limit, 1), 100))


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

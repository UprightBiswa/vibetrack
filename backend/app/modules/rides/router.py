from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.security import CurrentUser, get_current_user
from app.modules.rides.schemas import (
    CreateRideSessionRequest,
    FinishRideRequest,
    RideSummary,
    StartRideRequest,
    StartRideResponse,
)
from app.modules.rides.service import RideService

router = APIRouter()


@router.post('/sessions/start', response_model=StartRideResponse)
async def start_ride(
    request: StartRideRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> StartRideResponse:
    ride = await RideService(session).start_ride(user, request)
    return StartRideResponse(session_id=ride.id, started_at=ride.started_at, status=ride.status)


@router.post('/sessions', response_model=RideSummary)
async def create_ride_session(
    request: CreateRideSessionRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> RideSummary:
    ride = await RideService(session).create_session(user, request)
    return RideSummary.model_validate(ride)


@router.post('/sessions/finish', response_model=RideSummary)
async def finish_ride(
    request: FinishRideRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> RideSummary:
    try:
        ride = await RideService(session).finish_ride(user, request)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return RideSummary.model_validate(ride)


@router.get('/sessions/mine', response_model=list[RideSummary])
async def list_my_rides(
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> list[RideSummary]:
    rides = await RideService(session).list_rides(user)
    return [RideSummary.model_validate(ride) for ride in rides]


@router.get('/sessions/{session_id}', response_model=RideSummary)
async def get_ride_session(
    session_id: str,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> RideSummary:
    ride = await RideService(session).get_ride(user, session_id)
    if ride is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Ride session not found')
    return RideSummary.model_validate(ride)

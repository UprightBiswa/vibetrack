from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.core.security import CurrentUser, get_current_user


class StartRideRequest(BaseModel):
    activity_type: str = Field(default='ride')


class StartRideResponse(BaseModel):
    session_id: str
    started_at: datetime


class FinishRideRequest(BaseModel):
    session_id: str
    distance_m: float = 0
    duration_s: int = 0


class FinishRideResponse(BaseModel):
    session_id: str
    status: str


class RideSummary(BaseModel):
    session_id: str
    activity_type: str
    distance_m: float
    duration_s: int


router = APIRouter()


@router.post('/sessions/start', response_model=StartRideResponse)
async def start_ride(
    request: StartRideRequest,
    user: CurrentUser = Depends(get_current_user),
) -> StartRideResponse:
    started_at = datetime.now(timezone.utc)
    session_id = f'{user.user_id}:{int(started_at.timestamp())}'
    return StartRideResponse(session_id=session_id, started_at=started_at)


@router.post('/sessions/finish', response_model=FinishRideResponse)
async def finish_ride(
    request: FinishRideRequest,
    user: CurrentUser = Depends(get_current_user),
) -> FinishRideResponse:
    _ = user
    return FinishRideResponse(session_id=request.session_id, status='queued')


@router.get('/sessions/mine', response_model=list[RideSummary])
async def list_my_rides(user: CurrentUser = Depends(get_current_user)) -> list[RideSummary]:
    _ = user
    return []

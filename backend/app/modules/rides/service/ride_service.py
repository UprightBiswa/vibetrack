from datetime import UTC, datetime
from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import CurrentUser
from app.modules.profiles.service import ProfileService
from app.modules.rides.models import RideSession, RideStatus
from app.modules.rides.schemas import (
    CreateRideSessionRequest,
    FinishRideRequest,
    StartRideRequest,
)


class RideService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.profile_service = ProfileService(session)

    async def start_ride(
        self,
        user: CurrentUser,
        payload: StartRideRequest,
    ) -> RideSession:
        await self.profile_service.get_or_create_profile(user)
        ride = RideSession(
            id=str(uuid4()),
            user_id=user.user_id,
            activity_type=payload.activity_type,
            status=RideStatus.active.value,
            started_at=datetime.now(UTC),
        )
        self.session.add(ride)
        await self.session.commit()
        await self.session.refresh(ride)
        return ride

    async def create_session(
        self,
        user: CurrentUser,
        payload: CreateRideSessionRequest,
    ) -> RideSession:
        await self.profile_service.get_or_create_profile(user)
        ride = RideSession(
            id=payload.session_id,
            user_id=user.user_id,
            activity_type=payload.activity_type,
            status=RideStatus.finished.value,
            started_at=payload.started_at,
            ended_at=payload.ended_at,
            distance_m=payload.distance_m,
            duration_s=payload.duration_s,
            avg_speed_mps=payload.avg_speed_mps,
            avg_pace=payload.avg_pace,
            calories=payload.calories,
            route_geojson=payload.route_geojson,
        )
        self.session.add(ride)
        await self.session.commit()
        await self.session.refresh(ride)
        return ride

    async def finish_ride(
        self,
        user: CurrentUser,
        payload: FinishRideRequest,
    ) -> RideSession:
        ride = await self.session.get(RideSession, payload.session_id)
        if ride is None or ride.user_id != user.user_id:
            raise ValueError('Ride session not found')

        ride.status = RideStatus.finished.value
        ride.ended_at = payload.ended_at or datetime.now(UTC)
        ride.distance_m = payload.distance_m
        ride.duration_s = payload.duration_s
        ride.avg_speed_mps = payload.avg_speed_mps
        ride.avg_pace = payload.avg_pace
        ride.calories = payload.calories
        ride.route_geojson = payload.route_geojson

        await self.session.commit()
        await self.session.refresh(ride)
        return ride

    async def get_ride(self, user: CurrentUser, session_id: str) -> RideSession | None:
        ride = await self.session.get(RideSession, session_id)
        if ride is None or ride.user_id != user.user_id:
            return None
        return ride

    async def list_rides(
        self,
        user: CurrentUser,
        limit: int = 50,
    ) -> list[RideSession]:
        result = await self.session.execute(
            select(RideSession)
            .where(RideSession.user_id == user.user_id)
            .order_by(RideSession.started_at.desc())
            .limit(limit)
        )
        return list(result.scalars())

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import CurrentUser
from app.modules.profiles.service import ProfileService
from app.modules.rides.models import RideSession, RideStatus
from app.modules.zones.models import Zone, ZoneClaimEvent
from app.modules.zones.schemas import ZoneClaimResponse


class ZoneService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.profile_service = ProfileService(session)

    async def list_zones(self) -> list[Zone]:
        await self._seed_default_zones_if_needed()
        result = await self.session.execute(select(Zone).order_by(Zone.name.asc()))
        return list(result.scalars())

    async def claim_zone(
        self,
        user: CurrentUser,
        zone_id: str,
        session_id: str,
    ) -> ZoneClaimResponse:
        await self.profile_service.get_or_create_profile(user)

        zone = await self.session.get(Zone, zone_id)
        if zone is None:
            raise ValueError('Zone not found')

        ride = await self.session.get(RideSession, session_id)
        if ride is None or ride.user_id != user.user_id:
            raise ValueError('Ride session not found for zone claim')
        if ride.status != RideStatus.finished.value:
            raise ValueError('Only finished rides can claim zones')

        aura_awarded = max(int(50 * zone.score_multiplier), 1)
        zone.current_guardian_user_id = user.user_id

        claim_event = ZoneClaimEvent(
            zone_id=zone.id,
            user_id=user.user_id,
            session_id=ride.id,
            aura_awarded=aura_awarded,
        )
        self.session.add(claim_event)

        profile = await self.profile_service.get_or_create_profile(user)
        profile.aura_points += aura_awarded

        await self.session.commit()
        await self.session.refresh(claim_event)

        return ZoneClaimResponse(
            zone_id=zone.id,
            claim_status='claimed',
            guardian_user_id=user.user_id,
            aura_awarded=aura_awarded,
            claimed_at=claim_event.created_at,
        )

    async def _seed_default_zones_if_needed(self) -> None:
        count = await self.session.scalar(select(Zone.id).limit(1))
        if count is not None:
            return

        zones = [
            Zone(
                id='zone-downtown-grid',
                name='Downtown Grid',
                city='Bengaluru',
                score_multiplier=1.1,
                polygon={
                    'type': 'Polygon',
                    'coordinates': [
                        [
                            [77.5883, 12.9716],
                            [77.6001, 12.9716],
                            [77.6001, 12.9810],
                            [77.5883, 12.9810],
                            [77.5883, 12.9716],
                        ],
                    ],
                },
            ),
            Zone(
                id='zone-hill-climb',
                name='Hill Climb',
                city='Bengaluru',
                score_multiplier=1.5,
                polygon={
                    'type': 'Polygon',
                    'coordinates': [
                        [
                            [77.5700, 12.9450],
                            [77.5810, 12.9450],
                            [77.5810, 12.9530],
                            [77.5700, 12.9530],
                            [77.5700, 12.9450],
                        ],
                    ],
                },
            ),
        ]
        self.session.add_all(zones)
        await self.session.commit()

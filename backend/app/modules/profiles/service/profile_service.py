from datetime import UTC, date

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import CurrentUser
from app.modules.profiles.models import Profile
from app.modules.profiles.schemas import LeaderboardEntryResponse, ProfileStreakResponse, UpdateProfileRequest
from app.modules.rides.models import RideSession, RideStatus


class ProfileService:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_or_create_profile(self, user: CurrentUser) -> Profile:
        profile = await self.session.get(Profile, user.user_id)
        if profile is None:
            profile = Profile(
                id=user.user_id,
                email=user.email,
                username=(user.email or '').split('@')[0][:64],
            )
            self.session.add(profile)
            await self.session.commit()
            await self.session.refresh(profile)
            return profile

        if user.email and profile.email != user.email:
            profile.email = user.email
            await self.session.commit()
            await self.session.refresh(profile)
        return profile

    async def get_profile_by_id(self, profile_id: str) -> Profile | None:
        return await self.session.get(Profile, profile_id)

    async def update_profile(self, user: CurrentUser, payload: UpdateProfileRequest) -> Profile:
        profile = await self.get_or_create_profile(user)
        data = payload.model_dump(exclude_none=True)
        for key, value in data.items():
            setattr(profile, key, value)
        await self.session.commit()
        await self.session.refresh(profile)
        return profile

    async def add_aura(self, user: CurrentUser, delta: int) -> Profile:
        profile = await self.get_or_create_profile(user)
        profile.aura_points = max(profile.aura_points + delta, 0)
        await self.session.commit()
        await self.session.refresh(profile)
        return profile

    async def list_profiles(self, limit: int = 20) -> list[Profile]:
        statement = select(Profile).order_by(Profile.created_at.desc()).limit(limit)
        result = await self.session.execute(statement)
        return list(result.scalars())

    async def get_global_rank(self, profile_id: str) -> int | None:
        profile = await self.session.get(Profile, profile_id)
        if profile is None:
            return None

        result = await self.session.execute(
            select(Profile.id).order_by(desc(Profile.aura_points), Profile.created_at.asc())
        )
        ordered_ids = list(result.scalars())
        try:
            return ordered_ids.index(profile_id) + 1
        except ValueError:
            return None

    async def list_leaderboard(self, limit: int = 20) -> list[LeaderboardEntryResponse]:
        result = await self.session.execute(
            select(Profile).order_by(desc(Profile.aura_points), Profile.created_at.asc()).limit(limit)
        )
        profiles = list(result.scalars())
        return [
            LeaderboardEntryResponse(
                profile_id=profile.id,
                username=profile.username,
                aura_points=profile.aura_points,
                global_rank=index + 1,
            )
            for index, profile in enumerate(profiles)
        ]

    async def get_streak(self, profile_id: str) -> ProfileStreakResponse | None:
        profile = await self.session.get(Profile, profile_id)
        if profile is None:
            return None

        result = await self.session.execute(
            select(RideSession.ended_at)
            .where(
                RideSession.user_id == profile_id,
                RideSession.status == RideStatus.finished.value,
                RideSession.ended_at.is_not(None),
            )
            .order_by(RideSession.ended_at.desc())
        )
        ride_dates = sorted(
            {
                ended_at.astimezone(UTC).date()
                for ended_at in result.scalars()
                if ended_at is not None
            },
            reverse=True,
        )

        if not ride_dates:
            return ProfileStreakResponse(
                profile_id=profile_id,
                current_streak_days=0,
                longest_streak_days=0,
                active_today=False,
            )

        today = date.today()
        active_today = ride_dates[0] == today

        current_streak = 0
        streak_start = today if active_today else today.fromordinal(today.toordinal() - 1)
        cursor = streak_start
        date_set = set(ride_dates)
        while cursor in date_set:
            current_streak += 1
            cursor = date.fromordinal(cursor.toordinal() - 1)

        longest_streak = 0
        running = 0
        previous: date | None = None
        for ride_date in sorted(date_set):
            if previous is None or (ride_date.toordinal() - previous.toordinal()) == 1:
                running += 1
            else:
                running = 1
            previous = ride_date
            if running > longest_streak:
                longest_streak = running

        return ProfileStreakResponse(
            profile_id=profile_id,
            current_streak_days=current_streak,
            longest_streak_days=longest_streak,
            active_today=active_today,
        )

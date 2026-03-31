from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import CurrentUser
from app.modules.profiles.models import Profile
from app.modules.profiles.schemas import LeaderboardEntryResponse, UpdateProfileRequest


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

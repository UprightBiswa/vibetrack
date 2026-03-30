from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import CurrentUser
from app.modules.feed.models import FeedPost
from app.modules.feed.schemas import CreateFeedPostRequest
from app.modules.profiles.service import ProfileService
from app.modules.rides.models import RideSession


class FeedService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.profile_service = ProfileService(session)

    async def list_posts(self, limit: int = 50) -> list[FeedPost]:
        result = await self.session.execute(
            select(FeedPost).order_by(FeedPost.created_at.desc()).limit(limit)
        )
        return list(result.scalars())

    async def create_post(self, user: CurrentUser, payload: CreateFeedPostRequest) -> FeedPost:
        await self.profile_service.get_or_create_profile(user)

        if payload.session_id:
            ride = await self.session.get(RideSession, payload.session_id)
            if ride is None or ride.user_id != user.user_id:
                raise ValueError('Ride session not found for post')

        post = FeedPost(
            id=str(uuid4()),
            user_id=user.user_id,
            session_id=payload.session_id,
            image_url=payload.image_url,
            caption=payload.caption,
            stats_json=payload.stats_json,
        )
        self.session.add(post)
        await self.session.commit()
        await self.session.refresh(post)
        return post

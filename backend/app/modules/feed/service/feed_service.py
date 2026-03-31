from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import CurrentUser
from app.modules.feed.models import FeedPost
from app.modules.feed.schemas import CreateFeedPostRequest, FeedPostResponse
from app.modules.profiles.models import Profile
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

    async def like_post(self, post_id: str) -> FeedPost | None:
        post = await self.session.get(FeedPost, post_id)
        if post is None:
            return None
        post.like_count += 1
        await self.session.commit()
        await self.session.refresh(post)
        return post

    async def to_response(self, post: FeedPost) -> FeedPostResponse:
        profile = await self.session.get(Profile, post.user_id)
        return FeedPostResponse(
            id=post.id,
            user_id=post.user_id,
            session_id=post.session_id,
            image_url=post.image_url,
            caption=post.caption,
            stats_json=post.stats_json,
            like_count=post.like_count,
            comment_count=post.comment_count,
            created_at=post.created_at,
            updated_at=post.updated_at,
            username=(profile.username if profile else 'Rider'),
        )

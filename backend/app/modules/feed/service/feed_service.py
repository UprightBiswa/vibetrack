from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import CurrentUser
from app.modules.feed.models import FeedComment, FeedPost, FeedPostLike
from app.modules.feed.schemas import (
    CreateFeedCommentRequest,
    CreateFeedPostRequest,
    FeedCommentResponse,
    FeedPostResponse,
)
from app.modules.notifications.service import NotificationService
from app.modules.profiles.models import Profile
from app.modules.profiles.service import ProfileService
from app.modules.rides.models import RideSession


class FeedService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.profile_service = ProfileService(session)
        self.notification_service = NotificationService(session)

    async def list_posts(self, limit: int = 50) -> list[FeedPost]:
        result = await self.session.execute(
            select(FeedPost).order_by(FeedPost.created_at.desc()).limit(limit)
        )
        return list(result.scalars())

    async def get_post(self, post_id: str) -> FeedPost | None:
        return await self.session.get(FeedPost, post_id)

    async def list_comments(self, post_id: str) -> list[FeedComment]:
        result = await self.session.execute(
            select(FeedComment)
            .where(FeedComment.post_id == post_id)
            .order_by(FeedComment.created_at.asc())
        )
        return list(result.scalars())

    async def has_liked(self, post_id: str, user_id: str) -> bool:
        result = await self.session.execute(
            select(FeedPostLike.id).where(
                FeedPostLike.post_id == post_id,
                FeedPostLike.user_id == user_id,
            )
        )
        return result.scalar_one_or_none() is not None

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

    async def create_comment(
        self,
        post_id: str,
        user: CurrentUser,
        payload: CreateFeedCommentRequest,
    ) -> FeedComment:
        actor_profile = await self.profile_service.get_or_create_profile(user)

        post = await self.session.get(FeedPost, post_id)
        if post is None:
            raise ValueError('Post not found')

        comment_body = payload.body.strip()
        comment = FeedComment(
            id=str(uuid4()),
            post_id=post_id,
            user_id=user.user_id,
            body=comment_body,
        )
        post.comment_count += 1
        self.session.add(comment)
        await self.session.commit()
        await self.session.refresh(comment)

        if post.user_id != user.user_id:
            actor_name = actor_profile.username or (user.email or 'Someone').split('@')[0]
            await self.notification_service.create_user_notification(
                post.user_id,
                type='post_comment',
                title=f'{actor_name} commented on your post',
                body=(comment_body[:120] if comment_body else 'New comment on your ride'),
                route=f'/feed/post/{post.id}',
                entity_id=post.id,
                payload_json={
                    'post_id': post.id,
                    'actor_user_id': user.user_id,
                    'actor_username': actor_name,
                },
            )
        return comment

    async def toggle_like(self, post_id: str, user: CurrentUser) -> FeedPost | None:
        actor_profile = await self.profile_service.get_or_create_profile(user)
        post = await self.session.get(FeedPost, post_id)
        if post is None:
            return None

        result = await self.session.execute(
            select(FeedPostLike).where(
                FeedPostLike.post_id == post_id,
                FeedPostLike.user_id == user.user_id,
            )
        )
        existing_like = result.scalar_one_or_none()
        created_like = False

        if existing_like is None:
            like = FeedPostLike(
                id=str(uuid4()),
                post_id=post_id,
                user_id=user.user_id,
            )
            self.session.add(like)
            post.like_count += 1
            created_like = True
        else:
            await self.session.delete(existing_like)
            post.like_count = max(0, post.like_count - 1)

        await self.session.commit()
        await self.session.refresh(post)

        if created_like and post.user_id != user.user_id:
            actor_name = actor_profile.username or (user.email or 'Someone').split('@')[0]
            await self.notification_service.create_user_notification(
                post.user_id,
                type='post_like',
                title=f'{actor_name} liked your post',
                body='Your activity is getting attention.',
                route=f'/feed/post/{post.id}',
                entity_id=post.id,
                payload_json={
                    'post_id': post.id,
                    'actor_user_id': user.user_id,
                    'actor_username': actor_name,
                },
            )
        return post

    async def to_response(
        self,
        post: FeedPost,
        current_user: CurrentUser | None = None,
    ) -> FeedPostResponse:
        profile = await self.session.get(Profile, post.user_id)
        liked_by_me = False
        if current_user is not None:
            liked_by_me = await self.has_liked(post.id, current_user.user_id)
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
            liked_by_me=liked_by_me,
        )

    async def comment_to_response(self, comment: FeedComment) -> FeedCommentResponse:
        profile = await self.session.get(Profile, comment.user_id)
        return FeedCommentResponse(
            id=comment.id,
            post_id=comment.post_id,
            user_id=comment.user_id,
            body=comment.body,
            created_at=comment.created_at,
            updated_at=comment.updated_at,
            username=(profile.username if profile else 'Rider'),
        )

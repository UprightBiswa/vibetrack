from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.security import CurrentUser, get_current_user
from app.modules.feed.schemas import CreateFeedPostRequest, FeedPostResponse
from app.modules.feed.service import FeedService

router = APIRouter()


@router.get('/posts', response_model=list[FeedPostResponse])
async def list_feed_posts(
    session: AsyncSession = Depends(get_db_session),
) -> list[FeedPostResponse]:
    service = FeedService(session)
    posts = await service.list_posts()
    return [await service.to_response(post) for post in posts]


@router.post('/posts', response_model=FeedPostResponse)
async def create_feed_post(
    request: CreateFeedPostRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> FeedPostResponse:
    service = FeedService(session)
    try:
        post = await service.create_post(user, request)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return await service.to_response(post)


@router.post('/posts/{post_id}/like', response_model=FeedPostResponse)
async def like_feed_post(
    post_id: str,
    session: AsyncSession = Depends(get_db_session),
) -> FeedPostResponse:
    service = FeedService(session)
    post = await service.like_post(post_id)
    if post is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Post not found')
    return await service.to_response(post)

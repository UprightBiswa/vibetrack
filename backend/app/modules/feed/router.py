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
    posts = await FeedService(session).list_posts()
    return [FeedPostResponse.model_validate(post) for post in posts]


@router.post('/posts', response_model=FeedPostResponse)
async def create_feed_post(
    request: CreateFeedPostRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> FeedPostResponse:
    try:
        post = await FeedService(session).create_post(user, request)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return FeedPostResponse.model_validate(post)

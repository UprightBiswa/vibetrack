from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.core.security import CurrentUser, get_current_user


class FeedPostResponse(BaseModel):
    id: str
    caption: str
    image_url: str
    created_at: datetime


class CreateFeedPostRequest(BaseModel):
    session_id: str | None = None
    caption: str = ''
    image_url: str = ''


router = APIRouter()


@router.get('/posts', response_model=list[FeedPostResponse])
async def list_feed_posts() -> list[FeedPostResponse]:
    return []


@router.post('/posts', response_model=FeedPostResponse)
async def create_feed_post(
    request: CreateFeedPostRequest,
    user: CurrentUser = Depends(get_current_user),
) -> FeedPostResponse:
    created_at = datetime.now(timezone.utc)
    return FeedPostResponse(
        id=f'post:{user.user_id}:{int(created_at.timestamp())}',
        caption=request.caption,
        image_url=request.image_url,
        created_at=created_at,
    )

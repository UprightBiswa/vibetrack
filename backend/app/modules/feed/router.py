from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.security import CurrentUser, get_current_user
from app.modules.feed.schemas import (
    CreateFeedCommentRequest,
    CreateFeedPostRequest,
    FeedCommentResponse,
    FeedPostResponse,
)
from app.modules.feed.service import FeedService

router = APIRouter()


@router.get('/posts', response_model=list[FeedPostResponse])
async def list_feed_posts(
    session: AsyncSession = Depends(get_db_session),
) -> list[FeedPostResponse]:
    service = FeedService(session)
    posts = await service.list_posts()
    return [await service.to_response(post) for post in posts]


@router.get('/posts/{post_id}', response_model=FeedPostResponse)
async def get_feed_post(
    post_id: str,
    session: AsyncSession = Depends(get_db_session),
) -> FeedPostResponse:
    service = FeedService(session)
    post = await service.get_post(post_id)
    if post is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Post not found')
    return await service.to_response(post)


@router.get('/posts/{post_id}/comments', response_model=list[FeedCommentResponse])
async def list_feed_comments(
    post_id: str,
    session: AsyncSession = Depends(get_db_session),
) -> list[FeedCommentResponse]:
    service = FeedService(session)
    post = await service.get_post(post_id)
    if post is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Post not found')
    comments = await service.list_comments(post_id)
    return [await service.comment_to_response(comment) for comment in comments]


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


@router.post('/posts/{post_id}/comments', response_model=FeedCommentResponse)
async def create_feed_comment(
    post_id: str,
    request: CreateFeedCommentRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> FeedCommentResponse:
    service = FeedService(session)
    try:
        comment = await service.create_comment(post_id, user, request)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return await service.comment_to_response(comment)


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

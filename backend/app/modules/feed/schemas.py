from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CreateFeedPostRequest(BaseModel):
    session_id: str | None = None
    caption: str = Field(default='', max_length=2000)
    image_url: str = Field(default='', max_length=512)
    stats_json: dict = Field(default_factory=dict)


class CreateFeedCommentRequest(BaseModel):
    body: str = Field(min_length=1, max_length=1000)


class UpdateFeedPostRequest(BaseModel):
    caption: str = Field(default='', max_length=2000)
    image_url: str = Field(default='', max_length=512)
    stats_json: dict = Field(default_factory=dict)


class FeedCommentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    post_id: str
    user_id: str
    body: str
    created_at: datetime
    updated_at: datetime
    username: str


class FeedPostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    session_id: str | None
    image_url: str
    caption: str
    stats_json: dict
    like_count: int
    comment_count: int
    created_at: datetime
    updated_at: datetime
    username: str
    liked_by_me: bool = False

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CreateFeedPostRequest(BaseModel):
    session_id: str | None = None
    caption: str = Field(default='', max_length=2000)
    image_url: str = Field(default='', max_length=512)
    stats_json: dict = Field(default_factory=dict)


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

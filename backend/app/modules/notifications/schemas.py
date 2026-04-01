from datetime import datetime

from pydantic import BaseModel, Field


class DeviceTokenRequest(BaseModel):
    token: str = Field(min_length=20, max_length=512)
    platform: str = Field(default='android', max_length=32)


class DeviceTokenDeleteRequest(BaseModel):
    token: str = Field(min_length=20, max_length=512)


class NotificationResponse(BaseModel):
    id: str
    recipient_user_id: str
    type: str
    title: str
    body: str
    route: str
    entity_id: str
    payload_json: dict
    is_read: bool
    read_at: datetime | None
    created_at: datetime
    updated_at: datetime


class NotificationUnreadCountResponse(BaseModel):
    unread_count: int


class TestNotificationRequest(BaseModel):
    title: str = Field(default='VibeTrack test', max_length=120)
    body: str = Field(default='Push delivery is working.', max_length=240)
    route: str = Field(default='', max_length=255)
    entity_id: str = Field(default='', max_length=64)
    payload_json: dict = Field(default_factory=dict)


class UserNotificationRequest(BaseModel):
    recipient_user_id: str = Field(min_length=3, max_length=64)
    type: str = Field(default='system', max_length=64)
    title: str = Field(max_length=120)
    body: str = Field(max_length=240)
    route: str = Field(default='', max_length=255)
    entity_id: str = Field(default='', max_length=64)
    payload_json: dict = Field(default_factory=dict)


class BroadcastNotificationRequest(BaseModel):
    type: str = Field(default='broadcast', max_length=64)
    title: str = Field(max_length=120)
    body: str = Field(max_length=240)
    route: str = Field(default='', max_length=255)
    entity_id: str = Field(default='', max_length=64)
    payload_json: dict = Field(default_factory=dict)

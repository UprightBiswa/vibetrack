from __future__ import annotations

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin


class DeviceToken(Base, TimestampMixin):
    __tablename__ = 'device_tokens'
    __table_args__ = (
        UniqueConstraint('user_id', 'token', name='uq_device_token_user_token'),
        UniqueConstraint('token', name='uq_device_token_token'),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(
        ForeignKey('profiles.id', ondelete='CASCADE'),
        index=True,
    )
    token: Mapped[str] = mapped_column(String(512), index=True)
    platform: Mapped[str] = mapped_column(String(32), default='android', nullable=False)


class AppNotification(Base, TimestampMixin):
    __tablename__ = 'app_notifications'

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    recipient_user_id: Mapped[str] = mapped_column(
        ForeignKey('profiles.id', ondelete='CASCADE'),
        index=True,
    )
    type: Mapped[str] = mapped_column(String(64), default='system', nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(160), default='', nullable=False)
    body: Mapped[str] = mapped_column(String(512), default='', nullable=False)
    route: Mapped[str] = mapped_column(String(255), default='', nullable=False)
    entity_id: Mapped[str] = mapped_column(String(64), default='', nullable=False, index=True)
    payload_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

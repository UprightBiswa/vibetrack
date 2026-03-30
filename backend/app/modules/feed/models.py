from __future__ import annotations

from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin


class FeedPost(Base, TimestampMixin):
    __tablename__ = 'feed_posts'

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(
        ForeignKey('profiles.id', ondelete='CASCADE'),
        index=True,
    )
    session_id: Mapped[str | None] = mapped_column(
        ForeignKey('ride_sessions.id', ondelete='SET NULL'),
        nullable=True,
        index=True,
    )
    image_url: Mapped[str] = mapped_column(String(512), default='', nullable=False)
    caption: Mapped[str] = mapped_column(Text, default='', nullable=False)
    stats_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
    like_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    comment_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    profile = relationship('Profile', back_populates='posts')
    ride_session = relationship('RideSession', back_populates='posts')

from __future__ import annotations

from datetime import datetime
from enum import StrEnum

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin


class RideStatus(StrEnum):
    active = 'active'
    finished = 'finished'
    canceled = 'canceled'


class RideSession(Base, TimestampMixin):
    __tablename__ = 'ride_sessions'

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(
        ForeignKey('profiles.id', ondelete='CASCADE'),
        index=True,
    )
    activity_type: Mapped[str] = mapped_column(
        String(32),
        default='ride',
        nullable=False,
        index=True,
    )
    status: Mapped[str] = mapped_column(
        String(16),
        default=RideStatus.active.value,
        nullable=False,
        index=True,
    )
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    distance_m: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    duration_s: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    avg_speed_mps: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    avg_pace: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    calories: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    route_geojson: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    profile = relationship('Profile', back_populates='rides')
    posts = relationship('FeedPost', back_populates='ride_session')

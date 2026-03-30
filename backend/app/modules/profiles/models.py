from __future__ import annotations

from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin


class Profile(Base, TimestampMixin):
    __tablename__ = 'profiles'

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)
    username: Mapped[str] = mapped_column(String(64), default='', nullable=False, index=True)
    avatar_url: Mapped[str] = mapped_column(String(512), default='', nullable=False)
    home_city: Mapped[str] = mapped_column(String(128), default='', nullable=False)
    aura_points: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    rides = relationship('RideSession', back_populates='profile', cascade='all, delete-orphan')
    posts = relationship('FeedPost', back_populates='profile', cascade='all, delete-orphan')

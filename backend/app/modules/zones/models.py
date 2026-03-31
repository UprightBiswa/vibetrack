from __future__ import annotations

from sqlalchemy import Float, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin


class Zone(Base, TimestampMixin):
    __tablename__ = 'zones'

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(128), nullable=False, index=True)
    polygon: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
    city: Mapped[str] = mapped_column(String(128), nullable=False, index=True)
    score_multiplier: Mapped[float] = mapped_column(Float, default=1.0, nullable=False)
    current_guardian_user_id: Mapped[str | None] = mapped_column(
        ForeignKey('profiles.id', ondelete='SET NULL'),
        nullable=True,
        index=True,
    )


class ZoneClaimEvent(Base, TimestampMixin):
    __tablename__ = 'zone_claim_events'

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    zone_id: Mapped[str] = mapped_column(
        ForeignKey('zones.id', ondelete='CASCADE'),
        nullable=False,
        index=True,
    )
    user_id: Mapped[str] = mapped_column(
        ForeignKey('profiles.id', ondelete='CASCADE'),
        nullable=False,
        index=True,
    )
    session_id: Mapped[str] = mapped_column(
        ForeignKey('ride_sessions.id', ondelete='CASCADE'),
        nullable=False,
        index=True,
    )
    aura_awarded: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

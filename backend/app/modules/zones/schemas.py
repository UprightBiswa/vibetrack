from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ZoneResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    polygon: dict
    city: str
    score_multiplier: float
    current_guardian_user_id: str | None


class ZoneClaimRequest(BaseModel):
    session_id: str


class ZoneClaimResponse(BaseModel):
    zone_id: str
    claim_status: str
    guardian_user_id: str | None
    aura_awarded: int
    claimed_at: datetime

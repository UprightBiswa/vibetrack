from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.core.security import CurrentUser, get_current_user


class ZoneResponse(BaseModel):
    id: str
    name: str
    city: str
    current_guardian_user_id: str | None


class ZoneClaimResponse(BaseModel):
    zone_id: str
    status: str


router = APIRouter()


@router.get('', response_model=list[ZoneResponse])
async def list_zones() -> list[ZoneResponse]:
    return []


@router.post('/{zone_id}/claim', response_model=ZoneClaimResponse)
async def claim_zone(
    zone_id: str,
    user: CurrentUser = Depends(get_current_user),
) -> ZoneClaimResponse:
    _ = user
    return ZoneClaimResponse(zone_id=zone_id, status='queued')

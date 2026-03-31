from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.security import CurrentUser, get_current_user
from app.modules.zones.schemas import ZoneClaimRequest, ZoneClaimResponse, ZoneResponse
from app.modules.zones.service import ZoneService

router = APIRouter()


@router.get('', response_model=list[ZoneResponse])
async def list_zones(
    session: AsyncSession = Depends(get_db_session),
) -> list[ZoneResponse]:
    zones = await ZoneService(session).list_zones()
    return [ZoneResponse.model_validate(zone) for zone in zones]


@router.post('/{zone_id}/claim', response_model=ZoneClaimResponse)
async def claim_zone(
    zone_id: str,
    payload: ZoneClaimRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> ZoneClaimResponse:
    if not payload.session_id.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='session_id is required',
        )

    try:
        return await ZoneService(session).claim_zone(user, zone_id, payload.session_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.core.security import CurrentUser, require_superadmin


class AdminOverviewResponse(BaseModel):
    environment: str
    active_flags: list[str]


router = APIRouter()


@router.get('/overview', response_model=AdminOverviewResponse)
async def get_admin_overview(
    user: CurrentUser = Depends(require_superadmin),
) -> AdminOverviewResponse:
    _ = user
    return AdminOverviewResponse(environment='development', active_flags=[])

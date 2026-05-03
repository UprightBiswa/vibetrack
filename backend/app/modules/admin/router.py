from pathlib import Path

from fastapi import APIRouter, Depends
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.security import CurrentUser, require_superadmin
from app.modules.notifications.models import DeviceToken
from app.modules.profiles.models import Profile

ADMIN_UI_DIR = Path(__file__).resolve().parent / 'ui'


class AdminOverviewResponse(BaseModel):
    environment: str
    active_flags: list[str]


class AdminNotificationRecipientResponse(BaseModel):
    user_id: str
    email: str | None
    username: str
    device_count: int


router = APIRouter()


@router.get('/overview', response_model=AdminOverviewResponse)
async def get_admin_overview(
    user: CurrentUser = Depends(require_superadmin),
) -> AdminOverviewResponse:
    _ = user
    return AdminOverviewResponse(environment='development', active_flags=[])


@router.get('/notification-recipients', response_model=list[AdminNotificationRecipientResponse])
async def list_notification_recipients(
    user: CurrentUser = Depends(require_superadmin),
    session: AsyncSession = Depends(get_db_session),
) -> list[AdminNotificationRecipientResponse]:
    _ = user
    result = await session.execute(
        select(
            Profile.id,
            Profile.email,
            Profile.username,
            func.count(DeviceToken.id).label('device_count'),
        )
        .join(DeviceToken, DeviceToken.user_id == Profile.id)
        .group_by(Profile.id, Profile.email, Profile.username)
        .order_by(Profile.username.asc())
    )
    return [
        AdminNotificationRecipientResponse(
            user_id=row.id,
            email=row.email,
            username=row.username or 'Rider',
            device_count=int(row.device_count or 0),
        )
        for row in result
    ]


@router.get('/notifications-console', response_class=HTMLResponse)
async def notification_console() -> str:
    return (ADMIN_UI_DIR / 'notifications_console.html').read_text(encoding='utf-8')

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.core.security import CurrentUser, get_current_user
from app.modules.shared.schemas import MessageResponse


class DeviceTokenRequest(BaseModel):
    token: str
    platform: str


router = APIRouter()


@router.post('/device-token', response_model=MessageResponse)
async def register_device_token(
    request: DeviceTokenRequest,
    user: CurrentUser = Depends(get_current_user),
) -> MessageResponse:
    _ = (request, user)
    return MessageResponse(message='device token queued')

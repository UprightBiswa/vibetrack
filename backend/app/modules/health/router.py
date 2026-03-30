from datetime import datetime, timezone

from fastapi import APIRouter

from app.modules.shared.schemas import HealthResponse, MessageResponse


router = APIRouter()


@router.get('/health', response_model=HealthResponse)
async def health_check() -> HealthResponse:
    return HealthResponse(status='ok', timestamp=datetime.now(timezone.utc))


@router.get('/ready', response_model=MessageResponse)
async def readiness_check() -> MessageResponse:
    return MessageResponse(message='ready')

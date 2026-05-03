from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import text

from app.core.database import engine
from app.modules.shared.schemas import HealthResponse, MessageResponse

router = APIRouter()


@router.get('/health', response_model=HealthResponse)
async def health_check() -> HealthResponse:
    return HealthResponse(status='ok', timestamp=datetime.now(UTC))


@router.get('/ready', response_model=MessageResponse)
async def readiness_check() -> MessageResponse:
    try:
        async with engine.connect() as conn:
            await conn.scalar(text('select 1'))
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail='database unavailable',
        ) from exc
    return MessageResponse(message='ready')

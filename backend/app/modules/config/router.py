from fastapi import APIRouter
from pydantic import BaseModel

from app.core.config import settings


class BootstrapConfigResponse(BaseModel):
    app_name: str
    api_base_path: str
    supports_live_tracking: bool
    supports_notifications: bool


router = APIRouter()


@router.get('/bootstrap', response_model=BootstrapConfigResponse)
async def get_bootstrap_config() -> BootstrapConfigResponse:
    return BootstrapConfigResponse(
        app_name=settings.project_name,
        api_base_path=settings.api_v1_prefix,
        supports_live_tracking=False,
        supports_notifications=True,
    )

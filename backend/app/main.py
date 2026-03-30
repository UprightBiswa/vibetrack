from fastapi import FastAPI

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.logging import configure_logging


configure_logging()

app = FastAPI(
    title=settings.project_name,
    version='0.1.0',
    docs_url='/docs',
    redoc_url='/redoc',
)

app.include_router(api_router, prefix=settings.api_v1_prefix)

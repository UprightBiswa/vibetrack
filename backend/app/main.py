from contextlib import asynccontextmanager

from fastapi import FastAPI

import app.db.models  # noqa: F401
from app.api.v1.router import api_router
from app.core.config import settings
from app.core.database import init_db
from app.core.logging import configure_logging

configure_logging()


@asynccontextmanager
async def lifespan(_: FastAPI):
    if settings.auto_create_tables:
        await init_db()
    yield


app = FastAPI(
    title=settings.project_name,
    version='0.1.0',
    docs_url='/docs',
    redoc_url='/redoc',
    lifespan=lifespan,
)

app.include_router(api_router, prefix=settings.api_v1_prefix)

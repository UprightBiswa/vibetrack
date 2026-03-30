from collections.abc import AsyncIterator
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings
from app.db.base import Base


def normalize_database_url(database_url: str) -> str:
    split_url = urlsplit(database_url)
    query_params = dict(parse_qsl(split_url.query, keep_blank_values=True))

    sslmode = query_params.pop('sslmode', None)
    query_params.pop('channel_binding', None)

    if sslmode and 'ssl' not in query_params:
        query_params['ssl'] = 'require' if sslmode == 'require' else sslmode

    return urlunsplit(
        (
            split_url.scheme,
            split_url.netloc,
            split_url.path,
            urlencode(query_params),
            split_url.fragment,
        )
    )


engine = create_async_engine(normalize_database_url(settings.database_url), pool_pre_ping=True)
SessionLocal = async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)


async def get_db_session() -> AsyncIterator[AsyncSession]:
    async with SessionLocal() as session:
        yield session


async def init_db() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

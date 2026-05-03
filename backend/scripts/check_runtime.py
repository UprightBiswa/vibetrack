import asyncio

import httpx
from sqlalchemy import text

from app.core.config import settings
from app.core.database import engine
from app.core.firebase import initialize_firebase


def _configured(value: object) -> str:
    return 'yes' if bool(value) else 'no'


async def check_database() -> bool:
    async with engine.connect() as conn:
        value = await conn.scalar(text('select 1'))
    return value == 1


async def check_supabase_jwks() -> bool:
    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(settings.supabase_jwks_url)
    response.raise_for_status()
    payload = response.json()
    return isinstance(payload.get('keys'), list)


async def main() -> None:
    print(f'app_env={settings.app_env}')
    print(f'api_prefix={settings.api_v1_prefix}')
    print(f'auto_create_tables={settings.auto_create_tables}')
    print(f'database_url_configured={_configured(settings.database_url)}')
    print(f'supabase_url_configured={_configured(settings.supabase_url)}')
    print(f'supabase_anon_key_configured={_configured(settings.supabase_anon_key)}')
    firebase_credentials = settings.google_application_credentials or settings.fcm_private_key
    print(f'firebase_credentials_configured={_configured(firebase_credentials)}')

    try:
        database_ok = await check_database()
        print(f'database_ping={"ok" if database_ok else "failed"}')
    except Exception as exc:
        print(f'database_ping=failed ({exc.__class__.__name__})')

    try:
        supabase_ok = await check_supabase_jwks()
        print(f'supabase_jwks={"ok" if supabase_ok else "failed"}')
    except Exception as exc:
        print(f'supabase_jwks=failed ({exc.__class__.__name__})')

    try:
        firebase_ok = initialize_firebase()
        print(f'firebase_admin={"ok" if firebase_ok else "not_configured"}')
    except Exception as exc:
        print(f'firebase_admin=failed ({exc.__class__.__name__})')


if __name__ == '__main__':
    asyncio.run(main())

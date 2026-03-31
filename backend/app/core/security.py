from dataclasses import dataclass

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import PyJWKClient, decode
from jwt.exceptions import InvalidTokenError

from app.core.config import settings

security = HTTPBearer(auto_error=False)
_jwk_client = PyJWKClient(settings.supabase_jwks_url)


@dataclass(slots=True)
class CurrentUser:
    user_id: str
    email: str | None
    role: str | None


def decode_supabase_token(token: str) -> dict:
    signing_key = _jwk_client.get_signing_key_from_jwt(token)
    return decode(
        token,
        signing_key.key,
        algorithms=['RS256'],
        audience=settings.supabase_jwt_audience,
        issuer=settings.supabase_jwt_issuer,
    )


async def fetch_supabase_user(token: str) -> dict:
    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(
            settings.supabase_userinfo_url,
            headers={
                'Authorization': f'Bearer {token}',
                'apikey': settings.supabase_anon_key or '',
            },
        )
    response.raise_for_status()
    return response.json()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
) -> CurrentUser:
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='Missing bearer token',
        )

    token = credentials.credentials

    try:
        payload = decode_supabase_token(token)
        return CurrentUser(
            user_id=str(payload.get('sub')),
            email=payload.get('email'),
            role=payload.get('role'),
        )
    except InvalidTokenError:
        pass

    try:
        user_data = await fetch_supabase_user(token)
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='Invalid token',
        ) from exc

    return CurrentUser(
        user_id=str(user_data.get('id') or user_data.get('sub')),
        email=user_data.get('email'),
        role=user_data.get('role'),
    )


async def require_superadmin(user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
    if (user.email or '').lower() not in settings.superadmin_email_set:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail='Admin access required',
        )
    return user

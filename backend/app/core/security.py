from dataclasses import dataclass

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


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
) -> CurrentUser:
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='Missing bearer token',
        )

    try:
        payload = decode_supabase_token(credentials.credentials)
    except InvalidTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='Invalid token',
        ) from exc

    return CurrentUser(
        user_id=str(payload.get('sub')),
        email=payload.get('email'),
        role=payload.get('role'),
    )


async def require_superadmin(user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
    if (user.email or '').lower() not in settings.superadmin_email_set:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail='Admin access required',
        )
    return user

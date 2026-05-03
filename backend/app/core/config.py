from functools import lru_cache

from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        case_sensitive=False,
    )

    app_env: str = Field(default='development', alias='APP_ENV')
    api_v1_prefix: str = Field(default='/api/v1', alias='API_V1_PREFIX')
    project_name: str = Field(default='VibeTrack API', alias='PROJECT_NAME')
    auto_create_tables: bool = Field(default=True, alias='APP_AUTO_CREATE_TABLES')
    cors_origins: str = Field(default='', alias='BACKEND_CORS_ORIGINS')
    database_url: str = Field(..., alias='DATABASE_URL')
    redis_url: str = Field(default='redis://localhost:6379/0', alias='REDIS_URL')
    supabase_url: str = Field(..., alias='SUPABASE_URL')
    supabase_anon_key: str | None = Field(default=None, alias='SUPABASE_ANON_KEY')
    supabase_jwt_issuer_override: str | None = Field(
        default=None,
        alias='SUPABASE_JWT_ISSUER',
    )
    supabase_jwt_audience: str = Field(
        default='authenticated',
        alias='SUPABASE_JWT_AUDIENCE',
    )
    supabase_jwks_url_override: str | None = Field(
        default=None,
        alias='SUPABASE_JWKS_URL',
    )
    superadmin_emails: str = Field(default='', alias='SUPERADMIN_EMAILS')
    google_application_credentials: str | None = Field(
        default=None,
        alias='GOOGLE_APPLICATION_CREDENTIALS',
    )
    fcm_project_id: str | None = Field(default=None, alias='FCM_PROJECT_ID')
    fcm_client_email: str | None = Field(default=None, alias='FCM_CLIENT_EMAIL')
    fcm_private_key: str | None = Field(default=None, alias='FCM_PRIVATE_KEY')

    @computed_field
    @property
    def supabase_jwt_issuer(self) -> str:
        if self.supabase_jwt_issuer_override:
            return self.supabase_jwt_issuer_override
        return f'{self.supabase_url.rstrip("/")}/auth/v1'

    @computed_field
    @property
    def supabase_jwks_url(self) -> str:
        if self.supabase_jwks_url_override:
            return self.supabase_jwks_url_override
        return f'{self.supabase_jwt_issuer}/.well-known/jwks.json'

    @computed_field
    @property
    def supabase_userinfo_url(self) -> str:
        return f'{self.supabase_jwt_issuer}/user'

    @property
    def superadmin_email_set(self) -> set[str]:
        return {
            email.strip().lower()
            for email in self.superadmin_emails.split(',')
            if email.strip()
        }

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(',') if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()

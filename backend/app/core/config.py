from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env', env_file_encoding='utf-8', case_sensitive=False)

    app_env: str = Field(default='development', alias='APP_ENV')
    api_v1_prefix: str = Field(default='/api/v1', alias='API_V1_PREFIX')
    project_name: str = Field(default='VibeTrack API', alias='PROJECT_NAME')
    database_url: str = Field(..., alias='DATABASE_URL')
    redis_url: str = Field(default='redis://localhost:6379/0', alias='REDIS_URL')
    supabase_url: str = Field(..., alias='SUPABASE_URL')
    supabase_jwt_issuer: str = Field(..., alias='SUPABASE_JWT_ISSUER')
    supabase_jwt_audience: str = Field(default='authenticated', alias='SUPABASE_JWT_AUDIENCE')
    supabase_jwks_url: str = Field(..., alias='SUPABASE_JWKS_URL')
    superadmin_emails: str = Field(default='', alias='SUPERADMIN_EMAILS')
    fcm_project_id: str | None = Field(default=None, alias='FCM_PROJECT_ID')
    fcm_client_email: str | None = Field(default=None, alias='FCM_CLIENT_EMAIL')
    fcm_private_key: str | None = Field(default=None, alias='FCM_PRIVATE_KEY')

    @property
    def superadmin_email_set(self) -> set[str]:
        return {email.strip().lower() for email in self.superadmin_emails.split(',') if email.strip()}


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()

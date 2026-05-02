# Backend Deployment Notes

## Current Shape

- Flutter uses Supabase Auth for login/session.
- Flutter sends the Supabase bearer token to FastAPI when `BACKEND_API_URL` is set.
- FastAPI verifies the token and stores app data in Neon Postgres.
- Firebase Cloud Messaging is wired for Android notifications.
- Supabase Storage is still used for post media uploads.

## Local API

Run from `backend/`:

```bash
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --app-dir .
```

Use these Flutter defines for local testing:

```json
{
  "APP_MODE": "dev",
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key",
  "SUPABASE_REDIRECT_URL": "vibetreck://login-callback",
  "BACKEND_API_URL": "http://127.0.0.1:8001",
  "BACKEND_API_URL_ANDROID": "http://10.0.2.2:8001"
}
```

For a physical Android device, use your computer LAN IP for `BACKEND_API_URL_ANDROID`, or run:

```bash
adb reverse tcp:8001 tcp:8001
```

## Production API

Set backend host environment variables:

```env
APP_ENV=production
API_V1_PREFIX=/api/v1
PROJECT_NAME=VibeTrack API
APP_AUTO_CREATE_TABLES=false
DATABASE_URL=postgresql+asyncpg://USER:PASSWORD@NEON_HOST/neondb?sslmode=require&channel_binding=require
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_JWT_AUDIENCE=authenticated
SUPERADMIN_EMAILS=admin@example.com
GOOGLE_APPLICATION_CREDENTIALS=backend/secrets/firebase-service-account.json
```

Production start command:

```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT --app-dir .
```

Then build Flutter with the live API URL:

```json
{
  "APP_MODE": "production",
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key",
  "SUPABASE_REDIRECT_URL": "vibetreck://login-callback",
  "BACKEND_API_URL": "https://api.your-domain.com",
  "BACKEND_API_URL_ANDROID": "https://api.your-domain.com"
}
```

## Before Production

- Add Alembic migrations before using `APP_AUTO_CREATE_TABLES=false`.
- Keep local and production Neon databases separate.
- Store Firebase service account JSON as a host secret, not in git.
- Use HTTPS for `BACKEND_API_URL` in production.
- Keep Supabase Auth and Firebase project IDs matched with the app build.

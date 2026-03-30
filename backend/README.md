# VibeTrack Backend

FastAPI modular-monolith backend for the VibeTrack mobile app and future admin panel.

## Why this shape

We are keeping the backend as a modular monolith first:
- fast to build and run locally
- clear module boundaries for future extraction
- easier for a small team than premature microservices
- ready for Postgres, Redis, background jobs, and WebSockets later

This backend is designed to:
- keep Supabase Auth as the identity provider for now
- verify Supabase JWTs on our own API
- move business logic out of Flutter and into server-side APIs
- support a future Next.js admin panel

## Planned stack

- FastAPI
- SQLAlchemy async
- Neon Postgres / PostGIS
- Redis later for caching and ephemeral ride state
- FCM later for notifications
- WebSockets later for live ride sharing

## What backend needs from you

### Required now
- `SUPABASE_URL`
- `DATABASE_URL`

### Optional now
- `SUPABASE_ANON_KEY`
- `SUPERADMIN_EMAILS`

### Needed later for push notifications
- `FCM_PROJECT_ID`
- `FCM_CLIENT_EMAIL`
- `FCM_PRIVATE_KEY`

### Needed later for Redis
- `REDIS_URL`

Notes:
- The backend does **not** need the frontend redirect URL
- The backend can derive JWT issuer and JWKS URL from `SUPABASE_URL`
- The backend usually does **not** need the Supabase anon key for token verification
- In development, the app auto-creates the current SQLAlchemy tables on startup when `APP_AUTO_CREATE_TABLES=true`

## Local setup

1. Install Python 3.11+
2. Create a virtual environment
3. Install dependencies

```bash
pip install -e .[dev]
```

4. Copy env file

```bash
copy .env.example .env
```

5. Fill in at least:
- `SUPABASE_URL`
- `DATABASE_URL`

6. Run the server

```bash
uvicorn app.main:app --reload --app-dir .
```

## Current DB-backed routes

- `GET /api/v1/health`
- `GET /api/v1/ready`
- `GET /api/v1/auth/me`
- `GET /api/v1/config/bootstrap`
- `GET /api/v1/profiles/me`
- `PUT /api/v1/profiles/me`
- `POST /api/v1/rides/sessions/start`
- `POST /api/v1/rides/sessions/finish`
- `GET /api/v1/rides/sessions/mine`
- `GET /api/v1/feed/posts`
- `POST /api/v1/feed/posts`

Routes below still exist as scaffold only:
- `GET /api/v1/zones`
- `POST /api/v1/zones/{zone_id}/claim`
- `POST /api/v1/notifications/device-token`
- `GET /api/v1/admin/overview`

## Next backend milestones

1. Alembic migrations and production-safe schema management
2. Ride points / route chunking for long sessions
3. Feed likes/comments and moderation
4. FCM device token management
5. Admin auth and audit logs
6. WebSocket live ride service
7. Flutter app migration from direct Supabase repositories to backend API adapters

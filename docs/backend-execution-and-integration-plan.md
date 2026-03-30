# Backend Execution And Integration Plan

## Current Runtime Status

### Backend API
- Backend scaffold exists under `backend/`
- Local API is **not runnable yet in this shell** because `python` and `py` are not available on PATH
- FastAPI files, router tree, config, auth middleware, and CI scaffold are created
- Database models, migrations, and real persistence are **not implemented yet**

### Supabase
- Supabase is currently the active identity and data backend in the Flutter app
- Current app directly uses Supabase for:
  - auth
  - profile reads/writes
  - session storage
  - feed storage
  - zones storage
  - media upload
- This means the app is **not yet switched to backend APIs**

### Firebase / FCM
- Firebase is **not integrated yet**
- No FCM SDK setup exists in the Flutter app
- No backend FCM sending service exists yet

## What Works Right Now
- Flutter app auth via Supabase
- Profile bootstrap after login
- Local GPS tracking in app
- Session save to Supabase
- Overlay generation in app
- Media upload to Supabase Storage
- Feed and zone reads from Supabase

## What Does Not Exist Yet
- FastAPI running locally
- Neon database connection in backend runtime
- backend-owned profile/session/post services
- Redis caching layer
- WebSocket live session service
- GraphQL layer
- FCM push pipeline
- admin panel UI
- admin audit/moderation APIs
- app integration through backend REST APIs

## Recommended Service Design

Keep a modular monolith backend first.

### Modules
- `auth`
  - verify Supabase JWT
  - expose `me`
  - admin guard
- `profiles`
  - current profile
  - profile update
  - follower counts later
- `rides`
  - start ride
  - ingest route points
  - pause/resume/finish
  - ride history
  - ride detail
- `feed`
  - posts
  - likes
  - comments
  - share/deep link metadata
- `zones`
  - list zones
  - claim validation
  - leaderboard logic later
- `notifications`
  - register device token
  - notification history
- `admin`
  - overview metrics
  - user lookup
  - moderation
  - reports
  - support/audit later
- `config`
  - feature flags
  - app config
  - theme config later
- `analytics`
  - event ingestion
  - operational metrics later

## API Style Decision

### Use REST first
Use REST for:
- auth bootstrap
- profile
- rides
- feed
- zones
- notifications
- admin

Why:
- simpler mobile integration
- easier debugging
- cleaner versioning
- better for solo development right now

### Add WebSockets later
Use WebSockets only for:
- live ride sharing
- live follower presence
- live event participation
- admin live activity dashboards if needed

### Do not add GraphQL now
GraphQL is not needed yet.
Add it only later if:
- app has many combined read screens
- admin dashboard needs complex composed read models
- REST payload duplication becomes painful

Recommended rule:
- writes = REST
- live = WebSockets
- complex read composition later = optional GraphQL read layer

## Caching And Query Strategy

### Phase 1
- no Redis required for MVP
- use Postgres directly
- query by indexed columns only
- paginate feed and ride history

### Phase 2
Add Redis for:
- feed cache
- leaderboard cache
- active ride session state
- rate limiting
- notification fanout queues

### Kafka
Do not add Kafka now.
Add only when event throughput and async workloads become substantial.
Before Kafka, use:
- DB-backed jobs or Redis queue
- background workers

## Database Plan

### Short term
- continue Supabase DB for current app until backend persistence is ready
- backend can connect to the same Postgres-compatible database if desired

### Better medium-term
- move backend to Neon Postgres/PostGIS
- backend becomes source of truth for business data
- Supabase remains auth only during transition

### First backend-owned tables
- profiles
- ride_sessions
- ride_points or route_segments
- posts
- post_likes
- post_comments
- zones
- zone_claim_events
- device_tokens
- audit_logs

## Flutter Integration Migration Plan

### Current app state management
- Riverpod
- repositories directly using Supabase

### Target integration shape
Add API client layer:
- `lib/core/network/api_client.dart`
- `lib/core/network/auth_token_provider.dart`
- `lib/core/network/api_exception.dart`

Then split repositories into:
- app repository interface
- Supabase legacy adapter
- backend API adapter

Example:
- `ProfileRepository`
  - `SupabaseProfileRepository` now
  - `ApiProfileRepository` next

### HTTP stack
Use:
- `dio`
- auth interceptor to attach Supabase access token to backend calls
- retry policy for network failures
- offline-safe queue later for ride uploads/post publish

## Login And Session Flow

### Current
- app signs in with Supabase
- app reads/writes Supabase directly

### Target
1. app signs in with Supabase
2. app gets Supabase access token
3. app calls backend REST APIs with bearer token
4. backend verifies JWT with Supabase JWKS
5. backend performs business logic and DB writes
6. backend returns normalized API responses

This keeps login simple while moving control to our backend.

## Ride Tracking Flow

### Current
- tracking and metric calculation happen fully inside Flutter
- session is written directly to Supabase on finish

### Target
1. app starts local ride tracking
2. app buffers points locally during ride
3. pause/resume stays local-first
4. on finish, app uploads summary + route batch to backend
5. backend validates, stores, computes canonical stats
6. backend awards aura / achievements
7. backend prepares feed-ready response

### Later for live rides
- app opens WebSocket during active ride
- sends lightweight live location updates every few seconds
- backend stores live state in Redis
- followers subscribe to live ride stream

## Notifications Plan

Use FCM for Android.

### App side later
- add `firebase_core`
- add `firebase_messaging`
- request notification permissions
- register token with backend

### Backend side later
- store device tokens
- send push notifications through FCM service account
- notification types:
  - like
  - comment
  - follower activity
  - zone lost
  - event reminder
  - admin announcement

## Admin Panel Timing

Do not start full admin panel right now.

### Add admin backend APIs first
Needed first:
- admin auth guard
- user lookup
- ride lookup
- feed post lookup
- overview metrics
- audit log primitives

### Add admin UI after that
Build admin UI in Next.js after:
- profile APIs exist
- ride APIs exist
- feed moderation APIs exist
- audit log exists

Recommended order:
1. backend auth + profiles + rides + feed
2. backend admin overview + user lookup APIs
3. basic Next.js admin panel

## Immediate Next Implementation Steps

1. Get Python 3.11 working locally
2. Run FastAPI app locally
3. Add SQLAlchemy models and Alembic
4. Connect Neon DB
5. Implement backend `profiles` module with real persistence
6. Implement backend `rides` module with real persistence
7. Implement backend `feed` module with real persistence
8. Add Dio API client in Flutter
9. Move Flutter repositories from direct Supabase access to backend REST adapters
10. Add FCM later after core app API flow is stable

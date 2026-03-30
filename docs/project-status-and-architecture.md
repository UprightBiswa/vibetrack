# VibeTrack Status And Architecture Plan

## 1. Product Direction

VibeTrack is a cycling-first social fitness app.

Core product idea:
- track rides, runs, and walks
- turn rides into shareable social posts
- support community competition, zones, leaderboards, and events
- grow later into a full cycling ecosystem with notifications, subscriptions, clubs, events, admin tooling, and analytics

Primary product identity:
- mobile-first
- community-focused
- cycling-specialized
- social validation and beautiful post-sharing

## 2. Current Implementation Status

The current app is an MVP shell with real feature wiring, not a full production platform yet.

What is working now:
- Flutter app shell with Riverpod and GoRouter
- Supabase auth repository for email/password and Google OAuth
- profile bootstrap after auth
- GPS tracking flow with start, pause, resume, finish
- route metrics calculation in app
- session save flow
- summary overlay generation
- post creation flow
- feed read and like flow
- zones read and claim contract
- Supabase schema and edge-function stubs
- fallback local repositories for non-configured mode

What is partially implemented:
- storage upload flow exists but needs stronger storage/RLS policy handling
- feed interactions exist but moderation and concurrency handling are minimal
- zone claim architecture exists but still needs stronger backend validation
- offline/network awareness exists at app shell level, but full sync system is not built

What is not production-ready yet:
- background ride recording
- reliable ride persistence across app kill/restart
- ride history and activity detail system
- comments system end-to-end
- followers/following graph
- live ride sharing via WebSockets
- notifications and FCM integration
- admin APIs and admin dashboard
- support tooling and audit logs
- analytics and monitoring
- subscription/paywall
- dynamic app configuration / feature flags
- moderation and report review tools

## 3. Current Technical Shape

Current app architecture:
- frontend: Flutter
- state/routing: Riverpod + GoRouter
- auth/data backend: Supabase
- maps: `flutter_map` with OpenStreetMap
- tracking: Geolocator
- media upload: Supabase Storage

Important current code areas:
- app bootstrap: [main.dart](d:\\vibetreck\\lib\\main.dart)
- app shell and profile bootstrap: [app.dart](d:\\vibetreck\\lib\\app.dart)
- environment config: [app_env.dart](d:\\vibetreck\\lib\\core\\config\\app_env.dart)
- repository wiring: [repositories.dart](d:\\vibetreck\\lib\\core\\providers\\repositories.dart)
- auth implementation: [auth_repository.dart](d:\\vibetreck\\lib\\features\\auth\\data\\auth_repository.dart)
- tracking logic: [tracking_controller.dart](d:\\vibetreck\\lib\\features\\tracking\\application\\tracking_controller.dart)
- feed repository: [feed_repository.dart](d:\\vibetreck\\lib\\features\\feed\\data\\feed_repository.dart)
- media upload: [media_upload_service.dart](d:\\vibetreck\\lib\\shared\\services\\media_upload_service.dart)
- database schema: [schema.sql](d:\\vibetreck\\supabase\\schema.sql)

## 4. Recommended Platform Direction

Recommendation: move to a hybrid architecture.

Use:
- Flutter app for user mobile experience
- custom Python backend as the core business system
- Supabase only where it still helps short-term
- Postgres as main database
- Redis later for cache/live session state
- FCM for notifications
- Next.js admin panel

Recommended backend choice:
- FastAPI over Django

Why FastAPI:
- better fit for API-first mobile backend
- faster to iterate as a solo or small team
- async-friendly
- easy to structure into modular services
- easier path for WebSockets later
- cleaner for a service-oriented backend than Django for this product

Why not Go first:
- Go is excellent for long-term performance, but product iteration is slower
- your current need is system clarity and shipping velocity more than raw runtime optimization

## 5. Target Architecture

### 5.1 High-level system

User app:
- Flutter
- BLoC + clean architecture target
- Dio for REST APIs later
- WebSockets for live ride sharing later
- local persistence for drafts, unsynced rides, and cached feed

Backend:
- FastAPI monolith first
- modular domain structure
- REST first
- WebSockets only for live features
- background workers for notifications, analytics, leaderboards, event jobs

Admin:
- Next.js + React + TypeScript
- talks only to backend APIs, not directly to app tables

Data:
- Postgres + PostGIS
- Redis later
- object storage for post media and activity assets

Notifications:
- FCM for Android
- APNs later for iOS

Analytics and support:
- audit logs
- crash reporting
- server event logs
- admin activity tools

### 5.2 Monolith first, microservices later

Start with a modular monolith, not microservices.

Reason:
- easier to develop and debug
- easier local development
- simpler deployment
- much better for a solo or small team
- still allows later extraction of services like notifications, analytics, live tracking, or billing

Future extraction candidates:
- notification worker
- activity analytics pipeline
- live session service
- billing/subscription service

## 6. Backend Domain Modules

Recommended backend modules:
- `auth`
- `users`
- `profiles`
- `activities`
- `activity_points`
- `feed`
- `comments`
- `likes`
- `follows`
- `zones`
- `events`
- `leaderboards`
- `notifications`
- `media`
- `admin`
- `reports`
- `analytics`
- `config`
- `subscriptions`
- `audit`

## 7. Recommended API Strategy

Use:
- REST for most app and admin flows
- WebSockets for live tracking and live presence later
- GraphQL only if a real cross-screen data composition problem appears

Recommendation:
- do not start with GraphQL
- build a clean REST API first
- if admin or app becomes data-shape heavy later, add GraphQL as a read layer only

## 8. Authentication Strategy

Short-term:
- keep Supabase Auth if it is already working and saves time

Medium-term:
- move all business logic behind custom backend APIs
- backend validates auth token and becomes the only business gateway

Long-term options:
- keep Supabase Auth permanently and validate JWTs in backend
- or migrate later to custom auth/identity provider if business needs require it

Recommended now:
- keep Supabase Auth for identity
- custom backend owns business logic, ride logic, admin, notifications, analytics, and config

## 9. Current User Flow vs Target User Flow

### 9.1 Current flow

1. user opens app
2. app checks auth state
3. user logs in
4. app creates or loads profile
5. user starts tracking
6. GPS points are collected in memory
7. user pauses/resumes/stops
8. app computes ride summary
9. app generates social overlay
10. app uploads image
11. app creates feed post
12. feed and zones read from backend

### 9.2 Target production flow

1. app starts
2. auth/session restored from secure storage
3. app fetches config + user state + pending sync jobs
4. if ride in progress, restore it
5. start ride
6. GPS points stream to local persistent store
7. if network is available, batch sync periodically
8. on pause/resume, state is persisted locally and mirrored to backend
9. on finish, ride summary is finalized by backend
10. backend validates ride quality and computes stats
11. media uploads complete
12. post is created
13. followers get notifications
14. ride appears in feed/leaderboard/profile/history

## 10. GPS And Ride Tracking Plan

Current state:
- GPS is managed in the app controller
- points are stored in memory
- ride summary is computed client-side

Production plan:
- store active ride state locally with persistent storage
- write route points in chunks, not only memory
- add background/foreground tracking strategy for Android
- use batching for route uploads
- add low-network sync retry queue
- validate pace, speed, route anomalies on backend
- add crash recovery for active sessions

Ride state model should include:
- `draft`
- `recording`
- `paused`
- `syncing`
- `uploaded`
- `failed`
- `published`

## 11. Notifications Plan

Use FCM.

Need:
- device token registration table
- notification preferences
- notification delivery log
- templates for like/comment/follow/zone/event
- background worker to send notifications

Notification categories later:
- social
- ride/live
- zone/leaderboard
- event/community
- product/system
- admin/support

## 12. Admin Panel Scope

The admin panel should be a separate web app.

Admin capabilities:
- search users
- inspect profiles and sessions
- inspect posts/comments/reports
- flag suspicious rides
- moderate feed content
- manage zones/events/challenges
- send notification campaigns
- manage feature flags and banners
- inspect app errors and support logs
- review subscription status later

## 13. Suggested Database Evolution

Current core tables already present:
- `profiles`
- `sessions`
- `posts`
- `post_likes`
- `post_comments`
- `zones`
- `zone_claim_events`

Add next:
- `activity_points`
- `notification_tokens`
- `notifications`
- `follows`
- `reports`
- `admin_users`
- `audit_logs`
- `app_config`
- `feature_flags`
- `events`
- `event_participants`
- `subscriptions`
- `support_tickets`

## 14. Suggested Database ER View

High-level relationships:

- user/auth -> profile
- profile -> sessions
- session -> activity_points
- profile -> posts
- post -> likes
- post -> comments
- profile -> follows -> profile
- session -> zone_claim_events -> zones
- profile -> notification_tokens
- profile -> notifications
- profile -> reports
- admin_users -> audit_logs
- events -> event_participants -> profiles

## 15. Data Flow Diagram Summary

### Login flow
- Flutter app -> Supabase Auth
- Supabase Auth -> token
- Flutter app -> backend API with token
- backend -> profile lookup/create
- backend -> app config + user bootstrap

### Tracking flow
- GPS sensor -> Flutter tracking service
- tracking service -> local draft ride store
- local ride store -> backend sync API
- backend -> Postgres/PostGIS
- backend -> derived stats/leaderboards/zone logic

### Publish flow
- summary screen -> media upload
- media upload -> storage
- app -> backend create-post API
- backend -> feed tables + follower notifications

### Admin flow
- admin UI -> admin API
- admin API -> data store + audit log

## 16. Architecture Direction For Flutter

Recommended move:
- standardize on BLoC + Clean Architecture

Suggested structure per feature:
- `presentation/bloc`
- `presentation/pages`
- `presentation/widgets`
- `domain/entities`
- `domain/repositories`
- `domain/usecases`
- `data/models`
- `data/datasources`
- `data/repositories`

Current app uses Riverpod. That is workable, but if you want the architecture to be enterprise-clean and consistent with your stated goal, moving to BLoC is reasonable.

Important recommendation:
- do not mix BLoC, MVVM, and ad-hoc Riverpod patterns everywhere
- choose one main architecture and apply it consistently

## 17. Immediate Implementation Plan

Phase 1: document and freeze architecture
- confirm backend direction: FastAPI modular monolith
- confirm auth direction: Supabase Auth + backend validation
- confirm map/tracking direction

Phase 2: scaffold backend
- create `backend/` FastAPI project
- add config, health route, auth middleware, API versioning
- add database connection via remote Postgres URL
- add SQLAlchemy or SQLModel models
- add Alembic migrations

Phase 3: move app business flow behind API
- auth bootstrap endpoint
- profile endpoints
- session create/update/finish endpoints
- feed list/create endpoints
- media upload contract
- zone claim endpoints

Phase 4: add local persistence and sync
- draft ride local storage
- offline queue
- retry rules

Phase 5: add notifications and admin APIs
- FCM integration
- admin auth
- moderation and analytics endpoints

## 18. Current Risks

Main current risks:
- business logic is still split between app and backend in an MVP way
- storage policies are not fully hardened
- ride tracking is not yet resilient enough for real cycling use
- admin and support visibility are missing
- comments/follows/notifications are not yet complete product loops

## 19. Recommended Next Step

The best next move is:
- create the FastAPI backend skeleton now
- keep Supabase Auth temporarily
- move all ride/feed/zone business logic to backend APIs
- start a real architecture migration rather than adding more features directly into the current MVP shell

That gives you:
- cleaner long-term system
- easier admin panel integration
- easier notifications and analytics
- easier future replacement of Supabase parts if needed

## 13. Backend Scaffold Implemented On 2026-03-30

A new backend foundation now exists under `backend/`.

Implemented now:
- FastAPI modular-monolith project scaffold
- environment-driven config via `pydantic-settings`
- structured logging bootstrap via `structlog`
- async SQLAlchemy engine/session factory
- Supabase JWT verification middleware using JWKS
- superadmin guard based on configured email allow-list
- API router tree for:
  - health
  - auth
  - config
  - profiles
  - rides
  - feed
  - zones
  - notifications
  - admin
- GitHub Actions backend CI scaffold

Current backend files:
- `backend/pyproject.toml`
- `backend/.env.example`
- `backend/README.md`
- `backend/app/main.py`
- `backend/app/core/config.py`
- `backend/app/core/logging.py`
- `backend/app/core/database.py`
- `backend/app/core/security.py`
- `backend/app/api/v1/router.py`
- `backend/app/modules/**/router.py`
- `.github/workflows/backend-ci.yml`

Important note:
- Python is not currently available in the local shell environment, so the backend scaffold was created but not yet executed locally in this session.
- Next technical prerequisite is installing Python 3.11+ or fixing PATH access to Python.

## 14. Next Backend Steps

1. Install Python locally and run the backend scaffold
2. Add SQLAlchemy models and Alembic migrations
3. Connect Neon Postgres and create first persisted modules:
   - profiles
   - ride sessions
   - feed posts
4. Add service layer and repository layer inside backend
5. Move Flutter data access from direct Supabase tables to backend APIs
6. Add device token persistence and FCM delivery service
7. Add audit logs, admin metrics, and report moderation
8. Add Redis-backed caching and live ride session state
9. Add WebSocket live ride channels

## 15. Backend Persistence Slice Implemented On 2026-03-30

The backend is no longer only a scaffold.

Implemented now:
- shared SQLAlchemy base and timestamp mixin
- automatic dev-time table creation via `APP_AUTO_CREATE_TABLES=true`
- Neon connection normalization for async SQLAlchemy + `asyncpg`
- DB-backed `profiles` module
- DB-backed `rides` module
- DB-backed `feed` module

Current persisted tables:
- `profiles`
- `ride_sessions`
- `feed_posts`

Current backend runtime verification completed:
- backend imports successfully
- Neon query succeeds
- FastAPI server responds on `/api/v1/health`
- core tables exist in Neon
- backend lint passes with Ruff

What is still scaffold-only:
- zones
- notifications
- admin overview
- analytics

Next recommended implementation order:
1. likes/comments and richer feed actions
2. ride point chunk storage and activity detail retrieval
3. Dio-based Flutter API client and backend repository adapters
4. FCM device token registration + push delivery service
5. admin APIs and moderation/audit layer
6. WebSocket live ride service

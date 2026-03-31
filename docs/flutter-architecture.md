# Flutter App Architecture Direction

The Flutter app is standardized around one approach:
- Riverpod for state management and dependency wiring
- GoRouter for navigation
- repository interfaces for data access
- Dio for backend REST integration
- Supabase for auth/session only

## Chosen direction

We are **not** mixing:
- BLoC
- GetX
- MVVM layers on top of Riverpod

That combination would add complexity without improving delivery.

Instead, the app follows a practical clean architecture shape:
- `core/`
  - environment config
  - routing
  - network client
  - logging
  - theme
- `features/`
  - presentation
  - application/controller
  - data/repository
- `shared/`
  - models
  - services
  - reusable widgets

## Data flow

1. User signs in with Supabase
2. App reads access token from current Supabase session
3. Dio attaches bearer token to backend requests
4. Backend verifies token and reads/writes Neon data
5. Repository adapters map API payloads into app models

## Current backend-backed features
- profile get/update
- public profile read by id
- ride session create/get
- feed list/create/like
- zones list/claim

## Still on fallback path for now
- notifications
- admin features
- live sockets
- GraphQL read layer

## Next Flutter milestones
1. Add explicit repository tests for API adapters
2. Add background/offline ride sync queue
3. Add WebSocket client for live ride sharing
4. Add FCM token registration and notification handling
5. Add notifications/admin API adapters when backend modules are ready

## Done For Now

The current Flutter baseline is considered stable for the implemented feature set.

Implemented now:
- Riverpod + GoRouter app shell
- shared route constants
- shared theme and shell widgets
- Dio backend client
- auth token attachment from Supabase session
- connectivity-aware API calls
- shared API error mapping/logging
- backend-backed repositories for profile, rides, feed, and zones
- edit profile screen wired to backend update API
- public profile screen reachable from the feed

Deferred to later phases:
- BLoC/GetX rewrite
- GraphQL client
- WebSocket client
- offline DB and sync engine
- dynamic runtime theming
- admin UI flows


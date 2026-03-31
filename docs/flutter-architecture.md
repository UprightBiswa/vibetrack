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
- profile
- ride session create/get
- feed list/create/like

## Still on fallback path for now
- zones
- notifications
- admin features
- live sockets
- GraphQL read layer

## Next Flutter milestones
1. Add explicit repository tests for API adapters
2. Add background/offline ride sync queue
3. Add WebSocket client for live ride sharing
4. Add FCM token registration and notification handling
5. Add zones API adapter when backend module is ready

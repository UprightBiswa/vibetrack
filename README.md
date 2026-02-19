# VibeTrack

Urban fitness + social validation app MVP in Flutter.

## Stack
- Flutter + Riverpod + GoRouter
- Supabase (Auth, Postgres/PostGIS, Storage, Edge Functions)
- Geolocator + Mapbox

## Implemented MVP Flow
- Auth (email/password, local fallback mode)
- Home dashboard with Cyber-Bento cards
- Live tracking session start/pause/resume/finish
- Session summary + 3 overlay templates
- Overlay export and post creation
- Feed with likes/comment-lite counters
- Zone listing + claim action contract
- Profile + settings

## Run
```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=MAPBOX_PUBLIC_TOKEN=YOUR_MAPBOX_TOKEN
```

If env vars are not provided, app runs in local demo mode (mock auth/data).

## Supabase Setup
1. Run SQL in `supabase/schema.sql`.
2. Create a public storage bucket named `posts`.
3. Deploy edge functions:
   - `supabase/functions/award-aura/index.ts`
   - `supabase/functions/claim-zone/index.ts`

## Tests
```bash
flutter analyze
flutter test
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

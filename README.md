# VibeTrack

Urban fitness + social validation app MVP in Flutter.

## Stack
- Flutter + Riverpod + GoRouter
- Supabase Auth + Storage
- FastAPI + Neon Postgres for app business APIs
- Geolocator + flutter_map (OpenStreetMap)

## Current App/Backend Split
- Supabase: login/session identity, Google sign-in, storage uploads
- FastAPI backend: profiles, rides, feed APIs
- Neon: backend-owned data for profiles, ride sessions, and feed posts

## Implemented MVP Flow
- Auth (email/password, Google OAuth, local fallback mode)
- Home dashboard with Cyber-Bento cards
- Live tracking session start/pause/resume/finish
- Session summary + 3 overlay templates
- Overlay export and post creation
- Feed with likes/comment-lite counters
- Zone listing + claim action contract
- Profile + settings
- Backend API integration for profile, ride session, and feed flows when `BACKEND_API_URL` is configured

## Run
```bash
flutter pub get
flutter run \
  --dart-define=APP_MODE=dev \
  --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=SUPABASE_REDIRECT_URL=vibetreck://login-callback \
  --dart-define=BACKEND_API_URL=http://YOUR_MACHINE_IP:8001
```

Production run (recommended):
```bash
flutter run --release --dart-define-from-file=env.production.json
```

Create your `env.production.json` from `env.example.json`.

If env vars are not provided, app runs in local demo mode (mock auth/data).

## Backend API URL Notes
- Android emulator: `http://10.0.2.2:8001`
- Physical Android device: `http://YOUR_COMPUTER_LAN_IP:8001`
- iOS simulator: `http://127.0.0.1:8001`

## Supabase Setup
1. Run SQL in `supabase/schema.sql`.
2. Create a public storage bucket named `posts`.
3. Deploy edge functions if you still use the Supabase-only fallback path:
   - `supabase/functions/award-aura/index.ts`
   - `supabase/functions/claim-zone/index.ts`
4. Add OAuth redirect URL in Supabase Auth:
   - `vibetreck://login-callback`

## Backend Setup
1. Go to `backend/`
2. Copy `.env.example` to `.env`
3. Fill in `SUPABASE_URL` and `DATABASE_URL`
4. Run:
```bash
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --app-dir .
```

## Tests
```bash
flutter analyze
flutter test
```

## Supabase Storage SQL
Use a public `posts` bucket for post media uploads.

```sql
insert into storage.buckets (id, name, public)
values ('posts', 'posts', true)
on conflict (id) do nothing;

create policy "Authenticated users can upload post media"
on storage.objects for insert
to authenticated
with check (bucket_id = 'posts');

create policy "Public can read post media"
on storage.objects for select
to public
using (bucket_id = 'posts');
```

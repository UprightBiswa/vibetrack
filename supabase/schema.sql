create extension if not exists postgis;

create table if not exists profiles (
  id uuid primary key,
  username text not null default '',
  avatar_url text not null default '',
  aura_points int not null default 0,
  home_city text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists sessions (
  id text primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  type text not null,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  distance_m double precision not null default 0,
  duration_s int not null default 0,
  avg_pace double precision not null default 0,
  calories int not null default 0,
  route_geojson jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists posts (
  id text primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  session_id text references sessions(id) on delete set null,
  image_url text not null default '',
  caption text not null default '',
  stats_json jsonb not null default '{}'::jsonb,
  like_count int not null default 0,
  comment_count int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists post_likes (
  post_id text not null references posts(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists post_comments (
  id bigserial primary key,
  post_id text not null references posts(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists zones (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  polygon geometry(polygon, 4326) not null,
  city text not null,
  score_multiplier double precision not null default 1.0,
  current_guardian_user_id uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists zone_claim_events (
  id bigserial primary key,
  zone_id uuid not null references zones(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  session_id text not null references sessions(id) on delete cascade,
  aura_awarded int not null,
  created_at timestamptz not null default now()
);

create materialized view if not exists leaderboard_weekly as
select
  p.id as user_id,
  p.username,
  coalesce(sum(zce.aura_awarded), 0) as week_aura
from profiles p
left join zone_claim_events zce
  on zce.user_id = p.id
  and zce.created_at >= date_trunc('week', now())
group by p.id, p.username;

create or replace function increment_user_aura(user_id uuid, delta int)
returns void
language sql
security definer
as $$
  update profiles
  set aura_points = greatest(aura_points + delta, 0)
  where id = user_id;
$$;

create or replace function route_intersects_zone(route_geojson jsonb, zone_id uuid)
returns boolean
language sql
security definer
as $$
  select st_intersects(
    st_setsrid(st_geomfromgeojson(route_geojson::text), 4326),
    (select polygon from zones where id = zone_id)
  );
$$;

alter table profiles enable row level security;
alter table sessions enable row level security;
alter table posts enable row level security;
alter table post_likes enable row level security;
alter table post_comments enable row level security;
alter table zones enable row level security;
alter table zone_claim_events enable row level security;

create policy "public feed read"
  on posts for select using (true);

create policy "public zones read"
  on zones for select using (true);

create policy "own profile read write"
  on profiles for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "own session read write"
  on sessions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "own post write"
  on posts for insert
  with check (auth.uid() = user_id);

create policy "own post update delete"
  on posts for update using (auth.uid() = user_id);

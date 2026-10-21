-- Picture catalogue for the puzzle app: topics (chủ đề) contain pictures.
-- Metadata lives in public.topics and public.pictures; image bytes live in the public "pictures" bucket.
-- The backend writes with the service role key (bypasses RLS). Clients never touch these
-- tables directly: they read through GET /api/topics.

create table if not exists public.topics (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(name) between 1 and 40),
  position   integer not null default 0,
  active     boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists topics_active_position_idx
  on public.topics (active, position, created_at);

create table if not exists public.pictures (
  id           uuid primary key default gen_random_uuid(),
  topic_id     uuid not null references public.topics (id) on delete cascade,
  position     integer not null default 0,
  active       boolean not null default true,
  storage_path text not null unique,
  content_type text not null,
  bytes        integer not null check (bytes > 0),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists pictures_topic_position_idx
  on public.pictures (topic_id, position, created_at);

-- RLS on and no policies: anon and authenticated roles get no access to these tables.
alter table public.topics enable row level security;
alter table public.pictures enable row level security;

-- Public bucket so the returned URLs can be fetched by the game without signing.
-- Uploads are limited to the three formats and 4 MiB, matching the API checks.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'pictures',
  'pictures',
  true,
  4194304,
  array['image/png', 'image/jpeg', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

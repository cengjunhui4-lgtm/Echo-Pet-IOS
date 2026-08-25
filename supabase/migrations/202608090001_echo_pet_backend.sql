-- Echo Pet Supabase backend foundation.
-- Run this migration in Supabase SQL editor or through the Supabase CLI.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_path text,
  locale text not null default 'zh-Hans',
  ai_memory_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  species text not null default 'pet',
  breed text,
  gender text,
  birthday date,
  adoption_date date,
  avatar_path text,
  relationship_label text not null default '主人与宠物',
  personality_notes text,
  health_notes text,
  favorite_things text[] not null default '{}',
  habits text[] not null default '{}',
  ai_memory_enabled boolean not null default true,
  status text not null default 'active' check (status in ('active', 'archived', 'deleted')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.timeline_events (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  story text,
  happened_at timestamptz not null default now(),
  location_label text,
  mood text,
  emotion_tags text[] not null default '{}',
  behavior_tags text[] not null default '{}',
  importance integer not null default 3 check (importance between 1 and 5),
  source_kind text not null default 'memory' check (source_kind in ('memory', 'daily_task', 'capsule', 'system')),
  ai_summary text,
  ai_context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.timeline_media_assets (
  id uuid primary key default gen_random_uuid(),
  timeline_event_id uuid not null references public.timeline_events(id) on delete cascade,
  pet_id uuid not null references public.pets(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  media_kind text not null default 'photo' check (media_kind in ('photo', 'video', 'audio')),
  mime_type text,
  width integer,
  height integer,
  duration_seconds numeric,
  sort_order integer not null default 0,
  caption text,
  created_at timestamptz not null default now(),
  unique (timeline_event_id, sort_order)
);

create table if not exists public.daily_tasks (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  note text,
  due_on date not null default current_date,
  due_at time,
  template_key text,
  is_completed boolean not null default false,
  completed_at timestamptz,
  mood_after text,
  importance integer not null default 3 check (importance between 1 and 5),
  ai_context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lifeprints (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  version integer not null default 1,
  summary text not null,
  personality_traits text[] not null default '{}',
  favorite_things text[] not null default '{}',
  habits text[] not null default '{}',
  relationship_patterns text[] not null default '{}',
  source_timeline_event_ids uuid[] not null default '{}',
  source_daily_task_ids uuid[] not null default '{}',
  ai_model text,
  ai_mode text,
  confidence numeric,
  is_current boolean not null default true,
  generated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.memory_capsules (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  subtitle text,
  occasion text,
  cover_media_path text,
  content jsonb not null default '{}'::jsonb,
  source_timeline_event_ids uuid[] not null default '{}',
  source_daily_task_ids uuid[] not null default '{}',
  ai_model text,
  ai_mode text,
  status text not null default 'generated' check (status in ('draft', 'generated', 'opened', 'archived')),
  generated_at timestamptz not null default now(),
  opened_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.companion_messages (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  is_ai_generated boolean not null default false,
  source_timeline_event_ids uuid[] not null default '{}',
  source_daily_task_ids uuid[] not null default '{}',
  source_lifeprint_id uuid references public.lifeprints(id) on delete set null,
  request_context jsonb not null default '{}'::jsonb,
  model_version text,
  provider text,
  mode text,
  created_at timestamptz not null default now()
);

create table if not exists public.user_data_requests (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  request_kind text not null check (request_kind in ('export', 'delete')),
  status text not null default 'pending' check (status in ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  result_path text,
  requested_at timestamptz not null default now(),
  completed_at timestamptz
);

create index if not exists pets_owner_idx on public.pets(owner_id);
create index if not exists timeline_events_pet_happened_idx on public.timeline_events(pet_id, happened_at desc);
create index if not exists timeline_media_assets_event_order_idx on public.timeline_media_assets(timeline_event_id, sort_order);
create index if not exists daily_tasks_pet_due_idx on public.daily_tasks(pet_id, due_on desc, is_completed);
create index if not exists lifeprints_pet_current_idx on public.lifeprints(pet_id, is_current, generated_at desc);
create index if not exists memory_capsules_pet_generated_idx on public.memory_capsules(pet_id, generated_at desc);
create index if not exists companion_messages_pet_created_idx on public.companion_messages(pet_id, created_at desc);
create index if not exists user_data_requests_owner_idx on public.user_data_requests(owner_id, requested_at desc);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists pets_set_updated_at on public.pets;
create trigger pets_set_updated_at
before update on public.pets
for each row execute function public.set_updated_at();

drop trigger if exists timeline_events_set_updated_at on public.timeline_events;
create trigger timeline_events_set_updated_at
before update on public.timeline_events
for each row execute function public.set_updated_at();

drop trigger if exists daily_tasks_set_updated_at on public.daily_tasks;
create trigger daily_tasks_set_updated_at
before update on public.daily_tasks
for each row execute function public.set_updated_at();

drop trigger if exists lifeprints_set_updated_at on public.lifeprints;
create trigger lifeprints_set_updated_at
before update on public.lifeprints
for each row execute function public.set_updated_at();

drop trigger if exists memory_capsules_set_updated_at on public.memory_capsules;
create trigger memory_capsules_set_updated_at
before update on public.memory_capsules
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.pets enable row level security;
alter table public.timeline_events enable row level security;
alter table public.timeline_media_assets enable row level security;
alter table public.daily_tasks enable row level security;
alter table public.lifeprints enable row level security;
alter table public.memory_capsules enable row level security;
alter table public.companion_messages enable row level security;
alter table public.user_data_requests enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
for select using (id = auth.uid());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
for insert with check (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "pets_select_own" on public.pets;
create policy "pets_select_own" on public.pets
for select using (owner_id = auth.uid());

drop policy if exists "pets_insert_own" on public.pets;
create policy "pets_insert_own" on public.pets
for insert with check (owner_id = auth.uid());

drop policy if exists "pets_update_own" on public.pets;
create policy "pets_update_own" on public.pets
for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "pets_delete_own" on public.pets;
create policy "pets_delete_own" on public.pets
for delete using (owner_id = auth.uid());

drop policy if exists "timeline_events_all_own" on public.timeline_events;
create policy "timeline_events_all_own" on public.timeline_events
for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "timeline_media_assets_all_own" on public.timeline_media_assets;
create policy "timeline_media_assets_all_own" on public.timeline_media_assets
for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "daily_tasks_all_own" on public.daily_tasks;
create policy "daily_tasks_all_own" on public.daily_tasks
for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "lifeprints_all_own" on public.lifeprints;
create policy "lifeprints_all_own" on public.lifeprints
for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "memory_capsules_all_own" on public.memory_capsules;
create policy "memory_capsules_all_own" on public.memory_capsules
for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "companion_messages_all_own" on public.companion_messages;
create policy "companion_messages_all_own" on public.companion_messages
for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "user_data_requests_all_own" on public.user_data_requests;
create policy "user_data_requests_all_own" on public.user_data_requests
for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'pet-media',
  'pet-media',
  false,
  52428800,
  array['image/jpeg', 'image/png', 'image/heic', 'image/heif', 'video/mp4', 'video/quicktime']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "pet_media_select_own_folder" on storage.objects;
create policy "pet_media_select_own_folder" on storage.objects
for select using (
  bucket_id = 'pet-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "pet_media_insert_own_folder" on storage.objects;
create policy "pet_media_insert_own_folder" on storage.objects
for insert with check (
  bucket_id = 'pet-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "pet_media_update_own_folder" on storage.objects;
create policy "pet_media_update_own_folder" on storage.objects
for update using (
  bucket_id = 'pet-media'
  and (storage.foldername(name))[1] = auth.uid()::text
) with check (
  bucket_id = 'pet-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "pet_media_delete_own_folder" on storage.objects;
create policy "pet_media_delete_own_folder" on storage.objects
for delete using (
  bucket_id = 'pet-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

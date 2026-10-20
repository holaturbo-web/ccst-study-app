-- CCST Crew: Supabase setup
-- Paste this whole file into Supabase → SQL Editor → New query, edit the 3 values marked EDIT, then Run.
-- Safe to run again later: it only adds what's missing and refreshes the functions and rules.

-- ===== 1. Settings (EDIT these three values before running) =====
create table if not exists public.settings (key text primary key, value text not null);
insert into public.settings (key, value) values
  ('crew_code',      'CHANGE-ME-1234'),                   -- EDIT: the code techs type to sign up
  ('coach_username', 'alejandro'),                         -- EDIT: the username YOU will sign up with (becomes coach)
  ('email_pattern',  'yourcrewinbox+{u}@gmail.com')        -- EDIT: an inbox you control; {u} becomes the username
on conflict (key) do nothing;

-- ===== 2. Tables =====
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  display_name text not null,
  role text not null default 'tech' check (role in ('tech', 'coach')),
  approved boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.progress (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
create table if not exists public.stats (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  week text,
  week_points int not null default 0,
  week_answered int not null default 0,
  week_correct int not null default 0,
  week_cards int not null default 0,
  total_points int not null default 0,
  total_answered int not null default 0,
  total_correct int not null default 0,
  total_cards int not null default 0,
  streak int not null default 0,
  readiness int not null default 0,
  last_active timestamptz,
  blocks jsonb not null default '{}'::jsonb,
  tasks jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
create table if not exists public.announcements (
  id bigint generated always as identity primary key,
  body text not null check (char_length(body) between 1 and 1000),
  author uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.content (
  name text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

-- ===== 3. Helper functions =====
create or replace function public.is_approved() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and approved);
$$;
create or replace function public.is_coach() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and approved and role = 'coach');
$$;
-- Turns a username into the sign-in address (techs never see or use this address).
create or replace function public.crew_email(u text) returns text
language sql stable security definer set search_path = public as $$
  select replace((select value from public.settings where key = 'email_pattern'), '{u}', lower(trim(u)));
$$;
grant execute on function public.crew_email(text) to anon, authenticated;

-- New sign-ups: check the crew code and username, create the profile (pending approval).
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_code text; v_coach text; v_user text; v_name text; v_is_coach boolean;
begin
  select value into v_code from public.settings where key = 'crew_code';
  select lower(value) into v_coach from public.settings where key = 'coach_username';
  v_user := lower(trim(coalesce(new.raw_user_meta_data ->> 'username', '')));
  v_name := left(trim(coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), v_user)), 40);
  if v_user !~ '^[a-z0-9][a-z0-9_.-]{2,23}$' then
    raise exception 'CREW_BAD_USERNAME';
  end if;
  if coalesce(new.raw_user_meta_data ->> 'crew_code', '') is distinct from v_code then
    raise exception 'CREW_BAD_CODE';
  end if;
  -- The coach username becomes coach only if no coach exists yet.
  v_is_coach := v_user = v_coach and not exists (select 1 from public.profiles where role = 'coach');
  insert into public.profiles (id, username, display_name, role, approved)
  values (new.id, v_user, v_name, case when v_is_coach then 'coach' else 'tech' end, v_is_coach);
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Coach-only: read or change the crew code from the app.
create or replace function public.get_crew_code() returns text
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_coach() then raise exception 'not allowed'; end if;
  return (select value from public.settings where key = 'crew_code');
end $$;
create or replace function public.set_crew_code(new_code text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_coach() then raise exception 'not allowed'; end if;
  if char_length(trim(new_code)) < 4 then raise exception 'code too short'; end if;
  update public.settings set value = trim(new_code) where key = 'crew_code';
end $$;
revoke execute on function public.get_crew_code() from anon;
revoke execute on function public.set_crew_code(text) from anon;

-- ===== 4. Row level security =====
alter table public.settings enable row level security;       -- no policies: only the functions above read it
alter table public.profiles enable row level security;
alter table public.progress enable row level security;
alter table public.stats enable row level security;
alter table public.announcements enable row level security;
alter table public.content enable row level security;

drop policy if exists profiles_read on public.profiles;
drop policy if exists profiles_coach_update on public.profiles;
drop policy if exists profiles_coach_delete on public.profiles;
create policy profiles_read on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_approved());
create policy profiles_coach_update on public.profiles for update to authenticated
  using (public.is_coach()) with check (public.is_coach());
create policy profiles_coach_delete on public.profiles for delete to authenticated
  using (public.is_coach() and id <> auth.uid());

drop policy if exists progress_own on public.progress;
drop policy if exists progress_coach_read on public.progress;
create policy progress_own on public.progress for all to authenticated
  using (user_id = auth.uid() and public.is_approved())
  with check (user_id = auth.uid() and public.is_approved());
create policy progress_coach_read on public.progress for select to authenticated
  using (public.is_coach());

drop policy if exists stats_read on public.stats;
drop policy if exists stats_own_write on public.stats;
drop policy if exists stats_own_update on public.stats;
create policy stats_read on public.stats for select to authenticated
  using (public.is_approved());
create policy stats_own_write on public.stats for insert to authenticated
  with check (user_id = auth.uid() and public.is_approved());
create policy stats_own_update on public.stats for update to authenticated
  using (user_id = auth.uid() and public.is_approved())
  with check (user_id = auth.uid() and public.is_approved());

drop policy if exists ann_read on public.announcements;
drop policy if exists ann_coach_insert on public.announcements;
drop policy if exists ann_coach_delete on public.announcements;
create policy ann_read on public.announcements for select to authenticated
  using (public.is_approved());
create policy ann_coach_insert on public.announcements for insert to authenticated
  with check (public.is_coach() and author = auth.uid());
create policy ann_coach_delete on public.announcements for delete to authenticated
  using (public.is_coach());

drop policy if exists content_read on public.content;
drop policy if exists content_coach_insert on public.content;
drop policy if exists content_coach_update on public.content;
create policy content_read on public.content for select to authenticated
  using (public.is_approved());
create policy content_coach_insert on public.content for insert to authenticated
  with check (public.is_coach());
create policy content_coach_update on public.content for update to authenticated
  using (public.is_coach()) with check (public.is_coach());

-- ===== 5. Private file storage for the Study Reader PDF =====
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('reader', 'reader', false, 52428800, array['application/pdf'])
on conflict (id) do nothing;

drop policy if exists reader_read on storage.objects;
drop policy if exists reader_coach_insert on storage.objects;
drop policy if exists reader_coach_update on storage.objects;
create policy reader_read on storage.objects for select to authenticated
  using (bucket_id = 'reader' and public.is_approved());
create policy reader_coach_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'reader' and public.is_coach());
create policy reader_coach_update on storage.objects for update to authenticated
  using (bucket_id = 'reader' and public.is_coach()) with check (bucket_id = 'reader' and public.is_coach());

-- Done. Check: select * from public.settings;

-- =====================================================================
-- Nirma Hub :: Estimated CGPA feature
-- Run this whole file once in Supabase -> SQL Editor -> New query -> Run
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Admin-managed semester setup per academic year
--    Tells the app: which semester the live "Estimated SGPA" belongs to,
--    and which past semesters the student should type in manually.
-- ---------------------------------------------------------------------
create table if not exists public.cgpa_configs (
  id                   uuid primary key default gen_random_uuid(),
  academic_year        text    not null,              -- '1st' | '2nd' | '3rd' | '4th'
  applies_to_semester  int     not null default 0,    -- 0 = default row for the year.
                                                      -- For 1st year use 1 or 2 so each
                                                      -- SGPA tab gets its own setup.
  current_semester     int     not null,              -- semester number of the live Estimated SGPA
  past_semesters       jsonb   not null default '[]'::jsonb,
                                                      -- [{"number":1,"label":"Semester 1"},
                                                      --  {"number":2,"label":"Semester 2"}]
  is_enabled           boolean not null default true, -- false = hide the CGPA card for this year
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  constraint cgpa_configs_unique_year_sem unique (academic_year, applies_to_semester),
  constraint cgpa_configs_current_sem_chk check (current_semester between 1 and 12)
);

create index if not exists cgpa_configs_year_idx
  on public.cgpa_configs (academic_year, applies_to_semester);

-- ---------------------------------------------------------------------
-- 2. The SGPA values each student types in for their completed semesters
-- ---------------------------------------------------------------------
create table if not exists public.user_past_sgpa (
  user_id          uuid not null references public.profiles(id) on delete cascade,
  semester_number  int  not null,
  sgpa             numeric(4,2) not null check (sgpa >= 0 and sgpa <= 10),
  updated_at       timestamptz not null default now(),
  primary key (user_id, semester_number)
);

create index if not exists user_past_sgpa_user_idx
  on public.user_past_sgpa (user_id);

-- ---------------------------------------------------------------------
-- 3. Keep updated_at fresh
-- ---------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists cgpa_configs_touch on public.cgpa_configs;
create trigger cgpa_configs_touch
  before update on public.cgpa_configs
  for each row execute function public.touch_updated_at();

drop trigger if exists user_past_sgpa_touch on public.user_past_sgpa;
create trigger user_past_sgpa_touch
  before update on public.user_past_sgpa
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------
-- 4. Row Level Security
--    (the admin panel uses the service_role key, which bypasses RLS,
--     so it keeps full read/write access without extra policies)
-- ---------------------------------------------------------------------
alter table public.cgpa_configs   enable row level security;
alter table public.user_past_sgpa enable row level security;

drop policy if exists "cgpa_configs read for signed-in users" on public.cgpa_configs;
create policy "cgpa_configs read for signed-in users"
  on public.cgpa_configs
  for select
  to authenticated
  using (true);

drop policy if exists "own past sgpa select" on public.user_past_sgpa;
create policy "own past sgpa select"
  on public.user_past_sgpa
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "own past sgpa insert" on public.user_past_sgpa;
create policy "own past sgpa insert"
  on public.user_past_sgpa
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "own past sgpa update" on public.user_past_sgpa;
create policy "own past sgpa update"
  on public.user_past_sgpa
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "own past sgpa delete" on public.user_past_sgpa;
create policy "own past sgpa delete"
  on public.user_past_sgpa
  for delete
  to authenticated
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 5. Starter rows (edit / add more later from the admin panel)
-- ---------------------------------------------------------------------
insert into public.cgpa_configs
  (academic_year, applies_to_semester, current_semester, past_semesters, is_enabled)
values
  -- 1st year, Semester 1 tab: nothing completed yet -> CGPA = SGPA
  ('1st', 1, 1, '[]'::jsonb, true),
  -- 1st year, Semester 2 tab: Sem 1 is done
  ('1st', 2, 2, '[{"number":1,"label":"Semester 1"}]'::jsonb, true),
  -- 2nd year: Sem 1 + Sem 2 done, live SGPA is Sem 3
  ('2nd', 0, 3, '[{"number":1,"label":"Semester 1"},{"number":2,"label":"Semester 2"}]'::jsonb, true),
  -- 3rd year: Sem 1..4 done, live SGPA is Sem 5
  ('3rd', 0, 5, '[{"number":1,"label":"Semester 1"},{"number":2,"label":"Semester 2"},{"number":3,"label":"Semester 3"},{"number":4,"label":"Semester 4"}]'::jsonb, true),
  -- 4th year: Sem 1..6 done, live SGPA is Sem 7
  ('4th', 0, 7, '[{"number":1,"label":"Semester 1"},{"number":2,"label":"Semester 2"},{"number":3,"label":"Semester 3"},{"number":4,"label":"Semester 4"},{"number":5,"label":"Semester 5"},{"number":6,"label":"Semester 6"}]'::jsonb, true)
on conflict (academic_year, applies_to_semester) do nothing;

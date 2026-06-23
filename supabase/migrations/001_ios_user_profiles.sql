-- Nutriscope AI iOS — minimal schema (dedicated Supabase project)
-- Meals stay on-device (SwiftData) for now; this table is for future cloud profile sync.

create table if not exists public.ios_user_profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  email text,
  daily_protein_target int default 135,
  calorie_range_min int default 1900,
  calorie_range_max int default 2200,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.ios_user_profiles enable row level security;

create policy "Users read own profile"
  on public.ios_user_profiles for select
  using (auth.uid() = id);

create policy "Users insert own profile"
  on public.ios_user_profiles for insert
  with check (auth.uid() = id);

create policy "Users update own profile"
  on public.ios_user_profiles for update
  using (auth.uid() = id);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger ios_user_profiles_updated_at
  before update on public.ios_user_profiles
  for each row execute function public.set_updated_at();

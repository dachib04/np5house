-- Per-house option control: which catalog options are enabled for each house.
-- Absence of a row means that option is NOT available for that house.
create table if not exists house_option_enabled (
  id uuid primary key default gen_random_uuid(),
  house_id uuid references houses(id) on delete cascade,
  category text not null, -- 'facade-system' | 'subframe' | 'insulation-material' | 'insulation-thickness' | 'windows' | 'roof' | 'included'
  item_key text not null,
  created_at timestamptz default now(),
  unique(house_id, category, item_key)
);
alter table house_option_enabled enable row level security;
create policy "Public read house_option_enabled" on house_option_enabled for select to anon, authenticated using (true);
create policy "Admin write house_option_enabled" on house_option_enabled for insert to authenticated with check (true);
create policy "Admin delete house_option_enabled" on house_option_enabled for delete to authenticated using (true);

-- Compatibility rules, per house: selecting (if_category, if_key) either excludes or requires (then_category, then_key).
create table if not exists house_compat_rules (
  id uuid primary key default gen_random_uuid(),
  house_id uuid references houses(id) on delete cascade,
  if_category text not null,
  if_key text not null,
  then_category text not null,
  then_key text not null,
  relation text not null check (relation in ('excludes','requires')),
  created_at timestamptz default now()
);
alter table house_compat_rules enable row level security;
create policy "Public read house_compat_rules" on house_compat_rules for select to anon, authenticated using (true);
create policy "Admin write house_compat_rules" on house_compat_rules for insert to authenticated with check (true);
create policy "Admin delete house_compat_rules" on house_compat_rules for delete to authenticated using (true);

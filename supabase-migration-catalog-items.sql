-- The global option catalog (subframe, insulation, windows, roof, etc).
-- Per-house availability still comes from house_option_enabled — this table is just
-- "what options exist at all", so the admin can add a brand-new option (e.g. a new
-- window type) without needing a code change.
create table if not exists catalog_items (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  item_key text not null,
  name text not null,
  note text,
  sort_order int default 0,
  created_at timestamptz default now(),
  unique(category, item_key)
);
alter table catalog_items enable row level security;
create policy "Public read catalog_items" on catalog_items for select to anon, authenticated using (true);
create policy "Admin write catalog_items" on catalog_items for insert to authenticated with check (true);
create policy "Admin update catalog_items" on catalog_items for update to authenticated using (true);
create policy "Admin delete catalog_items" on catalog_items for delete to authenticated using (true);

-- Seed with the existing fixed catalog so nothing changes for current houses.
insert into catalog_items (category, item_key, name, note, sort_order) values
  ('subframe', 'timber', 'Timber', 'Double ventilated timber subframe', 0),
  ('subframe', 'steel', 'Steel Omega', 'Galvanized steel Omega subframe', 1),
  ('insulation-material', 'mineral-wool', 'Mineral Wool', 'Ventilated or Non-Ventilated', 0),
  ('insulation-material', 'phenolic', 'Phenolic Foam (PF)', 'Non-Ventilated only', 1),
  ('insulation-material', 'eps', 'EPS', 'Ventilated only', 2),
  ('insulation-material', 'pir', 'PIR', 'Ventilated only', 3),
  ('insulation-thickness', '12cm', '12 cm', '', 0),
  ('insulation-thickness', '20cm', '20 cm', '', 1),
  ('windows', 'aluminium', 'Aluminium', 'Slim profile', 0),
  ('windows', 'plastic', 'Plastic (PVC)', 'Standard', 1),
  ('roof', 'slope', 'Slope', '', 0),
  ('roof', 'flat', 'Flat', '', 1),
  ('included', 'interior-finishing', 'Interior Finishing', 'Folded into every quote', 0),
  ('included', 'floor-assembly', 'Floor Assembly', 'Folded into every quote', 1)
on conflict (category, item_key) do nothing;

-- Quote requests submitted from the configurator's "Request Quote" form.
create table if not exists quote_requests (
  id uuid primary key default gen_random_uuid(),
  house_id uuid references houses(id) on delete set null,
  house_name text,
  house_slug text,
  name text not null,
  email text not null,
  phone text,
  message text,
  configuration jsonb,
  estimated_price numeric,
  handled boolean not null default false,
  created_at timestamptz default now()
);
alter table quote_requests enable row level security;
-- Anyone (including anonymous visitors) can submit a quote request.
create policy "Public can submit quote requests" on quote_requests for insert to anon, authenticated with check (true);
-- Only the logged-in admin can read or manage them.
create policy "Admin read quote_requests" on quote_requests for select to authenticated using (true);
create policy "Admin update quote_requests" on quote_requests for update to authenticated using (true);
create policy "Admin delete quote_requests" on quote_requests for delete to authenticated using (true);

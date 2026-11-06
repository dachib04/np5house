-- ============================================================
-- 1) Spam / abuse protection on quote_requests
--    A bot or malicious script could otherwise submit unlimited
--    requests. This rejects a new request from the same email
--    within 2 minutes of their last one, and caps anyone at 5
--    requests per 24 hours — enforced in the database, so it can't
--    be bypassed by skipping the frontend JS.
-- ============================================================
create or replace function quote_requests_rate_limit() returns trigger as $$
declare
  recent_count int;
  last_submitted timestamptz;
begin
  select max(created_at) into last_submitted
  from quote_requests where lower(email) = lower(new.email);

  if last_submitted is not null and now() - last_submitted < interval '2 minutes' then
    raise exception 'Please wait a couple of minutes before submitting another request.';
  end if;

  select count(*) into recent_count
  from quote_requests
  where lower(email) = lower(new.email) and created_at > now() - interval '24 hours';

  if recent_count >= 5 then
    raise exception 'Too many requests from this email today. Please contact us directly.';
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_quote_requests_rate_limit on quote_requests;
create trigger trg_quote_requests_rate_limit
  before insert on quote_requests
  for each row execute function quote_requests_rate_limit();

-- ============================================================
-- 2) Input length limits (defense in depth — the frontend also
--    enforces these, but a direct API call could skip the frontend)
-- ============================================================
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'quote_requests_name_len') then
    alter table quote_requests add constraint quote_requests_name_len check (char_length(name) <= 200);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'quote_requests_email_len') then
    alter table quote_requests add constraint quote_requests_email_len check (char_length(email) <= 320);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'quote_requests_phone_len') then
    alter table quote_requests add constraint quote_requests_phone_len check (phone is null or char_length(phone) <= 40);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'quote_requests_message_len') then
    alter table quote_requests add constraint quote_requests_message_len check (message is null or char_length(message) <= 4000);
  end if;
end $$;

-- ============================================================
-- 3) Server-side cost/markup storage, ready for when real pricing
--    data lands. No public read policy at all — only the logged-in
--    admin can ever see this table, regardless of what any client
--    script requests. Customers only ever see `prices.price` (the
--    final selling price), never cost or markup.
-- ============================================================
create table if not exists price_costs (
  id text primary key references prices(id) on delete cascade,
  cost numeric,
  markup_pct numeric,
  notes text,
  updated_at timestamptz default now()
);
alter table price_costs enable row level security;
create policy "Admin only read price_costs" on price_costs for select to authenticated using (true);
create policy "Admin only write price_costs" on price_costs for insert to authenticated with check (true);
create policy "Admin only update price_costs" on price_costs for update to authenticated using (true);
create policy "Admin only delete price_costs" on price_costs for delete to authenticated using (true);
-- Note: no policy at all for the `anon` role — PostgREST denies by default,
-- so an unauthenticated visitor cannot read this table under any circumstance.

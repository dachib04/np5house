-- ============================================================
-- CRITICAL: lock write access down to the real admin, not just
-- "anyone who is logged in".
--
-- Why this matters: every write policy on this project so far grants
-- access `to authenticated` — meaning ANY Supabase Auth user, not
-- specifically you. This project currently has public sign-up ENABLED
-- (confirmed by testing it directly), so right now anyone could create
-- an account, confirm their email, and get full write/delete access to
-- houses, prices, catalog items, and quote requests.
--
-- This migration fixes the real root cause: every write policy now
-- checks that the logged-in user's email matches yours specifically,
-- not just that they're logged in at all. This protects you even if
-- public sign-up stays on, even if someone else's account gets
-- compromised, and even if a future policy is added carelessly.
--
-- You should ALSO disable public sign-up in the dashboard (see the
-- chat message for exact steps) as defense in depth — but this
-- migration is the part that actually closes the hole regardless.
--
-- IMPORTANT: replace 'dachib04@gmail.com' below with the real admin
-- email if it's different, BEFORE running this.
-- ============================================================

create or replace function is_admin() returns boolean as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'dachib04@gmail.com';
$$ language sql stable security definer set search_path = public;

-- Re-locks every INSERT/UPDATE/DELETE policy on every CMS-managed table to
-- admin-only (so this is safe to run however many times, and doesn't depend
-- on knowing the exact original policy names). quote_requests is handled
-- separately below, since its INSERT must stay public.
do $$
declare
  tbl text;
  pol record;
  tables text[] := array[
    'houses', 'house_facades', 'house_facade_images', 'gallery_images',
    'prices', 'catalog_items', 'house_option_enabled', 'house_compat_rules',
    'price_costs'
  ];
begin
  foreach tbl in array tables loop
    if to_regclass('public.' || tbl) is null then
      continue; -- table doesn't exist in this project yet, skip it
    end if;
    for pol in
      select policyname from pg_policies
      where schemaname = 'public' and tablename = tbl and cmd in ('INSERT', 'UPDATE', 'DELETE')
    loop
      execute format('drop policy %I on public.%I', pol.policyname, tbl);
    end loop;

    execute format('create policy %I on public.%I for insert to authenticated with check (is_admin())', tbl || '_admin_insert', tbl);
    execute format('create policy %I on public.%I for update to authenticated using (is_admin())', tbl || '_admin_update', tbl);
    execute format('create policy %I on public.%I for delete to authenticated using (is_admin())', tbl || '_admin_delete', tbl);
  end loop;
end $$;

-- quote_requests: INSERT must stay open to anonymous visitors (that's the
-- whole point of the form), but UPDATE ("mark as handled") and DELETE
-- become admin-only like everything else.
do $$
declare pol record;
begin
  if to_regclass('public.quote_requests') is not null then
    for pol in
      select policyname from pg_policies
      where schemaname = 'public' and tablename = 'quote_requests' and cmd in ('UPDATE', 'DELETE')
    loop
      execute format('drop policy %I on public.quote_requests', pol.policyname);
    end loop;
    create policy quote_requests_admin_update on public.quote_requests for update to authenticated using (is_admin());
    create policy quote_requests_admin_delete on public.quote_requests for delete to authenticated using (is_admin());
  end if;
end $$;

-- Re-assert the public insert policy explicitly, in case it was ever
-- dropped or renamed — visitors must still be able to submit without
-- logging in at all.
drop policy if exists "Public can submit quote requests" on quote_requests;
create policy "Public can submit quote requests" on quote_requests for insert to anon, authenticated with check (true);

-- Storage buckets (house-images, gallery-images) have the exact same hole:
-- their upload/delete policies are scoped to "authenticated", not specifically
-- you. Lock those down the same way. Their public SELECT (so images actually
-- display on the site) is untouched.
do $$
declare
  bucket text;
  pol record;
  buckets text[] := array['house-images', 'gallery-images'];
begin
  foreach bucket in array buckets loop
    for pol in
      select policyname from pg_policies
      where schemaname = 'storage' and tablename = 'objects'
        and cmd in ('INSERT', 'UPDATE', 'DELETE')
        and policyname ilike '%' || bucket || '%'
    loop
      execute format('drop policy %I on storage.objects', pol.policyname);
    end loop;
    execute format(
      'create policy %I on storage.objects for insert to authenticated with check (bucket_id = %L and is_admin())',
      bucket || '_admin_upload', bucket
    );
    execute format(
      'create policy %I on storage.objects for update to authenticated using (bucket_id = %L and is_admin())',
      bucket || '_admin_update', bucket
    );
    execute format(
      'create policy %I on storage.objects for delete to authenticated using (bucket_id = %L and is_admin())',
      bucket || '_admin_delete', bucket
    );
  end loop;
end $$;

-- SELECT also needs locking down on the two genuinely private tables —
-- their existing SELECT policies say "any authenticated user", which has
-- the exact same hole as the write policies did: quote_requests holds real
-- customer PII (name, email, phone), and price_costs holds the business's
-- real cost/markup figures. Neither should be readable by just anyone who
-- signed up. Every other table's SELECT stays public on purpose — the
-- website itself needs to read houses, prices, catalog items, etc.
do $$
declare
  tbl text;
  pol record;
  private_tables text[] := array['quote_requests', 'price_costs'];
begin
  foreach tbl in array private_tables loop
    if to_regclass('public.' || tbl) is null then
      continue;
    end if;
    for pol in
      select policyname from pg_policies
      where schemaname = 'public' and tablename = tbl and cmd = 'SELECT'
    loop
      execute format('drop policy %I on public.%I', pol.policyname, tbl);
    end loop;
    execute format('create policy %I on public.%I for select to authenticated using (is_admin())', tbl || '_admin_select', tbl);
  end loop;
end $$;

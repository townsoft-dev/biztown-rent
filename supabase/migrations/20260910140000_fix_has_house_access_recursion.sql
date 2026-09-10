-- Critical bug found while wiring real House/Room CRUD (10/09/2026): every
-- RLS-protected table's policy calls has_house_access(), which SELECTs from
-- tb_user_house_access — but tb_user_house_access's OWN SELECT policy also
-- calls has_house_access(), which SELECTs from tb_user_house_access again,
-- forever ("stack depth limit exceeded", never caught before because all
-- prior testing either used static sample data or hit empty tables, where
-- the policy has zero rows to evaluate and the recursive call path never
-- actually fires). See docs/DECISIONS.md 2026-09-10 for the full writeup.
--
-- Fix: has_house_access() must run as SECURITY DEFINER so its internal read
-- of tb_user_house_access bypasses that table's own RLS instead of
-- re-triggering it. This is the standard pattern for a permission-check
-- helper that reads the very table its callers' policies are guarding.
create or replace function has_house_access(p_house_id uuid, p_role text default null)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from tb_user_house_access
    where house_id = p_house_id
      and phone = current_user_phone()
      and (p_role is null or role = p_role)
  )
$$;

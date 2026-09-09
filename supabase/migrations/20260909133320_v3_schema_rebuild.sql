-- BizTown Rent-Manager — schema rebuild for Version 3
-- Replaces the Version 1 schema from 20260903121605_initial_schema.sql (dropped below).
-- Source of truth: docs/DATABASE.md (Version 3, 2026-09-08) + docs/BUSINESS-RULES.md.
-- See docs/DECISIONS.md 2026-09-09 for the V1->V3 rebuild decision.

-- ============================================================
-- 0. Drop Version 1 schema (dev project, no real data — clean rebuild)
-- ============================================================
drop table if exists notifications cascade;
drop table if exists rental_inquiries cascade;
drop table if exists maintenance_requests cascade;
drop table if exists payments cascade;
drop table if exists invoices cascade;
drop table if exists meter_readings cascade;
drop table if exists contracts cascade;
drop table if exists rooms cascade;
drop table if exists properties cascade;
drop table if exists tenants cascade;
drop table if exists landlords cascade;

-- ============================================================
-- 1. tb_user — pure identity, no role column (role lives in tb_user_house_access)
-- ============================================================
create table tb_user (
  id uuid primary key references auth.users (id) on delete cascade,
  phone text not null unique, -- login credential, immutable after creation (BR-ROLE-09)
  full_name text not null,
  email text, -- optional Phase 1, Phase 2 required for email-OTP recovery
  id_number text,
  status text not null default 'active' check (status in ('active', 'disabled')),
  note text,
  created_at timestamptz not null default now()
);
-- NOTE: no passwordHash column here — auth is fully delegated to Supabase Auth
-- (auth.users), per docs/ARCHITECTURE.md "Manager là 1-1 với auth.users, dùng
-- chung Supabase Auth". DATABASE.md still lists passwordHash as a leftover from
-- the Version 2 manager_account design; omitted here to match the actual
-- architecture decision instead of the stale field list.

comment on table tb_user is 'Pure identity table, 1-1 with auth.users. Role is NOT stored here — see tb_user_house_access.';

-- ============================================================
-- 2. tb_house (Nhà/Dãy trọ)
-- ============================================================
create table tb_house (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text not null,
  description text,
  photos text[] not null default '{}',
  house_type text not null default 'Dãy trọ' check (house_type in ('Dãy trọ', 'Căn hộ')),
  owner_full_name text not null,
  owner_id_number text,
  owner_tax_code text,
  bank_account_name text,
  bank_account_number text,
  bank_bin text, -- NAPAS bank code, for VietQR generation
  service_fee_rate_per_sqm numeric, -- default only, NOT used for billing (see tb_contract_version)
  recurring_fees jsonb not null default '[]', -- [{name, amount}], default only
  created_at timestamptz not null default now()
);

-- ============================================================
-- 3. tb_user_house_access — the single source of role, keyed by phone
-- ============================================================
create table tb_user_house_access (
  id uuid primary key default gen_random_uuid(),
  phone text not null, -- logical FK to tb_user.phone; may point to a phone with no account yet
  house_id uuid not null references tb_house (id) on delete cascade,
  role text not null check (role in ('owner', 'manager')),
  granted_by_phone text, -- logical FK to tb_user.phone; null if self-granted (house creator)
  granted_at timestamptz not null default now(),
  unique (phone, house_id)
);

create index idx_user_house_access_phone on tb_user_house_access (phone);
create index idx_user_house_access_house on tb_user_house_access (house_id);

-- ============================================================
-- 4. tb_room (Phòng)
-- ============================================================
create table tb_room (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references tb_house (id) on delete cascade,
  room_no text not null,
  area_sqm numeric not null,
  base_rent numeric, -- reference price only, not the billing source of truth
  recurring_fees jsonb not null default '[]', -- [{name, amount}], defaults from tb_house at creation
  amenities text[] not null default '{}',
  photos text[] not null default '{}',
  status text not null default 'Empty' check (status in ('Empty', 'Occupied', 'UnderRepair')),
  created_at timestamptz not null default now()
);

create index idx_room_house on tb_room (house_id);

-- ============================================================
-- 5. tb_tenant (Tenant Pool — no login, scoped per house)
-- ============================================================
create table tb_tenant (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references tb_house (id) on delete cascade, -- BR-DATA-05
  full_name text not null,
  phone text not null,
  sex text check (sex in ('M', 'F')),
  date_of_birth date,
  mail text,
  id_number text,
  id_photo_front text,
  id_photo_back text,
  note text,
  created_at timestamptz not null default now()
);

create index idx_tenant_house on tb_tenant (house_id);

-- ============================================================
-- 6. tb_contract (no direct roomId — see tb_contract_room)
-- ============================================================
create table tb_contract (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tb_tenant (id) on delete restrict, -- fixed representative, BR-CTR-13
  current_version_id uuid, -- FK added after tb_contract_version exists (circular dependency)
  status text not null default 'Active' check (status in ('Active', 'Ended')),
  -- settlement fields (merged from Version 2's contract_settlement, 1-1 relationship)
  unpaid_invoices_total numeric,
  damage_deduction numeric,
  refund_amount numeric,
  settlement_note text,
  settlement_confirmed_at timestamptz,
  created_at timestamptz not null default now()
);

create index idx_contract_tenant on tb_contract (tenant_id);

-- ============================================================
-- 7. tb_contract_room (junction: 1 contract can span multiple rooms)
-- ============================================================
create table tb_contract_room (
  contract_id uuid not null references tb_contract (id) on delete cascade,
  room_id uuid not null references tb_room (id) on delete restrict,
  -- Denormalized flag, kept in sync by trigger below, to enforce "1 room, 1 active
  -- contract at a time" via a partial unique index (can't reference tb_contract.status
  -- directly in a partial index since Postgres partial indexes can only use columns
  -- of the indexed table itself).
  is_active boolean not null default true,
  primary key (contract_id, room_id)
);

create unique index one_active_contract_per_room on tb_contract_room (room_id) where is_active;
create index idx_contract_room_contract on tb_contract_room (contract_id);

create or replace function set_contract_room_is_active()
returns trigger
language plpgsql
as $$
begin
  select (status = 'Active') into new.is_active
  from tb_contract where id = new.contract_id;
  return new;
end;
$$;

create trigger trg_contract_room_set_active
  before insert on tb_contract_room
  for each row execute function set_contract_room_is_active();

create or replace function sync_contract_room_on_status_change()
returns trigger
language plpgsql
as $$
begin
  if new.status is distinct from old.status then
    update tb_contract_room set is_active = (new.status = 'Active') where contract_id = new.id;
  end if;
  return new;
end;
$$;

create trigger trg_contract_status_sync_rooms
  after update of status on tb_contract
  for each row execute function sync_contract_room_on_status_change();

-- ============================================================
-- 8. tb_contract_version (versioned terms, source of truth for billing)
-- ============================================================
create table tb_contract_version (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references tb_contract (id) on delete cascade,
  version_no int not null,
  change_reason text not null check (change_reason in ('New', 'Renewal', 'Amendment')),
  start_date date not null,
  end_date date not null,
  monthly_rent numeric not null, -- whole contract, not per room
  deposit_amount numeric not null, -- whole contract
  electricity_unit_price numeric,
  water_unit_price numeric,
  electricity_billing_method text not null default 'BY_READING'
    check (electricity_billing_method in ('BY_READING', 'FLAT', 'NOT_BILLED')),
  water_billing_method text not null default 'BY_READING'
    check (water_billing_method in ('BY_READING', 'FLAT', 'NOT_BILLED')),
  electricity_flat_amount numeric,
  water_flat_amount numeric,
  recurring_fees jsonb not null default '[]', -- [{name, amount}]
  rent_cycle_months int not null default 1, -- independent of monthly meter reading cycle
  rent_cycle_anchor_ym date not null, -- first-of-month anchor
  payment_due_day_of_month int not null check (payment_due_day_of_month between 1 and 31),
  service_fee_rate_per_sqm numeric, -- snapshot from tb_house at contract creation, editable
  contract_area_sqm numeric not null, -- locked at creation, never recalculated
  service_fee_amount numeric, -- = service_fee_rate_per_sqm * contract_area_sqm, locked
  late_fee_terms text,
  real_estate jsonb, -- {name, contact, fee}, optional
  created_at timestamptz not null default now(),
  unique (contract_id, version_no)
);

create index idx_contract_version_contract on tb_contract_version (contract_id);

alter table tb_contract
  add constraint fk_contract_current_version
  foreign key (current_version_id) references tb_contract_version (id);

-- ============================================================
-- 9. tb_invoice (created before the reading tables so they can FK to it directly)
-- ============================================================
create table tb_invoice (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references tb_contract (id) on delete restrict,
  contract_version_id uuid not null references tb_contract_version (id) on delete restrict,
  house_id uuid not null references tb_house (id) on delete restrict,
  house_name text not null, -- snapshot
  room_nos text[] not null, -- snapshot of room numbers at issue time
  tenant_name text not null, -- snapshot
  period_start date not null,
  period_end date not null,
  due_date date not null,
  rent_amount numeric not null default 0, -- 0 if this period doesn't collect rent; prorated at move-in/out
  -- utility_lines: one entry per room x utility type — see docs/DATABASE.md for why jsonb, not a table
  -- [{roomId, roomNo, utilityType, previousReading, currentReading, usageAmount, unitPrice, totalAmount, readingId}]
  utility_lines jsonb not null default '[]',
  service_fee_amount numeric not null default 0, -- snapshot from contract_version
  recurring_fees jsonb not null default '[]', -- snapshot
  other_fees jsonb not null default '[]', -- ad-hoc adjustments, also used for BR-METER-13 corrections
  total_amount numeric not null,
  payment_qr_payload text, -- VietQR/NAPAS-247 payload
  status text not null default 'Draft' check (status in ('Draft', 'Sent', 'Collected')),
  -- Overdue is derived from due_date while status='Sent', not stored.
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  collected_at timestamptz
);

create index idx_invoice_contract on tb_invoice (contract_id);
create index idx_invoice_house on tb_invoice (house_id);

-- ============================================================
-- 10/11. tb_electricity_reading / tb_water_reading (identical structure, one row per room)
-- ============================================================
create table tb_electricity_reading (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references tb_room (id) on delete cascade,
  house_id uuid not null references tb_house (id) on delete cascade, -- denormalized for RLS/query
  reading_type text not null check (reading_type in ('PERIODIC', 'MOVE_IN', 'MOVE_OUT')),
  period_ym date not null,
  contract_id uuid references tb_contract (id), -- only for MOVE_IN/MOVE_OUT
  reading_date date not null,
  previous_reading_id uuid references tb_electricity_reading (id), -- source of truth for the chain
  previous_reading numeric, -- display snapshot only, NOT the source of truth
  current_reading numeric not null,
  usage_amount numeric generated always as (current_reading - previous_reading) stored,
  recorded_by_phone text not null, -- logical FK to tb_user.phone
  photo_url text,
  invoice_id uuid references tb_invoice (id), -- the invoice where this reading is the CLOSING (to) reading
  -- isLocked is derived (invoice_id is not null, OR this reading is referenced as the
  -- OPENING reading inside another invoice's utility_lines) — not stored, computed at
  -- query time by the application / Edge Functions.
  note text,
  created_at timestamptz not null default now(),
  constraint chk_electricity_reading_order check (previous_reading is null or current_reading >= previous_reading)
);

create unique index one_periodic_reading_per_room_period
  on tb_electricity_reading (room_id, period_ym) where reading_type = 'PERIODIC';
create index idx_electricity_reading_room on tb_electricity_reading (room_id);
create index idx_electricity_reading_house on tb_electricity_reading (house_id);

create table tb_water_reading (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references tb_room (id) on delete cascade,
  house_id uuid not null references tb_house (id) on delete cascade,
  reading_type text not null check (reading_type in ('PERIODIC', 'MOVE_IN', 'MOVE_OUT')),
  period_ym date not null,
  contract_id uuid references tb_contract (id),
  reading_date date not null,
  previous_reading_id uuid references tb_water_reading (id),
  previous_reading numeric,
  current_reading numeric not null,
  usage_amount numeric generated always as (current_reading - previous_reading) stored,
  recorded_by_phone text not null,
  photo_url text,
  invoice_id uuid references tb_invoice (id),
  note text,
  created_at timestamptz not null default now(),
  constraint chk_water_reading_order check (previous_reading is null or current_reading >= previous_reading)
);

create unique index one_periodic_water_reading_per_room_period
  on tb_water_reading (room_id, period_ym) where reading_type = 'PERIODIC';
create index idx_water_reading_room on tb_water_reading (room_id);
create index idx_water_reading_house on tb_water_reading (house_id);

-- ============================================================
-- 12. tb_device_token — NOT in docs/DATABASE.md's entity list, added here because
-- docs/ARCHITECTURE.md requires it ("client đăng ký device token, lưu vào Supabase
-- để Edge Function gửi push") and DATABASE.md's header states 12 tables while only
-- 11 are individually documented — this is the most likely missing 12th table.
-- Flag for Dream to confirm/formalize in DATABASE.md.
-- ============================================================
create table tb_device_token (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references tb_user (id) on delete cascade,
  platform text not null check (platform in ('android', 'ios')),
  token text not null,
  created_at timestamptz not null default now(),
  unique (user_id, token)
);

create index idx_device_token_user on tb_device_token (user_id);

-- ============================================================
-- RLS helper functions
-- ============================================================
create or replace function current_user_phone()
returns text
language sql stable
as $$
  select nullif(auth.jwt() ->> 'phone', '')
$$;

create or replace function has_house_access(p_house_id uuid, p_role text default null)
returns boolean
language sql stable
as $$
  select exists (
    select 1 from tb_user_house_access
    where house_id = p_house_id
      and phone = current_user_phone()
      and (p_role is null or role = p_role)
  )
$$;

-- ============================================================
-- RLS policies
-- ============================================================

alter table tb_user enable row level security;
create policy "User reads/updates own row" on tb_user
  for all using (id = auth.uid());

alter table tb_house enable row level security;
create policy "House visible to members" on tb_house
  for select using (has_house_access(id));
create policy "Owner manages house" on tb_house
  for update using (has_house_access(id, 'owner'));
create policy "Owner deletes house" on tb_house
  for delete using (has_house_access(id, 'owner'));
create policy "Any authenticated user creates a house" on tb_house
  for insert to authenticated with check (true);

-- Auto-grant owner access to whoever creates a house.
create or replace function grant_owner_on_house_insert()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into tb_user_house_access (phone, house_id, role, granted_by_phone)
  values (current_user_phone(), new.id, 'owner', null);
  return new;
end;
$$;

create trigger trg_house_insert_grant_owner
  after insert on tb_house
  for each row execute function grant_owner_on_house_insert();

alter table tb_user_house_access enable row level security;
create policy "Members view access rows for their houses" on tb_user_house_access
  for select using (has_house_access(house_id));
create policy "Owner grants access" on tb_user_house_access
  for insert with check (has_house_access(house_id, 'owner'));
create policy "Owner revokes access they granted" on tb_user_house_access
  for delete using (
    has_house_access(house_id, 'owner')
    and (granted_by_phone = current_user_phone() or granted_by_phone is null)
  );

alter table tb_room enable row level security;
create policy "Room visible to members" on tb_room
  for select using (has_house_access(house_id));
create policy "Owner/manager manage rooms" on tb_room
  for insert with check (has_house_access(house_id));
create policy "Owner/manager update rooms" on tb_room
  for update using (has_house_access(house_id));
create policy "Owner/manager delete rooms" on tb_room
  for delete using (has_house_access(house_id));

alter table tb_tenant enable row level security;
create policy "Tenant pool scoped to house members" on tb_tenant
  for all using (has_house_access(house_id));

alter table tb_contract enable row level security;
create policy "Contract visible/manageable via room's house" on tb_contract
  for all using (
    exists (
      select 1 from tb_contract_room cr
      join tb_room r on r.id = cr.room_id
      where cr.contract_id = tb_contract.id and has_house_access(r.house_id)
    )
    -- also allow select right after insert, before tb_contract_room rows exist yet,
    -- by checking the tenant's house as a fallback
    or exists (
      select 1 from tb_tenant t where t.id = tb_contract.tenant_id and has_house_access(t.house_id)
    )
  );

alter table tb_contract_room enable row level security;
create policy "Contract room scoped via room's house" on tb_contract_room
  for all using (
    exists (select 1 from tb_room r where r.id = tb_contract_room.room_id and has_house_access(r.house_id))
  );

alter table tb_contract_version enable row level security;
create policy "Contract version scoped via contract" on tb_contract_version
  for all using (
    exists (
      select 1 from tb_contract c
      join tb_tenant t on t.id = c.tenant_id
      where c.id = tb_contract_version.contract_id and has_house_access(t.house_id)
    )
  );

alter table tb_invoice enable row level security;
create policy "Invoice scoped to house" on tb_invoice
  for all using (has_house_access(house_id));

alter table tb_electricity_reading enable row level security;
create policy "Electricity reading scoped to house" on tb_electricity_reading
  for all using (has_house_access(house_id));

alter table tb_water_reading enable row level security;
create policy "Water reading scoped to house" on tb_water_reading
  for all using (has_house_access(house_id));

alter table tb_device_token enable row level security;
create policy "User manages own device tokens" on tb_device_token
  for all using (user_id = auth.uid());

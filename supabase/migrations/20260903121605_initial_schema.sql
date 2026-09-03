-- Initial schema for BizTown Rent-Manager
-- Based on docs/DATABASE.md, docs/REQUIREMENTS.md, docs/BUSINESS-RULES.md
-- RLS policies enforce multi-tenant isolation per BUSINESS-RULES.md section 6.

-- ============================================================
-- landlords
-- ============================================================
create table landlords (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  phone text not null,
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table landlords enable row level security;

create policy "Landlord reads own profile"
  on landlords for select
  using (id = auth.uid());

create policy "Landlord updates own profile"
  on landlords for update
  using (id = auth.uid());

-- ============================================================
-- tenants (Tenant Pool — BR-CTR-06, exists independently of contract)
-- ============================================================
create table tenants (
  id uuid primary key default gen_random_uuid(),
  created_by_landlord_id uuid not null references landlords (id) on delete cascade,
  auth_user_id uuid references auth.users (id) on delete set null,
  full_name text not null,
  phone text not null,
  national_id text not null,
  national_id_photo_front_url text,
  national_id_photo_back_url text,
  gender text check (gender in ('M', 'F')),
  age int,
  created_at timestamptz not null default now()
);

alter table tenants enable row level security;

create policy "Landlord manages own tenants"
  on tenants for all
  using (created_by_landlord_id = auth.uid());

create policy "Tenant reads own profile"
  on tenants for select
  using (auth_user_id = auth.uid());

-- ============================================================
-- properties (Dãy trọ / Nhà)
-- ============================================================
create table properties (
  id uuid primary key default gen_random_uuid(),
  landlord_id uuid not null references landlords (id) on delete cascade,
  name text not null,
  address text not null,
  description text,
  photos text[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table properties enable row level security;

create policy "Landlord manages own properties"
  on properties for all
  using (landlord_id = auth.uid());

-- ============================================================
-- rooms
-- ============================================================
create table rooms (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references properties (id) on delete cascade,
  name text not null,
  area_m2 numeric,
  rent_price numeric not null,
  electricity_unit_price numeric,
  water_unit_price numeric,
  other_fees jsonb not null default '[]', -- [{name, amount}]
  amenities text[] not null default '{}',
  photos text[] not null default '{}',
  status text not null default 'vacant' check (status in ('vacant', 'occupied', 'under_maintenance')),
  is_public_listed boolean not null default false, -- BR-LIST-01/02
  created_at timestamptz not null default now()
);

alter table rooms enable row level security;

create policy "Landlord manages own rooms"
  on rooms for all
  using (
    exists (
      select 1 from properties
      where properties.id = rooms.property_id
      and properties.landlord_id = auth.uid()
    )
  );

-- Public read for listing search (Flow #3) — only publicly listed + vacant rooms.
create policy "Anyone authenticated can view public listed rooms"
  on rooms for select
  to authenticated
  using (is_public_listed = true and status = 'vacant');

-- ============================================================
-- contracts (1 phòng chỉ 1 hợp đồng Active tại 1 thời điểm — BR-CTR-04,
-- enforced via partial unique index below)
-- ============================================================
create table contracts (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references rooms (id) on delete restrict,
  tenant_id uuid not null references tenants (id) on delete restrict,
  start_date date not null,
  end_date date not null,
  deposit_amount numeric not null,
  rent_price numeric not null,
  electricity_unit_price numeric,
  water_unit_price numeric,
  late_fee_terms text,
  status text not null default 'active' check (status in ('active', 'ended')),
  created_at timestamptz not null default now()
);

create unique index one_active_contract_per_room
  on contracts (room_id)
  where (status = 'active');

alter table contracts enable row level security;

create policy "Landlord manages contracts on own rooms"
  on contracts for all
  using (
    exists (
      select 1 from rooms
      join properties on properties.id = rooms.property_id
      where rooms.id = contracts.room_id
      and properties.landlord_id = auth.uid()
    )
  );

create policy "Tenant reads own contracts"
  on contracts for select
  using (
    exists (
      select 1 from tenants
      where tenants.id = contracts.tenant_id
      and tenants.auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- meter_readings (ghi độc lập với hoá đơn — BR-CTR-07)
-- ============================================================
create table meter_readings (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references rooms (id) on delete cascade,
  period date not null, -- first day of the billing month
  electricity_reading numeric not null,
  water_reading numeric not null,
  recorded_at timestamptz not null default now(),
  unique (room_id, period)
);

alter table meter_readings enable row level security;

create policy "Landlord manages meter readings on own rooms"
  on meter_readings for all
  using (
    exists (
      select 1 from rooms
      join properties on properties.id = rooms.property_id
      where rooms.id = meter_readings.room_id
      and properties.landlord_id = auth.uid()
    )
  );

-- ============================================================
-- invoices
-- ============================================================
create table invoices (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references contracts (id) on delete restrict,
  period date not null,
  room_charge numeric not null,
  electricity_charge numeric not null default 0,
  water_charge numeric not null default 0,
  other_fees jsonb not null default '[]', -- [{name, amount}]
  total_amount numeric not null,
  due_date date not null,
  status text not null default 'unpaid'
    check (status in ('unpaid', 'pending_confirmation', 'paid', 'overdue')),
  sent_via text[] not null default '{}', -- push / sms / zalo
  created_at timestamptz not null default now(),
  unique (contract_id, period)
);

alter table invoices enable row level security;

create policy "Landlord manages invoices on own contracts"
  on invoices for all
  using (
    exists (
      select 1 from contracts
      join rooms on rooms.id = contracts.room_id
      join properties on properties.id = rooms.property_id
      where contracts.id = invoices.contract_id
      and properties.landlord_id = auth.uid()
    )
  );

create policy "Tenant reads own invoices"
  on invoices for select
  using (
    exists (
      select 1 from contracts
      join tenants on tenants.id = contracts.tenant_id
      where contracts.id = invoices.contract_id
      and tenants.auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- payments
-- ============================================================
create table payments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references invoices (id) on delete cascade,
  proof_photo_url text,
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'rejected')),
  confirmed_by_landlord_id uuid references landlords (id),
  confirmed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table payments enable row level security;

create policy "Landlord manages payments on own invoices"
  on payments for all
  using (
    exists (
      select 1 from invoices
      join contracts on contracts.id = invoices.contract_id
      join rooms on rooms.id = contracts.room_id
      join properties on properties.id = rooms.property_id
      where invoices.id = payments.invoice_id
      and properties.landlord_id = auth.uid()
    )
  );

create policy "Tenant manages own payment confirmations"
  on payments for all
  using (
    exists (
      select 1 from invoices
      join contracts on contracts.id = invoices.contract_id
      join tenants on tenants.id = contracts.tenant_id
      where invoices.id = payments.invoice_id
      and tenants.auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- maintenance_requests
-- ============================================================
create table maintenance_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete cascade,
  room_id uuid not null references rooms (id) on delete cascade,
  type text not null check (type in ('repair', 'maintenance', 'residency_registration', 'other')),
  description text not null,
  photos text[] not null default '{}',
  status text not null default 'new'
    check (status in ('new', 'in_progress', 'resolved', 'rejected')),
  landlord_note text,
  extra_cost numeric,
  created_at timestamptz not null default now()
);

alter table maintenance_requests enable row level security;

create policy "Landlord manages requests on own rooms"
  on maintenance_requests for all
  using (
    exists (
      select 1 from rooms
      join properties on properties.id = rooms.property_id
      where rooms.id = maintenance_requests.room_id
      and properties.landlord_id = auth.uid()
    )
  );

create policy "Tenant manages own requests"
  on maintenance_requests for all
  using (
    exists (
      select 1 from tenants
      where tenants.id = maintenance_requests.tenant_id
      and tenants.auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- rental_inquiries (Flow #3 — Yêu cầu liên hệ, BR-LIST-05: không tự tạo tenant/contract)
-- ============================================================
create table rental_inquiries (
  id uuid primary key default gen_random_uuid(),
  tenant_auth_user_id uuid not null references auth.users (id) on delete cascade,
  room_id uuid not null references rooms (id) on delete cascade,
  contact_phone text not null,
  status text not null default 'new' check (status in ('new', 'contacted', 'not_converted')),
  created_at timestamptz not null default now()
);

alter table rental_inquiries enable row level security;

create policy "Landlord manages inquiries on own rooms"
  on rental_inquiries for all
  using (
    exists (
      select 1 from rooms
      join properties on properties.id = rooms.property_id
      where rooms.id = rental_inquiries.room_id
      and properties.landlord_id = auth.uid()
    )
  );

create policy "Tenant manages own inquiries"
  on rental_inquiries for all
  using (tenant_auth_user_id = auth.uid());

-- Rate limit BR-LIST-06 (10 requests/day) enforced in application/Edge Function layer.

-- ============================================================
-- notifications (nguồn cho Trung tâm thông báo S-03)
-- ============================================================
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  related_entity_type text,
  related_entity_id uuid,
  channel text[] not null default '{}', -- push / sms / zalo
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table notifications enable row level security;

create policy "User reads own notifications"
  on notifications for select
  using (user_id = auth.uid());

create policy "User marks own notifications read"
  on notifications for update
  using (user_id = auth.uid());

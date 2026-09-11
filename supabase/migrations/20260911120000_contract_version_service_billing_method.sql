-- Figma T-05/T-06 (node 220:3552 / 220:3669) hiển thị "Service" y hệt pattern
-- Electricity/Water: 1 billing method + 1 giá/tháng. Thêm cột
-- service_billing_method để phân biệt Flat (nhập thẳng service_fee_amount)
-- và ByArea (giữ cách tính cũ service_fee_rate_per_sqm * contract_area_sqm).
-- Xem docs/DECISIONS.md Đợt 27.
alter table tb_contract_version
  add column service_billing_method text not null default 'ByArea'
    check (service_billing_method in ('Flat', 'ByArea'));

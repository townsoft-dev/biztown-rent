-- Figma H-02 "Default unit prices" section has Electricity /kWh and Water /m³
-- default price fields — docs/DATABASE.md's tb_house field list only ever had
-- service_fee_rate_per_sqm (a different concept: service fee per sqm, not
-- electricity/water unit price). Adding the 2 missing default price columns.
-- These are defaults only (auto-fill a new contract), never used for billing —
-- same rule as service_fee_rate_per_sqm, see docs/DATABASE.md "Đơn giá tồn tại ở 2 nơi".

alter table tb_house add column default_electricity_price numeric;
alter table tb_house add column default_water_price numeric;

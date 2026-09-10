-- Same gap as owner_phone (see 20260910131500) — Figma H-02 also has an
-- "Owner email" field that docs/DATABASE.md's tb_house field list never had.
alter table tb_house add column owner_email text;

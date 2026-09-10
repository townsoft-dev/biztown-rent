-- Figma H-02 (House Registration) has an "Owner phone" field that was missing
-- from the Version 3 tb_house schema rebuild — docs/DATABASE.md's tb_house
-- field list never listed it. Adding it now while wiring real CRUD for H-02.
-- See docs/DECISIONS.md 2026-09-10 for the gap + fix writeup.

alter table tb_house add column owner_phone text;

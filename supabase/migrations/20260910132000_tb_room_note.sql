-- Same class of gap as tb_house owner_phone/owner_email/default utility
-- prices (see migrations above) — Figma H-05 (Room Create/Edit) and H-04
-- (Room Detail) both show a free-text "Note" field that tb_room never had
-- a column for in the Version 3 schema rebuild.
alter table tb_room add column note text;

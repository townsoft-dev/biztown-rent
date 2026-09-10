-- Supabase Storage bucket for House/Room photos (tb_house.photos, tb_room.photos).
-- Private bucket — access follows the exact same rule as tb_house/tb_room rows
-- (has_house_access), reusing the helper function from 20260909133320_v3_schema_rebuild.sql.
-- Path convention: "<houseId>/houses/<file>" for house photos, "<houseId>/rooms/<roomId>/<file>"
-- for room photos — first path segment is always the houseId so one policy covers both.

insert into storage.buckets (id, name, public)
values ('property-photos', 'property-photos', false)
on conflict (id) do nothing;

create policy "House members read property photos"
on storage.objects for select
using (
  bucket_id = 'property-photos'
  and has_house_access((storage.foldername(name))[1]::uuid)
);

create policy "House members upload property photos"
on storage.objects for insert
with check (
  bucket_id = 'property-photos'
  and has_house_access((storage.foldername(name))[1]::uuid)
);

create policy "House members delete property photos"
on storage.objects for delete
using (
  bucket_id = 'property-photos'
  and has_house_access((storage.foldername(name))[1]::uuid)
);

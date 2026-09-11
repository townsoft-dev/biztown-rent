-- "Change photo" (P-02) — thêm cột ảnh đại diện cho tb_user + bucket Storage
-- riêng. Khác `property-photos` (dùng chung House/Room, quyền theo
-- has_house_access), avatar là dữ liệu CÁ NHÂN — chỉ chính chủ tài khoản mới
-- được đọc/ghi/xoá, không liên quan gì tới quyền truy cập Nhà/Phòng.

alter table tb_user add column avatar_path text;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false)
on conflict (id) do nothing;

-- Path convention: "<userId>/<file>" — first path segment is always the
-- owner's auth.uid(), so a single policy covers read/write/delete.
create policy "Users manage their own avatar"
on storage.objects for all
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

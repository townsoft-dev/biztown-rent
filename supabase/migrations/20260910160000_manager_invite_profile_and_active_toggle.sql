-- Đợt P-0x (Manager/Profile), quyết định chốt cùng dungtv 2026-09-10:
-- `tb_user_house_access` cần thêm 3 cột để hỗ trợ mời Manager qua P-06:
--
-- - full_name/id_number: hồ sơ do CHÍNH CHỦ NHÀ tự gõ lúc mời — không thể
--   lưu vào `tb_user` (RLS chỉ cho tự sửa hồ sơ của chính mình, chủ nhà
--   không có quyền viết hồ sơ hộ người khác), và người được mời có thể
--   CHƯA có tài khoản lúc mời — giống hệt mô hình `tb_tenant` đã làm (hồ sơ
--   độc lập, không bắt buộc khớp tài khoản thật của user).
-- - is_active: bật/tắt quyền truy cập TỪNG nhà mà KHÔNG xoá hẳn dòng cấp
--   quyền (khác "Remove" = xoá thật, đã có sẵn) — cho phép tạm ngưng rồi
--   bật lại, không mất lịch sử ai cấp/lúc nào.
alter table tb_user_house_access
  add column full_name text,
  add column id_number text,
  add column is_active boolean not null default true;

comment on column tb_user_house_access.full_name is 'Tên do chủ nhà tự nhập lúc mời (P-06) — độc lập với tb_user.full_name thật của người đó nếu có tài khoản, giống mô hình tb_tenant.';
comment on column tb_user_house_access.id_number is 'CCCD/CMND do chủ nhà tự nhập lúc mời, optional.';
comment on column tb_user_house_access.is_active is 'Bật/tắt quyền truy cập nhà này — tắt thì mất quyền ngay (has_house_access kiểm tra cột này) nhưng dòng vẫn còn để bật lại sau, khác xoá hẳn.';

-- has_house_access() phải kiểm tra thêm is_active — tắt quyền 1 nhà phải có
-- hiệu lực ngay trên MỌI bảng RLS dựa vào hàm này (tb_house/tb_room/...),
-- không chỉ ẩn ở UI. Giữ nguyên security definer (đã sửa ở migration
-- 20260910140000 để tránh đệ quy).
create or replace function has_house_access(p_house_id uuid, p_role text default null)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from tb_user_house_access
    where house_id = p_house_id
      and phone = current_user_phone()
      and is_active = true
      and (p_role is null or role = p_role)
  )
$$;

-- Trước đó tb_user_house_access chỉ có policy INSERT (mời)/DELETE (thu hẳn
-- quyền) — chưa có UPDATE nên không sửa được full_name/id_number/is_active
-- sau khi đã mời. Cho phép bất kỳ ai đang là owner của nhà đó sửa (không
-- giới hạn "đúng người đã cấp" như DELETE — bật/tắt tạm thời là hành vi
-- quản trị nhẹ hơn thu quyền hẳn).
create policy "Owner updates access rows for their houses" on tb_user_house_access
  for update using (has_house_access(house_id, 'owner'))
  with check (has_house_access(house_id, 'owner'));

-- Đảo ngược 1 phần giới hạn của quyết định Đợt 20 (2026-09-10): trước đó 1
-- Manager BẮT BUỘC phải gắn với ít nhất 1 dòng cấp quyền theo Nhà mới "tồn
-- tại" được — nếu Save P-06 mà chưa tick Nhà nào (VD nhà duy nhất đã có
-- Manager active khác nên checkbox bị disable), toàn bộ form bị mất trắng,
-- không báo lỗi (phát hiện lúc dungtv test lại toàn bộ luồng 11/09/2026).
-- dungtv xác nhận muốn tạo trước 1 hồ sơ Manager rồi gán Nhà sau, nên đổi
-- kiến trúc: `house_id` được phép NULL, đại diện cho 1 hồ sơ Manager "nháp"
-- (draft) — CHƯA gán Nhà nào — do đúng người mời (`granted_by_phone`) tạo
-- ra và sở hữu, độc lập với các Owner khác (giữ đúng tinh thần cách ly dữ
-- liệu giữa các Owner khác nhau đã có từ Đợt 20: mỗi Owner tự nhập/tự thấy
-- hồ sơ Manager của riêng mình, không chia sẻ giữa các Owner dù trùng SĐT).

alter table tb_user_house_access alter column house_id drop not null;

-- Chỉ cho phép ĐÚNG 1 dòng "nháp" (house_id null) mỗi cặp (SĐT Manager,
-- Owner đã mời) — tránh 1 Owner vô tình tạo trùng nhiều hồ sơ nháp cho cùng
-- 1 SĐT. Không ảnh hưởng `one_active_manager_per_house` (chỉ áp cho dòng có
-- house_id thật) vì NULL không bao giờ bị Postgres coi là trùng nhau trong
-- unique index.
create unique index one_draft_profile_per_owner
  on tb_user_house_access (phone, granted_by_phone)
  where role = 'manager' and house_id is null;

-- RLS: policy cũ (`has_house_access(house_id, ...)`) luôn false khi house_id
-- NULL nên hoàn toàn không áp dụng được cho dòng nháp — thêm 1 policy riêng,
-- chỉ chính Owner đã tạo dòng nháp đó (`granted_by_phone`) mới đọc/sửa/xoá
-- được, không Owner nào khác thấy được hồ sơ nháp của người khác dù trùng
-- SĐT Manager.
create policy "Owner manages their own draft manager profiles"
  on tb_user_house_access
  for all
  using (
    house_id is null
    and role = 'manager'
    and granted_by_phone = current_user_phone()
  )
  with check (
    house_id is null
    and role = 'manager'
    and granted_by_phone = current_user_phone()
  );

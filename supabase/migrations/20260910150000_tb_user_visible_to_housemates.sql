-- Phát hiện lúc làm field "Manager" ở H-03 (dungtv báo thiếu, đối chiếu lại
-- Figma xác nhận đúng có field này, xem docs/DECISIONS.md 2026-09-10 Đợt 19):
-- tb_user trước đó chỉ cho đọc ĐÚNG dòng của chính mình ("id = auth.uid()"),
-- nên không có cách nào lấy full_name của Manager mình đã mời (hoặc của chủ
-- nhà, nếu đang xem với vai trò manager) — dù DATABASE.md mục "Vai trò &
-- phân quyền" đã ghi rõ ý định ("Riêng tư khi mời... chỉ hiển thị tên ở dạng
-- che một phần") ngụ ý phải xem được tên người cùng truy cập 1 Nhà.
--
-- Thêm 1 policy SELECT mới: cho phép đọc tb_user của người khác NẾU người đó
-- và mình cùng có ít nhất 1 dòng quyền (tb_user_house_access) trỏ tới cùng 1
-- houseId — tức "housemate" (chủ nhà xem tên manager, manager xem tên chủ
-- nhà, hoặc 2 manager cùng nhà xem nhau). Không phải security definer — chạy
-- với quyền người gọi bình thường, nên subquery trên tb_user_house_access
-- vẫn tự bị RLS của chính bảng đó lọc lại (has_house_access, đã sửa security
-- definer ở migration trước) — không có nguy cơ đệ quy vì đây là 2 bảng khác
-- nhau (tb_user tham chiếu tb_user_house_access), không phải tự tham chiếu.
create policy "Members see profiles of housemates" on tb_user
  for select using (
    exists (
      select 1
      from tb_user_house_access mine
      join tb_user_house_access theirs on theirs.house_id = mine.house_id
      where mine.phone = current_user_phone()
        and theirs.phone = tb_user.phone
    )
  );

-- Bật Realtime cho `tb_notification` — S-03 Notification Center/chuông ở
-- Home cần tự cập nhật ngay khi có thông báo mới do NGƯỜI KHÁC (quản lý
-- khác, hoặc backend) tạo ra trong lúc app đang mở sẵn, không chỉ khi chính
-- người dùng vừa thao tác xong (dungtv yêu cầu 2026-09-15 — "thông báo mà
-- không hiện luôn thì cùi lắm"). RLS SELECT có sẵn (`recipient_phone =
-- current_user_phone()`) tự áp dụng cho cả luồng Realtime, không cần thêm
-- policy riêng.
alter publication supabase_realtime add table tb_notification;

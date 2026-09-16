-- Vá 2 lỗi thật của cơ chế token Zalo (phát hiện 16/09/2026, xem
-- docs/DECISIONS.md Đợt 48):
--
-- 1. TRANH CHẤP KHI LÀM MỚI TOKEN — lỗi nghiêm trọng, chắc chắn nổ ở B-03.
--    Refresh token của Zalo là loại DÙNG 1 LẦN: mỗi lần làm mới, Zalo trả về
--    cặp access+refresh MỚI và huỷ hiệu lực cặp cũ NGAY. Chức năng "gửi hoá
--    đơn hàng loạt" gửi nhiều tin song song (Promise.all) — nếu token vừa hết
--    hạn, tất cả các tin sẽ cùng lúc gọi làm mới với CÙNG 1 refresh token:
--    1 cái thành công, phần còn lại thất bại VÀ làm chết token (vì Zalo đã
--    huỷ cái cũ). Đây đúng là tình trạng đã xảy ra thật ngày 16/09.
--    → Thêm `refresh_lock_until` làm khoá: chỉ tiến trình giành được khoá mới
--      được gọi Zalo, các tiến trình khác chờ rồi đọc lại token mới.
--
-- 2. HẾT HẠN VÌ KHÔNG AI DÙNG — refresh token sống ~3 tháng. Nếu suốt 3 tháng
--    không ai gửi hoá đơn qua Zalo thì không có gì kích hoạt làm mới, token
--    chết hẳn và phải xin cấp lại tay.
--    → Bật pg_cron + pg_net, đặt lịch tự gọi Edge Function `refresh-zalo-token`
--      mỗi tuần, không phụ thuộc việc có ai dùng app hay không.

alter table tb_zalo_token
  add column if not exists refresh_lock_until timestamptz;

comment on column tb_zalo_token.refresh_lock_until is
  'Khoá chống 2 tiến trình cùng làm mới token (refresh token Zalo chỉ dùng được 1 lần). Tiến trình giành khoá đặt giá trị = now() + ~30s; tiến trình khác thấy khoá còn hiệu lực thì chờ và đọc lại token mới thay vì tự gọi Zalo.';

create extension if not exists pg_cron;
create extension if not exists pg_net;

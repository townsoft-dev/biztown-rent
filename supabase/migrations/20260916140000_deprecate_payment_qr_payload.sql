-- Đánh dấu `tb_invoice.payment_qr_payload` là BỎ DÙNG (16/09/2026).
--
-- Cột này lưu chuỗi VietQR sinh tại thời điểm TẠO hoá đơn — tức là chụp lại số
-- tài khoản của chủ nhà ở thời điểm đó. Chủ trọ đổi số tài khoản sau đó thì
-- chuỗi cũ KHÔNG được cập nhật, người thuê quét vào là chuyển tiền sang tài
-- khoản đã bỏ. Dữ liệu thật đã dính đúng lỗi này: có hoá đơn giữ QR trỏ tới
-- `0071000112233 / LE THI MAI` trong khi nhà đó nay dùng
-- `9697354961 / TRAN VAN DUNG`.
--
-- Cách làm đúng (đã áp dụng): QR sinh TẠI THỜI ĐIỂM NGƯỜI THUÊ XEM, trong Edge
-- Function `invoice-public`, luôn đọc tài khoản hiện hành từ `tb_house`. Sinh
-- chuỗi QR chỉ là phép ghép chuỗi nên không tốn gì đáng kể.
--
-- KHÔNG xoá cột ngay: xoá cột là thao tác không khôi phục được, mà giữ lại cũng
-- không hại gì (không còn ai ghi, không còn ai đọc). Xoá hẳn khi dungtv xác
-- nhận không cần dữ liệu cũ nữa.

comment on column tb_invoice.payment_qr_payload is
  'BỎ DÙNG từ 16/09/2026 — KHÔNG đọc cột này. Chuỗi lưu ở đây là ảnh chụp số tài khoản lúc tạo hoá đơn, sẽ SAI nếu chủ nhà đổi tài khoản sau đó. Mã QR phải luôn được sinh mới từ tb_house tại thời điểm hiển thị (xem Edge Function invoice-public).';

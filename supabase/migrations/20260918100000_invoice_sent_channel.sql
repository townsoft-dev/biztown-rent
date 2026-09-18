-- Ghi lại hoá đơn đã gửi qua KÊNH nào.
--
-- Thiết kế B-01 (Figma) hiện dòng phụ "sent 05/09 via Zalo" — tức chữ phụ
-- phải nêu cả ngày gửi lẫn kênh gửi. Trước đây bảng chỉ có `sent_at`, không
-- có chỗ nào ghi kênh, nên app chỉ hiện được ngày (dungtv phát hiện khi đối
-- chiếu B-01 với thiết kế, 18/09/2026).
--
-- Để `text` tự do thay vì enum: danh sách kênh còn thay đổi (Zalo ZNS chưa
-- mua gói), thêm kênh mới bằng enum thì phải migrate lại cả cột.
alter table tb_invoice
  add column if not exists sent_channel text;

comment on column tb_invoice.sent_channel is
  'Kênh đã gửi hoá đơn: sms | email | zalo. NULL nghĩa là chưa gửi, hoặc đã '
  'gửi trước 18/09/2026 khi hệ thống chưa ghi nhận kênh — app hiển thị lùi về '
  'dạng chỉ có ngày gửi trong trường hợp đó.';

-- Chặn dò mã hoá đơn tự động cho endpoint tra cứu công khai
-- (`invoice-public`). Endpoint này KHÔNG yêu cầu đăng nhập (người thuê không
-- có tài khoản BizTown) nên phải tự chống lạm dụng.
--
-- Chỉ ghi lại lần tra cứu THẤT BẠI, không ghi lần thành công. Lý do: người
-- thuê thật luôn bấm đúng link nên gần như không bao giờ trượt; còn kẻ dò mã
-- thì hầu hết là trượt. Ghi theo hướng này vừa bắt đúng đối tượng cần chặn,
-- vừa không vô tình khoá nhầm nhiều người thuê dùng chung một đường mạng
-- (văn phòng, wifi nhà trọ... đều ra cùng 1 IP).

create table tb_invoice_lookup_failure (
  id bigserial primary key,
  ip text not null,
  attempted_at timestamptz not null default now()
);

create index idx_invoice_lookup_failure_ip
  on tb_invoice_lookup_failure (ip, attempted_at desc);

-- Bảng chỉ để Edge Function (service role) ghi/đọc; không mở cho client nào.
alter table tb_invoice_lookup_failure enable row level security;

comment on table tb_invoice_lookup_failure is
  'Nhật ký các lần tra cứu mã hoá đơn công khai THẤT BẠI, dùng để chặn dò mã theo IP. Chỉ Edge Function invoice-public ghi vào đây.';

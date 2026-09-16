-- Mã tra cứu công khai cho từng hoá đơn — dùng làm link gửi kèm SMS
-- (`bill.<domain>/<mã>`) để người thuê mở xem hoá đơn + mã QR thanh toán mà
-- KHÔNG cần tài khoản BizTown (người thuê không dùng app — xem docs/CLAUDE.md
-- mục 1). Chi tiết thiết kế xem docs/SMS-HOA-DON.md và docs/DECISIONS.md.
--
-- Vì sao KHÔNG dùng thẳng `tb_invoice.id` (uuid) làm mã:
-- 1. uuid dài 36 ký tự, nhét vào SMS rất tốn (tin tính phí theo đoạn 160 ký tự);
-- 2. id là khoá nội bộ đang dùng cho phân quyền ở nhiều nơi — lộ ra ngoài cho
--    người không có tài khoản là mở rộng bề mặt tấn công không cần thiết;
-- 3. cần thu hồi được riêng lẻ khi nghi lộ link, mà id thì không đổi được.

-- Bảng chữ cái Crockford Base32: bỏ I, L, O, U để không nhìn nhầm với 1, 0.
-- Đúng 32 ký tự nên mỗi byte ngẫu nhiên chia lấy dư 32 là chia đều tuyệt đối,
-- không lệch xác suất (nếu dùng bảng 31 hay 33 ký tự sẽ có ký tự hay ra hơn
-- ký tự khác, làm giảm độ khó đoán).
create or replace function generate_invoice_public_code()
returns text
language plpgsql
volatile
as $$
declare
  alphabet constant text := '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  code_length constant int := 12;
  bytes bytea;
  result text := '';
  i int;
begin
  -- gen_random_bytes (pgcrypto) là nguồn ngẫu nhiên an toàn mật mã.
  -- KHÔNG dùng random() của Postgres: nó có thể đoán trước được, không đủ an
  -- toàn cho thứ đóng vai trò như mật khẩu truy cập hoá đơn.
  bytes := gen_random_bytes(code_length);
  for i in 0..code_length - 1 loop
    result := result || substr(alphabet, (get_byte(bytes, i) % 32) + 1, 1);
  end loop;
  return result;
end;
$$;

comment on function generate_invoice_public_code() is
  '12 ký tự Crockford Base32 (~60 bit, khoảng 1,15 tỷ tỷ tổ hợp) sinh bằng nguồn ngẫu nhiên an toàn mật mã. Dùng làm mã tra cứu hoá đơn công khai gửi trong SMS.';

alter table tb_invoice
  add column if not exists public_code text;

-- Điền mã cho toàn bộ hoá đơn đã có, để tin nhắn gửi lại cho hoá đơn cũ cũng
-- có link mở được (không chỉ hoá đơn tạo từ sau đợt này).
update tb_invoice
set public_code = generate_invoice_public_code()
where public_code is null;

alter table tb_invoice
  alter column public_code set default generate_invoice_public_code(),
  alter column public_code set not null;

-- UNIQUE vừa là ràng buộc đúng đắn (2 hoá đơn không được trùng mã) vừa đóng
-- vai trò index cho chính truy vấn tra cứu theo mã của trang công khai.
create unique index if not exists idx_invoice_public_code
  on tb_invoice (public_code);

comment on column tb_invoice.public_code is
  'Mã tra cứu công khai gửi trong SMS. KHÔNG hết hạn (người thuê mở lại tin nhắn cũ vẫn xem được hoá đơn cũ — yêu cầu nghiệp vụ), nhưng đổi được bằng generate_invoice_public_code() nếu nghi lộ link.';

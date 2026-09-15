-- Lưu access/refresh token của Zalo OA (ZNS) — KHÁC với các secret tĩnh
-- (ZALO_APP_ID/ZALO_APP_SECRET, đặt qua `supabase secrets set`) vì access
-- token Zalo hết hạn sau ~1 giờ, và MỖI LẦN làm mới bằng refresh token thì
-- Zalo trả về 1 cặp access+refresh token MỚI (refresh token cũ mất hiệu
-- lực) — cần 1 chỗ ghi lại được, không phải giá trị tĩnh. Chỉ 1 dòng duy
-- nhất (`id = 'default'`), chỉ Edge Function (service role) đọc/ghi — không
-- có policy nào cho user thường, mặc định deny hết với RLS bật.
create table tb_zalo_token (
  id text primary key default 'default',
  access_token text not null,
  refresh_token text not null,
  expires_at timestamptz not null,
  updated_at timestamptz not null default now()
);

alter table tb_zalo_token enable row level security;

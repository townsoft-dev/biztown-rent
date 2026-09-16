-- Lịch tự động gia hạn token Zalo mỗi tuần (xem docs/DECISIONS.md Đợt 48).
--
-- Refresh token Zalo sống ~3 tháng. Nếu chỉ làm mới lúc gửi hoá đơn mà suốt
-- 3 tháng không ai gửi qua Zalo thì token chết hẳn, phải xin cấp lại tay —
-- đúng sự cố đã xảy ra thật ngày 16/09/2026. Lịch này gọi Edge Function
-- `refresh-zalo-token` mỗi tuần (08:00 thứ Hai, giờ VN = 01:00 UTC) để mỗi
-- lần Zalo cấp cặp token mới, đồng hồ 3 tháng được đặt lại từ đầu.
--
-- Service role key KHÔNG nhúng thẳng vào định nghĩa cron mà đọc từ Vault
-- (`vault.decrypted_secrets`), tránh lộ khoá trong bảng `cron.job` vốn ai đọc
-- được database cũng xem được.

select cron.schedule(
  'refresh-zalo-token-weekly',
  '0 1 * * 1',
  $$
  select net.http_post(
    url := 'https://rrtppoibjprlvasnbvwr.supabase.co/functions/v1/refresh-zalo-token',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (
        select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key' limit 1
      )
    ),
    body := '{}'::jsonb
  );
  $$
);

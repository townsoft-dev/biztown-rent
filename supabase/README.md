# RentEase — Supabase (Backend)

Backend chạy hoàn toàn trên Supabase: Postgres DB, Auth, Storage, và Edge Functions cho logic phía server.

## Setup lần đầu

1. Cài [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started).
2. `supabase login` — đăng nhập (cần mở trình duyệt để xác thực; hoặc dùng Access Token qua biến môi trường `SUPABASE_ACCESS_TOKEN` để chạy CLI không cần tương tác).
3. `supabase init` trong thư mục `supabase/` (hoặc root, tùy cấu hình) để sinh `config.toml`.
4. `supabase link --project-ref <project-ref>` để gắn với project Supabase đã tạo trên dashboard.

## Cấu trúc

- `functions/` — Edge Functions (Deno), ví dụ: sinh Bill hàng tháng, gửi Email/SMS.
- `migrations/` — SQL migration cho schema (house, room, tenant, contract, meter_reading, bill).

## Lịch định kỳ (thay Vercel Cron)

Dùng Supabase **Scheduled Triggers** (dựa trên `pg_cron`) để gọi Edge Function sinh Bill theo lịch hàng tháng.

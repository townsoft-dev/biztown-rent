# BizTown Rent-Manager — Supabase (Backend)

Backend chạy hoàn toàn trên Supabase: Postgres DB, Auth, Storage, và Edge Functions cho logic phía server.

## Setup lần đầu

Supabase CLI đã cài sẵn (npm devDependency ở root, xem `package.json`) — chạy qua `npx supabase ...`, không cần cài global.

1. `npx supabase login` — đăng nhập (cần mở trình duyệt để xác thực; hoặc dùng Access Token qua biến môi trường `SUPABASE_ACCESS_TOKEN` để chạy CLI không cần tương tác).
2. Tạo project trên [Supabase Dashboard](https://supabase.com/dashboard) (cân nhắc tạo dưới tài khoản khách hàng để dễ bàn giao sau).
3. `npx supabase init` ở root repo để sinh `config.toml`.
4. `npx supabase link --project-ref <project-ref>` để gắn với project vừa tạo.

## Cấu trúc

- `functions/` — Edge Functions (Deno), ví dụ: sinh Bill hàng tháng, gửi Email/SMS.
- `migrations/` — SQL migration cho schema (house, room, tenant, contract, meter_reading, bill).

## Lịch định kỳ (thay Vercel Cron)

Dùng Supabase **Scheduled Triggers** (dựa trên `pg_cron`) để gọi Edge Function sinh Bill theo lịch hàng tháng.

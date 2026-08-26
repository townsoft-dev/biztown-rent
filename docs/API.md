# API.md — Đặc tả API

## CRUD (House, Room, Tenant, Contract, Bill...)

Không có API tự viết — dùng trực tiếp **Supabase auto-generated REST/GraphQL API** (PostgREST) từ schema database, bảo vệ bằng Row Level Security (RLS). Xem [DATABASE.md](DATABASE.md) cho schema.

## Edge Functions (logic phía server)

| Function | Mô tả | Trigger |
|----------|-------|---------|
| TBD (ví dụ: `generate-bill`) | Sinh Bill hàng tháng từ meter_reading + contract | Scheduled Trigger (pg_cron), hàng tháng |
| TBD (ví dụ: `send-notification`) | Gửi Bill qua Email/SMS | Gọi từ `generate-bill` hoặc thủ công |

> Cập nhật danh sách Edge Functions cụ thể khi triển khai (`supabase/functions/`).

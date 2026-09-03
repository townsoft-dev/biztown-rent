# API.md — Đặc tả API

## CRUD (Property, Room, Tenant, Contract, Invoice...)

Không có API tự viết — dùng trực tiếp **Supabase auto-generated REST/GraphQL API** (PostgREST) từ schema database, bảo vệ bằng Row Level Security (RLS). Xem [DATABASE.md](DATABASE.md) cho schema.

## Edge Functions (logic phía server)

| Function | Mô tả | Trigger |
|----------|-------|---------|
| TBD (ví dụ: `generate-invoice`) | Sinh Invoice hàng tháng từ meter_reading + contract | Scheduled Trigger (pg_cron), hàng tháng |
| TBD (ví dụ: `send-notification`) | Gửi thông báo qua Push (FCM/APNs) + SMS/Zalo | Gọi từ `generate-invoice`, nhắc thanh toán, hoặc sự kiện khác (yêu cầu mới...) |
| TBD (ví dụ: `send-otp-sms`) | Auth Hook (Send SMS) — gửi OTP đăng nhập qua nhà cung cấp SMS Việt Nam | Supabase Auth gọi khi user đăng nhập/đăng ký |

> Cập nhật danh sách Edge Functions cụ thể khi triển khai (`supabase/functions/`).

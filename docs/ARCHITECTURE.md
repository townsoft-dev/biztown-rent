# ARCHITECTURE.md — Kiến trúc hệ thống

## Stack

- **Frontend**: Flutter (mobile app, iOS/Android) — thư mục `src/`.
- **Backend**: Supabase (Postgres DB, Auth, Storage, Edge Functions) — thư mục `supabase/`. Không dùng thêm Vercel, không dùng thêm Firebase (Auth Phone/OTP dùng Supabase Auth + custom Send SMS hook — xem [DECISIONS.md](DECISIONS.md)).
- **Auth**: Supabase Auth, đăng nhập bằng Số điện thoại + OTP (`signInWithOtp` / `verifyOtp`) — gửi OTP qua **Send SMS Hook** tuỳ chỉnh, cắm nhà cung cấp SMS brandname Việt Nam (eSMS/Speedsms — xem [REQUIREMENTS.md](REQUIREMENTS.md) INT-02/INT-03).
- **Notification**: 2 kênh song song cho **cả Landlord và Tenant** — Push notification (trong app) + SMS/Zalo (ngoài app) — xem [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 5.

## Thành phần

- **src/** — Flutter mobile app. Kết nối trực tiếp Supabase qua SDK `supabase_flutter` (anon key) cho CRUD thông thường (Property/House, Room, Tenant, Contract, Invoice/Bill...), có RLS (Row Level Security) bảo vệ dữ liệu — cách ly theo từng Landlord (multi-tenant) và theo từng Tenant, xem [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 6 (Data Isolation).
  - Nhận Push notification qua Firebase Cloud Messaging (Android) / APNs (iOS) — client đăng ký device token, lưu vào Supabase để Edge Function gửi push khi cần.
- **supabase/** — Edge Functions (Deno) + migrations. Dùng cho:
  - Sinh Bill/Invoice hàng tháng (tính toán từ số liệu check meter), chạy theo lịch qua Scheduled Triggers (`pg_cron`).
  - Gửi thông báo qua **Push (FCM/APNs) + SMS/Zalo** song song cho các sự kiện quan trọng (hoá đơn mới, nhắc thanh toán, yêu cầu mới...) — cần gọi API bên thứ ba, không gọi trực tiếp từ mobile app.
  - Auth Hook tuỳ chỉnh (Send SMS) để gửi OTP qua nhà cung cấp SMS Việt Nam thay vì provider mặc định của Supabase (Twilio/MessageBird/Vonage không phải SMS brandname VN).
  - Tác vụ cần Supabase service-role key (không được nhúng vào app client).
- **tests/** — Test cho Flutter app và Edge Functions.
- **design/** — File thiết kế UI/UX (Figma + logo assets).

## Sơ đồ tổng quát

```
[Flutter App] --Supabase SDK (anon key)--> [Supabase: Auth/DB/Storage]
      |                                            |
      | FCM/APNs device token                [Scheduled Trigger: pg_cron]
      |                                            |
      |                                  [Edge Function] --service-role key--> [Supabase DB]
      |                                            |
      +<----------- Push (FCM/APNs) ---------------+-------> [SMS/Zalo Gateway]
                                                    |
                                        [Send SMS Hook] --> [SMS brandname VN provider] (cho OTP đăng nhập)
```

> Cập nhật chi tiết khi triển khai cụ thể (schema Supabase, danh sách Edge Functions, chọn nhà cung cấp SMS/Zalo cụ thể...).

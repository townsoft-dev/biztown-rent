# ARCHITECTURE.md — Kiến trúc hệ thống
> **Version 2 — Last updated 2026-09-03.** Cập nhật theo scope Phase 1 mới: chỉ Landlord + Manager dùng app, Tenant không có tài khoản/app. Xem [DECISIONS.md](DECISIONS.md).

## Stack

- **Frontend**: Flutter (mobile app, iOS/Android) — thư mục `src/`.
- **Backend**: Supabase (Postgres DB, Auth, Storage, Edge Functions) — thư mục `supabase/`. Không dùng thêm Vercel, không dùng thêm Firebase (Auth Phone/OTP dùng Supabase Auth + custom Send SMS hook — xem [DECISIONS.md](DECISIONS.md)).
- **Auth**: Supabase Auth cho **2 loại tài khoản app**, cả hai đều là row trong `auth.users` (không có bảng auth tự viết riêng — xem [DATABASE.md](DATABASE.md)): Landlord (tự đăng ký, SĐT + OTP + mật khẩu — `signInWithOtp`/`verifyOtp`) và Manager (**do Landlord tạo trực tiếp qua Edge Function dùng service-role key + Supabase Admin API `auth.admin.createUser`** — không phải self-service signup; Landlord nhập SĐT + mật khẩu tạm, Manager đăng nhập bằng SĐT + mật khẩu đó, không cần OTP lúc tạo). OTP gửi qua **Send SMS Hook** tuỳ chỉnh, cắm nhà cung cấp SMS brandname Việt Nam (eSMS/Speedsms — xem [REQUIREMENTS.md](REQUIREMENTS.md) INT-02/INT-03). **Tenant không có `auth.users` row** trong Phase 1 — chỉ là bản ghi dữ liệu (`tenant` table), không đăng nhập được.
- **Notification**: 2 kênh khác nhau theo đối tượng — Push notification trong app **chỉ cho Landlord/Manager**; SMS/Zalo **một chiều tới Tenant** (không có kênh push/in-app cho Tenant vì không có app) — xem [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 5.

## Thành phần

- **src/** — Flutter mobile app, chỉ phục vụ Landlord & Manager (1 app, 2 role UI khác nhau tuỳ quyền). Kết nối trực tiếp Supabase qua SDK `supabase_flutter` (anon key) cho CRUD thông thường (House, Room, Tenant, Contract/ContractVersion, Invoice...), có RLS (Row Level Security) bảo vệ dữ liệu — cách ly theo từng Landlord (multi-tenant) và theo phạm vi Nhà/Dãy trọ được cấp cho từng Manager (`manager_house_access`), xem [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 6 (Data Isolation).
  - Nhận Push notification qua Firebase Cloud Messaging (Android) / APNs (iOS) — client đăng ký device token, lưu vào Supabase để Edge Function gửi push khi cần. Chỉ áp dụng cho Landlord/Manager.
- **supabase/** — Edge Functions (Deno) + migrations. Dùng cho:
  - Sinh Bill/Invoice hàng tháng (tính toán từ chỉ số điện/nước nhập trực tiếp lúc tạo hoá đơn — không còn bước ghi số riêng), chạy thủ công từ Bill Management hoặc theo lịch qua Scheduled Triggers (`pg_cron`) nếu cần nhắc tự động.
  - Gửi thông báo: **Push (FCM/APNs) cho Landlord/Manager** + **SMS/Zalo cho Tenant** — cần gọi API bên thứ ba, không gọi trực tiếp từ mobile app.
  - Auth Hook tuỳ chỉnh (Send SMS) để gửi OTP qua nhà cung cấp SMS Việt Nam thay vì provider mặc định của Supabase (Twilio/MessageBird/Vonage không phải SMS brandname VN). Chỉ dùng cho luồng đăng ký/quên mật khẩu của Landlord (Manager không tự đăng ký nên không cần OTP khi tạo tài khoản, chỉ cần khi quên mật khẩu).
  - Tác vụ cần Supabase service-role key (không được nhúng vào app client).
- **tests/** — Test cho Flutter app và Edge Functions.
- **design/** — File thiết kế UI/UX (Figma + logo assets).

## Sơ đồ tổng quát

```
[Flutter App: Landlord/Manager] --Supabase SDK (anon key)--> [Supabase: Auth/DB/Storage]
      |                                            |
      | FCM/APNs device token                [Scheduled Trigger: pg_cron - optional]
      |                                            |
      |                                  [Edge Function] --service-role key--> [Supabase DB]
      |                                            |
      +<----------- Push (FCM/APNs) ---------------+-------> [SMS/Zalo Gateway] --> [Tenant: nhận SMS/Zalo, không có app]
                                                    |
                                        [Send SMS Hook] --> [SMS brandname VN provider] (cho OTP đăng ký/quên mật khẩu Landlord)
```

> Cập nhật chi tiết khi triển khai cụ thể (schema Supabase, danh sách Edge Functions, chọn nhà cung cấp SMS/Zalo cụ thể...).

# ARCHITECTURE.md — Kiến trúc hệ thống

## Stack

- **Frontend**: Flutter (mobile app, iOS/Android) — thư mục `src/`.
- **Backend**: Supabase (Postgres DB, Auth, Storage, Edge Functions) — thư mục `supabase/`. Không dùng thêm Vercel.

## Thành phần

- **src/** — Flutter mobile app. Kết nối trực tiếp Supabase qua SDK `supabase_flutter` (anon key) cho CRUD thông thường (House, Room, Tenant, Contract, Bill), có RLS (Row Level Security) bảo vệ dữ liệu.
- **supabase/** — Edge Functions (Deno) + migrations. Dùng cho:
  - Sinh Bill hàng tháng (tính toán từ số liệu check meter), chạy theo lịch qua Scheduled Triggers (`pg_cron`).
  - Gửi thông báo Bill qua Email/SMS (cần gọi API bên thứ ba, không gọi trực tiếp từ mobile app).
  - Tác vụ cần Supabase service-role key (không được nhúng vào app client).
- **tests/** — Test cho Flutter app và Edge Functions.
- **design/** — File thiết kế UI/UX.

## Sơ đồ tổng quát

```
[Flutter App] --Supabase SDK (anon key)--> [Supabase: Auth/DB/Storage]
                                                    |
                                            [Scheduled Trigger: pg_cron]
                                                    |
                                          [Edge Function] --service-role key--> [Supabase DB]
                                                    |
                                          [Email API / SMS Gateway]
```

> Cập nhật chi tiết khi triển khai cụ thể (schema Supabase, danh sách Edge Functions...).

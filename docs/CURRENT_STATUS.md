# CURRENT_STATUS.md — Trạng thái hiện tại

## Giai đoạn

Khởi tạo (init) — chưa có tính năng nào được xây dựng.

## Đã xong

- [x] Cấu trúc thư mục repo (src/, supabase/, tests/, design/, docs/)
- [x] Chốt stack: Flutter (frontend) + Supabase-only (backend, không dùng Vercel)

## Đang làm / Tiếp theo

- [ ] Cài Flutter SDK, chạy `flutter create .` trong `src/`
- [ ] Cài Supabase CLI, tạo project Supabase, `supabase init`/`supabase link`
- [ ] Thiết kế schema (house, room, tenant, contract, meter_reading, bill) trong `supabase/migrations/`
- [ ] Viết Edge Functions: sinh Bill hàng tháng + gửi Email/SMS
- [ ] Setup Scheduled Trigger (pg_cron) cho job sinh Bill hàng tháng

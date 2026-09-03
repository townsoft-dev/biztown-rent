# CURRENT_STATUS.md — Trạng thái hiện tại

## Giai đoạn

Setup kỹ thuật xong, **đã nhận đủ design UI (Figma) + bộ docs nghiệp vụ chi tiết** (PRODUCT-OVERVIEW, REQUIREMENTS, BUSINESS-RULES, USER-FLOWS, SCREEN-SPEC, DESIGN-SYSTEMS) từ Dream ngày 2026-08-28. Sẵn sàng bắt đầu code tính năng thật.

## Đã xong

- [x] Cấu trúc thư mục repo (src/, supabase/, tests/, design/, docs/, changelog/)
- [x] Chốt stack: Flutter (frontend) + Supabase-only (backend, không dùng Vercel)
- [x] Cài Flutter SDK (3.47.1, qua `~/development/flutter`, PATH set trong `~/.zshrc`)
- [x] Cài Supabase CLI (2.115.0, qua npm devDependency, chạy bằng `npx supabase`)
- [x] Commit git đầu tiên
- [x] Push lên GitHub, đã transfer sang Organization, đổi tên repo: https://github.com/townsoft-dev/biztown-rent
- [x] Tạo project Supabase (`rentease`, region South Asia/Mumbai, org cá nhân `trandung1291`, sẽ transfer sau) — URL: `https://rrtppoibjprlvasnbvwr.supabase.co`
- [x] `supabase init` xong (`supabase/config.toml`)
- [x] Publishable key + Secret key + Access Token đã có, lưu trong `supabase/.env` (local, không lên git)
- [x] `supabase link` thành công — project `rentease` (ACTIVE_HEALTHY, Postgres 17, ap-south-1) đã gắn với repo
- [x] Figma MCP kết nối cho Claude Code (`claude.ai Figma`, tài khoản dungtv, seat Full)
- [x] Nhận design UI (Figma wireframe + logo) và mô tả nghiệp vụ chi tiết đầy đủ từ Dream
- [x] Chốt lại kênh thông báo: Push + SMS/Zalo (cả Landlord & Tenant), Auth: Supabase Auth Phone/OTP + Send SMS Hook (không dùng Firebase)

## Còn thiếu để dev thật được (máy local)

- [ ] Android Studio (Android SDK) — cần khi build/test trên Android
- [ ] Xcode đầy đủ + CocoaPods — cần khi build/test trên iOS
- [ ] Tài khoản Apple Developer (cần khi publish lên App Store)
- [ ] Rotate lại Secret key + Access Token (cả 2 đã bị dán vào chat, coi như lộ)

## Đang làm / Tiếp theo

- [ ] Chạy `flutter create .` trong `src/` để sinh đầy đủ project
- [ ] Thiết kế schema chi tiết (landlord, property, room, tenant, contract, meter_reading, invoice, payment, maintenance_request, rental_inquiry, notification) trong `supabase/migrations/` — xem [DATABASE.md](DATABASE.md)
- [ ] Chọn state management, điền `.claude/rules/flutter.md`
- [ ] Viết Edge Functions: sinh Invoice hàng tháng, gửi Push/SMS/Zalo, Send SMS Hook cho OTP
- [ ] Setup Scheduled Trigger (pg_cron) cho job sinh Invoice hàng tháng
- [ ] Chọn nhà cung cấp SMS Việt Nam (eSMS/Speedsms) + tích hợp Zalo ZNS/OA
- [ ] Bắt đầu code theo thứ tự 8 Core Flows trong [USER-FLOWS.md](USER-FLOWS.md)

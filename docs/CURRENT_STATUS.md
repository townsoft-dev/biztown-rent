# CURRENT_STATUS.md — Trạng thái hiện tại

## Giai đoạn

Đã nhận đủ design UI (Figma, hiện Low-fi Ver1) + bộ docs nghiệp vụ chi tiết từ Dream. **Đang chờ design hoàn chỉnh (final) mới code UI/màn hình thật** — tránh code rồi sửa lại khi design đổi. Trong lúc chờ, đã chuẩn bị trước phần hạ tầng/backend dựa trên business rules đã chốt (không phụ thuộc pixel UI).

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
- [x] Chốt state management: **Riverpod**
- [x] `flutter create .` xong trong `src/` (org `com.townsoftvina.biztown`, tên package `rent_manager`), chỉ giữ platform Android + iOS
- [x] Cấu trúc `lib/` theo role (core/, data/, shared/, landlord/, tenant/) + wiring Supabase/Riverpod cơ bản trong `main.dart` (chưa có UI thật, chờ design final)
- [x] Migration schema đầu tiên (11 bảng + RLS multi-tenant) viết xong và **đã áp lên Supabase dev thật** (`supabase db push` thành công, verify qua `migration list`)
- [x] Khung 3 Edge Functions: `generate-invoice` (đã code logic tính hoá đơn thật theo BR-BILL-01..05), `send-notification`, `send-otp-sms` (2 cái sau còn TODO chờ chọn provider) — cả 3 đã deploy thử lên Supabase dev để verify compile

## Còn thiếu để dev thật được (máy local)

- [ ] Android Studio (Android SDK) — cần khi build/test trên Android
- [ ] Xcode đầy đủ + CocoaPods — cần khi build/test trên iOS
- [ ] Tài khoản Apple Developer (cần khi publish lên App Store)
- [ ] Rotate lại Secret key + Access Token (cả 2 đã bị dán vào chat, coi như lộ)

## Đang làm / Tiếp theo

- [ ] **Chờ Dream hoàn thiện design (Figma) bản final** trước khi code UI/màn hình thật
- [ ] Chọn nhà cung cấp SMS Việt Nam (eSMS/Speedsms) + đăng ký Zalo ZNS/OA (nên bắt đầu sớm, tốn thời gian duyệt)
- [ ] Tạo project Firebase (miễn phí, chỉ dùng cho FCM push) khi tới lúc code `send-notification` thật
- [ ] Setup Scheduled Trigger (pg_cron) cho job sinh Invoice hàng tháng (sau khi chốt lịch cụ thể)
- [ ] Bắt đầu code UI theo thứ tự 8 Core Flows trong [USER-FLOWS.md](USER-FLOWS.md) khi có design final

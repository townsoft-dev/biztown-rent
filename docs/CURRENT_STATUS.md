# CURRENT_STATUS.md — Trạng thái hiện tại

## Giai đoạn

⚠️ **Cập nhật 2026-09-03 (chiều):** Phase 1 vừa **thu hẹp phạm vi lớn** — bỏ app Tenant, thêm Manager sub-account, đổi cấu trúc app sang 5 menu chính. Toàn bộ `docs/*.md` đã được viết lại theo scope mới (Version 2) — xem [DECISIONS.md](DECISIONS.md). **Backend/schema đã build trước đó (migration, Edge Functions) theo scope Version 1 — cần rà soát/viết lại trước khi code UI.**

✅ **Cập nhật 2026-09-03 (tối):** Figma wireframe **Version 2** (22 màn hình theo scope Phase 1 mới) đã build xong, nằm dưới Version 1 trong cùng file Figma — xem [SCREEN-SPEC.md](SCREEN-SPEC.md) mục 3.

Đã nhận đủ design UI (Figma, nay có cả Version 1 và Version 2) + bộ docs nghiệp vụ chi tiết từ Dream. **Sẵn sàng bắt đầu code UI theo Version 2** — chỉ còn thiếu việc nối prototype flow giữa các màn trong Figma (hiện là wireframe tĩnh) và rà soát lại backend/schema theo Version 2 trước khi dùng tiếp.

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
- [x] **Figma wireframe Version 2** (22 màn hình, 5 menu, theo scope Phase 1 mới) build xong trong cùng file Figma, nằm dưới Version 1 — xem [SCREEN-SPEC.md](SCREEN-SPEC.md) mục 3

## Còn thiếu để dev thật được (máy local)

- [ ] Android Studio (Android SDK) — cần khi build/test trên Android
- [ ] Xcode đầy đủ + CocoaPods — cần khi build/test trên iOS
- [ ] Tài khoản Apple Developer (cần khi publish lên App Store)
- [ ] Rotate lại Secret key + Access Token (cả 2 đã bị dán vào chat, coi như lộ)

## Đang làm / Tiếp theo

- [ ] **Rà soát & viết lại migration DB** theo schema Version 2 ([DATABASE.md](DATABASE.md)) — thêm `manager_account`/`manager_house_access`/`contract_version`/`contract_settlement`, bỏ `payments`/`maintenance_requests`/`rental_inquiries`
- [ ] Rà soát lại Edge Function `generate-invoice` (dùng `contract_version` snapshot) và `send-notification` (bỏ nhánh push cho Tenant)
- [ ] Nối prototype flow giữa các màn trong Figma Version 2 (hiện là wireframe tĩnh, chưa liên kết bằng Figma prototyping)
- [ ] Chọn nhà cung cấp SMS Việt Nam (eSMS/Speedsms) + đăng ký Zalo ZNS/OA (nên bắt đầu sớm, tốn thời gian duyệt) — vẫn cần vì Bill Management gửi hoá đơn cho Tenant qua kênh này
- [ ] Tạo project Firebase (miễn phí, chỉ dùng cho FCM push cho Landlord/Manager) khi tới lúc code `send-notification` thật
- [ ] Setup Scheduled Trigger (pg_cron) cho job nhắc thanh toán quá hạn (BR-PAY-04), sau khi chốt lịch cụ thể
- [ ] Bắt đầu code UI theo thứ tự 5 menu chính trong [USER-FLOWS.md](USER-FLOWS.md), dựa theo Figma Version 2

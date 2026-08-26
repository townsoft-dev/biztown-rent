# CURRENT_STATUS.md — Trạng thái hiện tại

## Giai đoạn

Setup kỹ thuật xong — đang chờ **design UI** và **mô tả nghiệp vụ chi tiết** trước khi code tính năng thật. Mô tả nghiệp vụ viết vào [PRODUCT.md](PRODUCT.md) (mục "Luồng nghiệp vụ chính" / "Tính năng chính").

## Đã xong

- [x] Cấu trúc thư mục repo (src/, supabase/, tests/, design/, docs/, changelog/)
- [x] Chốt stack: Flutter (frontend) + Supabase-only (backend, không dùng Vercel)
- [x] Cài Flutter SDK (3.47.1, qua `~/development/flutter`, PATH set trong `~/.zshrc`)
- [x] Cài Supabase CLI (2.115.0, qua npm devDependency, chạy bằng `npx supabase`)
- [x] Commit git đầu tiên
- [x] Push lên GitHub: https://github.com/dungtv1291/rentease

## Còn thiếu để dev thật được (máy local)

- [ ] Android Studio (Android SDK) — cần khi build/test trên Android
- [ ] Xcode đầy đủ + CocoaPods — cần khi build/test trên iOS
- [ ] Tài khoản + project Supabase (cân nhắc tạo dưới tài khoản khách hàng để dễ bàn giao sau)
- [ ] Tài khoản Apple Developer (cần khi publish lên App Store)

## Đang làm / Tiếp theo (chờ design + business)

- [ ] Nhận design UI + mô tả nghiệp vụ chi tiết
- [ ] Chạy `flutter create .` trong `src/` để sinh đầy đủ project
- [ ] `supabase init` / `supabase link` với project Supabase thật
- [ ] Thiết kế schema (house, room, tenant, contract, meter_reading, bill) trong `supabase/migrations/`
- [ ] Chọn state management, điền `.claude/rules/flutter.md`
- [ ] Viết Edge Functions: sinh Bill hàng tháng + gửi Email/SMS
- [ ] Setup Scheduled Trigger (pg_cron) cho job sinh Bill hàng tháng

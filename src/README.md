# BizTown Rent-Manager — Mobile App (Flutter)

Đây là placeholder cho Flutter app — chưa chạy `flutter create .` (đợi design UI + mô tả nghiệp vụ chi tiết trước).

Flutter SDK đã cài sẵn tại `~/development/flutter` (PATH set trong `~/.zshrc`, mở terminal mới để có lệnh `flutter`). Android SDK / Xcode đầy đủ **chưa cài** — cần khi build/test trên thiết bị thật hoặc emulator.

## Setup khi bắt đầu code (sau khi có design)

1. Trong thư mục `src/`, chạy `flutter create .` để sinh đầy đủ project (android/, ios/, lib/, test/...). Lệnh này sẽ giữ lại `pubspec.yaml` đã có sẵn nếu chọn đúng org/tên phù hợp — kiểm tra lại `pubspec.yaml` sau khi chạy.
2. Thêm dependency `supabase_flutter` để kết nối Supabase (Auth, Database, Storage).
3. Điền `.claude/rules/flutter.md` (chọn state management, cấu trúc `lib/`...).

## Kết nối Backend

- Supabase: dùng trực tiếp từ app qua `supabase_flutter` SDK (anon key) cho các thao tác CRUD thông thường (House, Room, Tenant, Contract).
- Supabase Edge Functions (`../supabase/functions/`): dùng cho tác vụ cần service-role key hoặc gửi Push/SMS/Zalo (không an toàn nếu gọi trực tiếp từ mobile app).

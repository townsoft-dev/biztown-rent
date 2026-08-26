# RentEase — Mobile App (Flutter)

Đây là placeholder cho Flutter app. Máy hiện chưa cài Flutter SDK.

## Setup lần đầu

1. Cài [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Trong thư mục `src/`, chạy `flutter create .` để sinh đầy đủ project (android/, ios/, lib/, test/...). Lệnh này sẽ giữ lại `pubspec.yaml` đã có sẵn nếu chọn đúng org/tên phù hợp — kiểm tra lại `pubspec.yaml` sau khi chạy.
3. Thêm dependency `supabase_flutter` để kết nối Supabase (Auth, Database, Storage).

## Kết nối Backend

- Supabase: dùng trực tiếp từ app qua `supabase_flutter` SDK (anon key) cho các thao tác CRUD thông thường (House, Room, Tenant, Contract).
- Supabase Edge Functions (`../supabase/functions/`): dùng cho tác vụ cần service-role key hoặc gửi Email/SMS (không an toàn nếu gọi trực tiếp từ mobile app).

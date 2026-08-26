---
paths:
  - "src/**/*.dart"
---

# Flutter Coding Standards — RentEase

> Placeholder. Điền chi tiết sau khi có design UI + mô tả nghiệp vụ cụ thể — không tự quyết kiến trúc lớn ở đây, hỏi trước.

- **State management**: TBD — cần chọn (vd: Riverpod, Bloc) trước khi code feature đầu tiên.
- **Kiến trúc thư mục `lib/`**: TBD.
- **Null-safety**: bắt buộc, tránh dùng `dynamic` tùy tiện.
- **Format**: chạy `dart format` trước khi coi một thay đổi là hoàn tất.
- **Testing**: mỗi feature quan trọng có ít nhất 1 widget test.
- **Kết nối backend**: dùng `supabase_flutter` SDK, không tự gọi HTTP thô tới Supabase.

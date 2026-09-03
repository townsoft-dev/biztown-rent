---
paths:
  - "src/**/*.dart"
---

# Flutter Coding Standards — BizTown Rent-Manager

- **State management**: **Riverpod** (xem [docs/DECISIONS.md](../../docs/DECISIONS.md) 2026-09-03). Không dùng Provider/Bloc/GetX.
- **Kiến trúc thư mục `lib/`** — nhóm theo role, khớp tên màn hình trong [docs/SCREEN-SPEC.md](../../docs/SCREEN-SPEC.md) (S-xx/L-xx/T-xx):
  ```
  lib/
  ├── core/          # theme, router, constants, extensions dùng chung
  ├── data/          # models, repositories (Supabase client calls)
  ├── shared/        # widget/màn hình dùng chung (S-00..S-05)
  ├── landlord/      # màn hình + provider riêng Landlord (L-01..L-19)
  ├── tenant/        # màn hình + provider riêng Tenant (T-01..T-11)
  └── main.dart
  ```
- **UI đợi design final**: hiện Figma còn Low-fi (Ver1) — không code UI/màn hình cụ thể cho tới khi có design hoàn chỉnh, tránh sửa đi sửa lại. Phần backend/schema không phụ thuộc pixel UI thì làm trước được.
- **Ngôn ngữ UI**: tiếng Anh là chính (theo [docs/DESIGN-SYSTEMS.md](../../docs/DESIGN-SYSTEMS.md) mục 0), đa ngôn ngữ để Phase 2.
- **Null-safety**: bắt buộc, tránh dùng `dynamic` tùy tiện.
- **Format**: chạy `dart format` trước khi coi một thay đổi là hoàn tất.
- **Testing**: mỗi feature quan trọng có ít nhất 1 widget test.
- **Kết nối backend**: dùng `supabase_flutter` SDK, không tự gọi HTTP thô tới Supabase.

# CLAUDE.md — Hướng dẫn cho AI

Tài liệu này giúp AI (Claude) hiểu nhanh project khi làm việc.

## Project

RentEase — ứng dụng mobile quản lý nhà cho thuê. Stack: **Flutter** (frontend) + **Supabase** (backend, không dùng Vercel). Xem [PRODUCT.md](PRODUCT.md) để biết yêu cầu chi tiết, [ARCHITECTURE.md](ARCHITECTURE.md) để biết kiến trúc.

## Cấu trúc

- `src/` — Flutter mobile app
- `supabase/` — Supabase backend (Edge Functions, migrations)
- `tests/` — test
- `design/` — file thiết kế UI/UX (Figma export, mockup, asset)
- `docs/` — tài liệu dự án (đọc trước khi code)
- `changelog/` — nhật ký thay đổi chi tiết theo ngày/giờ/người thực hiện (một file mỗi ngày: `YYYY-MM-DD.md`)

## Quy tắc khi code

- Sau khi thay đổi code có ảnh hưởng đến trạng thái/tiến độ, cập nhật [CURRENT_STATUS.md](CURRENT_STATUS.md) và [CHANGELOG.md](CHANGELOG.md).
- **Sau MỖI thay đổi** (dù nhỏ hay lớn), thêm entry vào `changelog/YYYY-MM-DD.md` (tạo file mới nếu chưa có, xem format tại [changelog/README.md](../changelog/README.md)): giờ, người thực hiện, tính năng/khu vực, mô tả cụ thể đã sửa gì.
- Quyết định thiết kế quan trọng ghi vào [DECISIONS.md](DECISIONS.md) kèm lý do.
- File thiết kế UI/UX nằm trong repo tại `design/` — cập nhật khi thiết kế thay đổi.

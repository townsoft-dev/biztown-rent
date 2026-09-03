# CLAUDE.md — Hướng dẫn cho AI
> **Trạng thái tài liệu:** Version 1  **Last updated:** 2026-08-28

Tài liệu này giúp AI (Claude) hiểu nhanh project khi làm việc.

## 1. Bối cảnh dự án

**BizTown Rent-Manager** là mobile app (iOS + Android, Flutter) giúp chủ trọ (Landlord) quản lý nhà/phòng/hợp đồng/hoá đơn điện nước/thu tiền/yêu cầu của người thuê, và người thuê (Tenant) tìm phòng, theo dõi hoá đơn, thanh toán, gửi yêu cầu — mô hình 2 chiều (2-sided), multi-tenant SaaS phục vụ nhiều chủ trọ với nhiều quy mô cho thuê khác nhau.
 Xem [PRODUCT-OVERVIEW.md](PRODUCT-OVERVIEW.md) để biết yêu cầu chi tiết, [ARCHITECTURE.md](ARCHITECTURE.md) để biết kiến trúc.

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
- File thiết kế UI/UX nằm trong repo tại `design/` — cập nhật khi thiết kế thay đổi. hoặc theo đường link → https://www.figma.com/design/AElzfTBuL8YyA8OJ85f7aX/BizTown-Rent-Manager-%E2%80%94-MVP-Wireframes

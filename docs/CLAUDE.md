# CLAUDE.md — Hướng dẫn cho AI
> **Trạng thái tài liệu:** Version 2  **Last updated:** 2026-09-03
> ⚠️ **Thay đổi phạm vi lớn (2026-09-03):** Phase 1 thu hẹp lại chỉ còn Landlord + Manager (tài khoản phụ do Landlord tạo) — **bỏ hẳn app/tài khoản Tenant**. Toàn bộ docs/*.md đã được cập nhật theo scope mới; xem [DECISIONS.md](DECISIONS.md) trước khi code bất kỳ tính năng nào liên quan tới Tenant, Search, Maintenance, hay Revenue Report (đều đã dời sang Phase 2 hoặc thay đổi cách hoạt động).

Tài liệu này giúp AI (Claude) hiểu nhanh project khi làm việc.

## 1. Bối cảnh dự án

**BizTown Rent-Manager (Phase 1)** là mobile app (iOS + Android, Flutter) dành cho Chủ trọ (Landlord) và Quản lý (Manager, tài khoản phụ do Landlord tạo) — quản lý nhà/phòng/người thuê/hợp đồng, và **tự động tạo & gửi hoá đơn điện nước hàng tháng** (chức năng cốt lõi). Người thuê (Tenant) trong Phase 1 không cài app/không có tài khoản — chỉ nhận hoá đơn/nhắc thanh toán một chiều qua SMS/Zalo.
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
- File thiết kế UI/UX nằm trong repo tại `design/` — cập nhật khi thiết kế thay đổi. hoặc theo đường link → https://www.figma.com/design/AElzfTBuL8YyA8OJ85f7aX/BizTown-Rent-Manager-%E2%80%94-MVP-Wireframes?node-id=133-57 

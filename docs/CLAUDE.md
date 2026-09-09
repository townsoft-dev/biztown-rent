# CLAUDE.md — Hướng dẫn cho AI
> **Trạng thái tài liệu:** Version 3  **Last updated:** 2026-09-08
> ⚠️ **Thay đổi phạm vi (2026-09-08):** Version 3 giữ nguyên định hướng "không có app Tenant" của Version 2, nhưng đổi 3 thứ cốt lõi: (1) cấu trúc app **5 menu → 4 tab**; (2) thêm nghiệp vụ **ghi chỉ số điện/nước** (3 loại, bắt buộc tại flow Hợp đồng); (3) **hợp đồng nhiều phòng** + tự động hoá hoá đơn sâu hơn (chu kỳ tiền nhà, phí dịch vụ/m², mã QR VietQR). Thay đổi lớn nhất về mô hình dữ liệu: **vai trò chủ nhà/quản lý không còn gắn vào tài khoản** mà gắn theo **từng Nhà/Dãy trọ**, và **tên bảng đổi lại dùng tiền tố `tb_`**. Toàn bộ `docs/*.md` đã được cập nhật theo scope mới; xem [DECISIONS.md](DECISIONS.md) trước khi code bất kỳ tính năng nào liên quan tới Auth/vai trò, Hợp đồng, hoặc Hoá đơn.

Tài liệu này giúp AI (Claude) hiểu nhanh project khi làm việc.

## 1. Bối cảnh dự án

**BizTown Rent-Manager (Phase 1)** là mobile app (iOS + Android, Flutter) quản lý nhà/phòng/người thuê/hợp đồng, và **tự động tạo & gửi hoá đơn điện nước hàng tháng kèm mã QR** (chức năng cốt lõi). Chỉ có **1 loại tài khoản** — vai trò Chủ nhà (`owner`)/Quản lý (`manager`) xác định theo **từng Nhà/Dãy trọ**, không gắn vào tài khoản (xem [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 4). Người thuê (Tenant) không cài app/không có tài khoản — chỉ nhận hoá đơn/nhắc thanh toán một chiều qua SMS/Zalo.
Xem [PRODUCT-OVERVIEW.md](PRODUCT-OVERVIEW.md) để biết yêu cầu chi tiết, [ARCHITECTURE.md](ARCHITECTURE.md) để biết kiến trúc, [DATABASE.md](DATABASE.md) để biết schema 12 bảng tiền tố `tb_`.

## ⚠️ 3 điều dễ làm sai nhất khi code theo Version 3

1. **Không cache vai trò (role) vào session hay state toàn cục.** Cùng 1 tài khoản có thể là `owner` ở nhà này và `manager` ở nhà khác — mọi màn hình thao tác trên 1 Nhà/Dãy trọ cụ thể phải tự hỏi lại quyền hiện tại cho đúng nhà đó (xem [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 4, 7).
2. **Chỉ số điện/nước (`MOVE_IN`/`MOVE_OUT`) là bước chặn bắt buộc trong flow Hợp đồng**, không phải 1 menu ghi số tự do — thiếu thì phải chặn nút "Lưu hợp đồng"/"Kết thúc hợp đồng" ngay tại chỗ, không cho lưu tạm rồi bổ sung sau (xem [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 6).
3. **Đơn giá điện/nước/phí dịch vụ tồn tại ở 2 nơi** — chỉ đơn giá snapshot trên `tb_contract_version` mới được dùng tính hoá đơn; đơn giá mặc định trên `tb_house`/`tb_room` chỉ để tự động điền form (xem [DATABASE.md](DATABASE.md) mục "Đơn giá tồn tại ở 2 nơi").

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
- File thiết kế UI/UX nằm trong repo tại `design/` — cập nhật khi thiết kế thay đổi. Hoặc theo đường link → https://www.figma.com/design/AElzfTBuL8YyA8OJ85f7aX/BizTown-Rent-Manager-%E2%80%94-MVP-Wireframes?node-id=133-57 (Figma wireframe **đã build lại theo Version 3** (08/09/2026): 32 màn/4 tab, Home tab tổ chức đúng 6 màn H-01→H-06 theo [SCREEN-SPEC.md](SCREEN-SPEC.md), prototype đã nối lại đầy đủ, trích dẫn `BR-xxx` đã rà soát khớp [BUSINESS-RULES.md](BUSINESS-RULES.md) — có thể dùng ngay để code UI).

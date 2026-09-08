# CHANGELOG.md

## [Unreleased]

### Added

- Khởi tạo cấu trúc project BizTown Rent-Manager (src/, supabase/, tests/, design/, docs/, changelog/).
- Chốt stack: Flutter (frontend) + Supabase-only (backend).
- Bỏ Vercel, chuyển toàn bộ backend logic (Edge Functions, cron) sang Supabase.
- Nhận design (Figma) + bộ docs nghiệp vụ đầy đủ (PRODUCT-OVERVIEW, REQUIREMENTS, BUSINESS-RULES, USER-FLOWS, SCREEN-SPEC, DESIGN-SYSTEMS).
- Chốt kênh thông báo: Push notification cho Landlord/Manager + SMS/Zalo một chiều cho Tenant.
- Chốt auth: Supabase Auth (Phone + OTP) với Send SMS Hook cho nhà cung cấp SMS Việt Nam, không dùng Firebase.
- Kết nối Figma MCP cho Claude Code để đọc trực tiếp file thiết kế.

### Changed

- **(2026-09-03) Thu hẹp phạm vi Phase 1**: bỏ app/tài khoản Tenant, thêm vai trò Manager (tài khoản phụ do Landlord tạo, phân quyền theo Nhà/Dãy trọ), đổi cấu trúc app sang 5 menu chính (House/Room Management, Tenant Management, Contract Management, Bill Management — core, User Setting). Trạng thái hoá đơn đổi sang `Draft/Sent/Collected/Overdue`. Thêm lịch sử phiên bản hợp đồng (Contract Versioning). Dời House/Room Search, Service Request Management, Revenue Report sang Phase 2. Xem [DECISIONS.md](DECISIONS.md).
- **(2026-09-08) Version 2 → Version 3**: đổi cấu trúc app **5 menu → 4 tab** (Home, Tenant & Contract, Bills, Profile). Thêm nghiệp vụ **ghi chỉ số điện/nước** (3 loại — định kỳ/nhận phòng/trả phòng — cùng 1 chuỗi lịch sử theo phòng, bắt buộc tại flow Hợp đồng). Hợp đồng cho phép **nhiều phòng** (bảng nối `tb_contract_room` mới). Hoá đơn tự động hoá sâu hơn: tạo hàng loạt theo nhà+kỳ, chu kỳ thu tiền nhà cấu hình được, phí dịch vụ theo m², hạn thanh toán theo ngày cố định trong tháng, sinh mã QR VietQR/NAPAS-247. **Vai trò Chủ nhà/Quản lý đổi sang gắn theo TỪNG Nhà/Dãy trọ** (không gắn vào tài khoản) — bỏ hẳn luồng "Landlord tạo tài khoản Manager qua Admin API", thay bằng mời quản lý qua số điện thoại (chỉ ghi quyền, không tạo tài khoản). **Đảo ngược quy ước đặt tên bảng**: quay lại dùng tiền tố `tb_` (quyết định "không tiền tố" của 2026-09-04 không còn hiệu lực). Số màn hình tăng 22 → 34. Kiểm chứng bằng kịch bản thật (`시뮬레이션 케이스 (Mr.Han).md`, 3 nhà A/B/C, chủ khác nhau, con gái làm quản lý). Toàn bộ `docs/*.md` đã được viết lại theo Version 3. Xem [DECISIONS.md](DECISIONS.md).

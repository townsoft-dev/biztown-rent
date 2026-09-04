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

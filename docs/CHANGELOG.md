# CHANGELOG.md

## [Unreleased]

### Added

- Khởi tạo cấu trúc project BizTown Rent-Manager (src/, supabase/, tests/, design/, docs/, changelog/).
- Chốt stack: Flutter (frontend) + Supabase-only (backend).
- Bỏ Vercel, chuyển toàn bộ backend logic (Edge Functions, cron) sang Supabase.
- Nhận design (Figma) + bộ docs nghiệp vụ đầy đủ (PRODUCT-OVERVIEW, REQUIREMENTS, BUSINESS-RULES, USER-FLOWS, SCREEN-SPEC, DESIGN-SYSTEMS).
- Chốt kênh thông báo: Push notification + SMS/Zalo cho cả Landlord và Tenant.
- Chốt auth: Supabase Auth (Phone + OTP) với Send SMS Hook cho nhà cung cấp SMS Việt Nam, không dùng Firebase.
- Kết nối Figma MCP cho Claude Code để đọc trực tiếp file thiết kế.

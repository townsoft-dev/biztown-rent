# DATABASE.md — Thiết kế dữ liệu (Supabase / Postgres)
> **Version 2 — Last updated 2026-09-03.** Viết lại theo scope Phase 1 mới (Landlord + Manager, bỏ Tenant app) và theo FigJam board `PAuYWdSon7WcPKdRQStoPR` (Dream, 2026-09-03). Xem [DECISIONS.md](DECISIONS.md).
>
> ⚠️ **Lưu ý cho dev:** Migration `supabase/migrations/20260903121605_initial_schema.sql` đã áp lên Supabase dev thật theo schema **Version 1** (11 bảng, gồm `payments`, `maintenance_requests`, `rental_inquiries`, `notifications` cho cả tenant). Schema Version 2 dưới đây **khác đáng kể** — cần viết migration mới (có thể là migration bổ sung/reset tuỳ mức độ đã có dữ liệu thật) trước khi code UI. Đây là việc của dev/Claude Code khi bắt tay vào code, tài liệu này chỉ mô tả schema mục tiêu.

> **Quy ước đặt tên bảng:** `snake_case`, không tiền tố (không dùng `tb_...`). Đây là tên bảng chính thức, thống nhất trên toàn bộ tài liệu (`SCREEN-SPEC.md`, `USER-FLOWS.md`, `REQUIREMENTS.md` đã đồng bộ theo — xem [DECISIONS.md](DECISIONS.md)). FigJam board gốc dùng tiền tố `tb_` cho một số bảng (VD: `tb_contact_settlement`) chỉ là ghi chú nháp lúc brainstorm, không phải tên chính thức.

## Các thực thể

- **landlord_account** — tài khoản đăng nhập gốc, liên kết 1-1 với `auth.users`: `phone` (PK, login credential), `passwordHash`, `createdAt`.
- **owner_profile** — hồ sơ Chủ nhà, 1-1 với `landlord_account`: `fullName`, `phone`, `sex` (M/F), `dateOfBirth`, `email` (optional), `idNumber` (CCCD/CMND), `taxCode` (optional), `bankAccountInfo`, `avatarUrl` (optional).
- **manager_account** — tài khoản phụ do Landlord tạo trực tiếp (Landlord nhập `phone` + `fullName`, hệ thống tạo user qua Supabase Admin API — xem [ARCHITECTURE.md](ARCHITECTURE.md)): 1-1 với `auth.users` (**dùng chung cơ chế Supabase Auth với Landlord, không phải bảng auth tự viết riêng** — `passwordHash` không lưu ở đây, Supabase Auth quản lý), `phone` (login credential, khớp `auth.users`), `fullName`, `status` (active/disabled), `note` (optional). Tạo bởi 1 `landlord_account` (`created_by_landlord_id`).
- **manager_house_access** — bảng phân quyền N-N giữa Manager và House: `managerId` (FK), `houseId` (FK), `grantedAt`. Đây là cơ chế RLS chính cho Manager (BR-DATA-02).
- **house** (Nhà/Dãy trọ) — thuộc `landlord_id`: `name`, `address`, `description` (optional), `photos` (multiple).
- **room** (Phòng) — thuộc `houseId`: `roomNo`, `areaSqm` (optional), `baseRent` (giá tham khảo, không phải giá cố định), `recurringFees` (tên+số tiền, mặc định gợi ý), `amenities` (list), `photos` (multiple), `status` (Empty/Occupied/UnderRepair).
- **tenant** — hồ sơ Người thuê (**không có tài khoản đăng nhập** trong Phase 1): `fullName`, `phone`, `sex` (M/F), `dateOfBirth`, `mail` (optional), `idNumber` (CCCD/CMND), `idPhotoFront`, `idPhotoBack`, `note` (optional). Tồn tại độc lập với hợp đồng ("Tenant Pool" — BR-CTR-06), tạo bởi `landlord_id` (dùng chung cho các Manager được cấp quyền).
- **contract** (Hợp đồng) — `roomId` (FK), `tenantId` (FK, đại diện cố định — "fixed representative"), `currentVersionId` (FK, trỏ tới `contract_version` mới nhất — shortcut điều khoản đang hiệu lực), `status` (Active/Ended), `createdAt`. Chỉ 1 hợp đồng `Active` trên 1 phòng tại 1 thời điểm (BR-CTR-04). 1 phòng có thể có nhiều `contract` theo thời gian ("hosts over time").
- **contract_version** (Phiên bản điều khoản hợp đồng — **mới, Version 2**) — thuộc `contractId`: `versionNo`, `changeReason` (New/Renewal/Amendment), `startDate`, `endDate`, `monthlyRent`, `depositAmount`, `electricityUnitPrice`, `waterUnitPrice`, `recurringFees` (tên+số tiền), `lateFeeTerms` (optional, free text), `realEstate` (optional — thông tin môi giới: tên, liên hệ, phí). Mỗi lần tạo/gia hạn/sửa điều khoản hợp đồng sinh 1 bản ghi mới, giữ nguyên lịch sử (BR-VER-01→05).
- **invoice** (Hoá đơn/Bill) — `contractId` (FK, denormalized cho RLS/query), `contractVersionId` (FK, điều khoản áp dụng — snapshot), `roomLabel`/`houseName`/`tenantName` (snapshot tại thời điểm phát hành), `periodStart` (neo theo ngày bắt đầu hợp đồng)/`periodEnd`, `electricityOldReading`/`electricityNewReading`, `waterOldReading`/`waterNewReading`, `rentAmount` (từ contract version), `recurringFees` (snapshot), `totalAmount` (computed), `status` (**Draft/Sent/Collected/Overdue** — thay cho `Chưa thanh toán/Chờ xác nhận/Đã thanh toán/Quá hạn` ở Version 1, vì không còn bước Tenant tự xác nhận), `createdAt`, `sentAt` (optional — thời điểm chuyển Draft→Sent, hiển thị ở lịch sử B-03), `collectedAt` (optional — thời điểm chuyển sang Collected, dùng để tính Overdue và hiển thị lịch sử thu tiền).
- **contract_settlement** (Đối soát kết thúc hợp đồng — mới, Version 2; tên bảng đề xuất `contract_settlement`, FigJam ghi tạm `tb_contact_settlement`) — `contractId` (FK, 0..1), `unpaidInvoicesTotal` (computed), `damageDeduction` (manual entry), `depositAmount`, `refundAmount` (computed), `confirmedAt`. Tạo khi Landlord/Manager thực hiện "End Contract" (C-05).
- **notification** — gắn `user_id` (`landlord_account` hoặc `manager_account` qua `auth.users`): loại sự kiện, nội dung, đã đọc/chưa, kênh (push) — nguồn cho S-03. **Không còn** notification cho Tenant trong app (Tenant nhận SMS/Zalo trực tiếp, không qua bảng này — có thể log riêng ở mức Edge Function nếu cần audit, không bắt buộc cho Phase 1).

> **Đã bỏ khỏi schema Version 1:** `payment` (thay bằng cập nhật trực tiếp `invoice.status`, không cần bảng riêng vì không còn ảnh chứng từ Tenant tự đính kèm), `maintenance_request`, `rental_inquiry` (Service Request & Search ngoài phạm vi Phase 1 — xem [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.2).

## Sơ đồ quan hệ (rút gọn)

```
landlord_account (1) --- (1) owner_profile
landlord_account (1) --- (N) manager_account [creates]
landlord_account (1) --- (N) house [owns]
landlord_account (1) --- (N) tenant [manages pool of]
manager_account (1) --- (N) manager_house_access (N) --- (1) house [scoped by / assigned via]

house (1) --- (N) room
room (1) --- (N) contract [hosts over time]
tenant (1) --- (N) contract [is party to]
contract (1) --- (N) contract_version [revised as]
contract (1) --- (0..1) contract_settlement [closed by]
contract_version (1) --- (N) invoice [bill calculate information]
```

## Multi-tenancy & RLS (xem [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 6)

- Mỗi `landlord_account` chỉ thấy `house`/`room`/`tenant`/`contract`/`invoice` do chính mình tạo (`landlord_id = auth.uid()` tương ứng).
- Mỗi `manager_account` chỉ thấy dữ liệu thuộc `house` có trong `manager_house_access` của chính họ — RLS policy cần join qua bảng này thay vì so trực tiếp `landlord_id`.
- `tenant` **không có** `auth.users` row trong Phase 1 — không cần policy RLS phía Tenant (khác biệt lớn so với Version 1, đơn giản hoá đáng kể mô hình auth).

> Cập nhật schema chi tiết (kiểu dữ liệu, ràng buộc, index, RLS policy cụ thể) khi viết migration thật — xem lưu ý đầu file.

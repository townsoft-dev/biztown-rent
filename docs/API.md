# API.md — Đặc tả API
> **Version 2 — Last updated 2026-09-03.** Cập nhật theo scope Phase 1 mới (Landlord + Manager, bỏ Tenant app). Xem [DECISIONS.md](DECISIONS.md).

## CRUD (House, Room, Tenant, Contract/ContractVersion, Invoice, Manager...)

Không có API tự viết — dùng trực tiếp **Supabase auto-generated REST/GraphQL API** (PostgREST) từ schema database, bảo vệ bằng Row Level Security (RLS) — RLS cho Manager cần join qua `manager_house_access` (xem [DATABASE.md](DATABASE.md) cho schema Version 2).

## Edge Functions (logic phía server)

| Function | Mô tả | Trigger | Trạng thái |
|----------|-------|---------|---|
| `generate-invoice` | Tính & tạo Invoice từ chỉ số điện/nước nhập trực tiếp lúc tạo hoá đơn + `contract_version` hiện hành (BR-BILL-01..07) | Gọi từ B-02 (Create Invoice) | Logic tính đã code xong theo schema Version 1 — **cần rà soát lại theo schema Version 2** (`contractVersionId`, snapshot điều khoản), đã deploy lên project dev |
| `send-notification` | Gửi **Push (FCM/APNs) cho Landlord/Manager** + **SMS/Zalo cho Tenant** (không còn push cho Tenant) | Gọi từ `generate-invoice`, nhắc thanh toán (BR-PAY-04) | Khung đã có, phần gửi thật (TODO) chờ chọn provider + tạo Firebase project — **cần cập nhật logic để không gửi push cho Tenant** |
| `send-otp-sms` | Auth Hook (Send SMS) — gửi OTP qua nhà cung cấp SMS Việt Nam | Supabase Auth gọi khi Landlord đăng ký/quên mật khẩu | Khung đã có, TODO chờ chọn eSMS/Speedsms. **Không áp dụng cho Manager** (không tự đăng ký, chỉ đăng nhập bằng mật khẩu do Landlord cấp) |

> Cả 3 function đã deploy thử lên project Supabase dev để verify compile theo schema Version 1 — logic cần rà soát lại theo scope Phase 1 mới (xem [DATABASE.md](DATABASE.md)) trước khi hoàn thiện phần gửi Push/SMS/Zalo thật.

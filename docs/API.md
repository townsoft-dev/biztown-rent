# API.md — Đặc tả API
> **Version 3 — Last updated 2026-09-08.** Cập nhật theo bản chốt thay đổi Version 2 → Version 3. Xem [DECISIONS.md](DECISIONS.md).

## CRUD (House, Room, Tenant, Contract/ContractVersion/ContractRoom, ElectricityReading/WaterReading, Invoice, User House Access...)

Không có API tự viết — dùng trực tiếp **Supabase auto-generated REST/GraphQL API** (PostgREST) từ schema database, bảo vệ bằng Row Level Security (RLS) — RLS cho mọi bảng nghiệp vụ join qua `tb_user_house_access` (kiểm cả `role` khi thao tác cần quyền `owner`) — xem [DATABASE.md](DATABASE.md) cho schema Version 3. **Mời/thu hồi quyền quản lý** (`INSERT`/`DELETE` trên `tb_user_house_access`) cũng đi thẳng qua PostgREST + RLS, **không cần Edge Function riêng** (khác Version 2).

## Edge Functions (logic phía server)

| Function | Mô tả | Trigger | Trạng thái |
|----------|-------|---------|---|
| `generate-invoice` | Tính & tạo Invoice — **đơn lẻ hoặc hàng loạt theo 1 Nhà/Dãy trọ + 1 kỳ**. Đọc lại chỉ số đã ghi sẵn trong `tb_electricity_reading`/`tb_water_reading`, tính tiền nhà theo chu kỳ cấu hình (`rentCycleMonths`/`rentCycleAnchorYm`), phí dịch vụ theo m², gộp `utilityLines` theo từng phòng, tự sinh mã QR (BR-BILL-01..13) | Gọi từ B-02 (Batch)/B-03 (Single) | ✅ Viết lại xong theo Version 3, deploy thành công lên project dev. ⚠️ Prorate tiền nhà khi `MOVE_IN`/`MOVE_OUT` giữa kỳ (BR-BILL-08) còn TODO — hiện tạm tính trọn tháng |
| `generate-payment-qr` | Sinh/sinh lại mã QR thanh toán chuẩn **VietQR/NAPAS-247** từ `tb_house.bankBin` + số tài khoản + `totalAmount` của 1 hoá đơn (dùng chung module `_shared/vietqr.ts` với `generate-invoice`) | Gọi từ `generate-invoice` lúc phát hành, hoặc gọi lại riêng lẻ từ B-05 (Invoice Detail → "Gửi lại") | ✅ Code xong (thuật toán CRC16/EMVCo verify đúng test vector chuẩn), deploy thành công. ⚠️ Chưa test với máy quét QR ngân hàng thật |
| `send-notification` | Gửi **Push (FCM/APNs)** cho người có quyền trên Nhà/Dãy trọ liên quan (qua `tb_user_house_access`/`tb_device_token`) + **SMS/Zalo** (kèm mã QR) cho Tenant | Gọi từ `generate-invoice`, nhắc thanh toán (BR-PAY-04), nhắc ghi chỉ số định kỳ (BR-NOTI-05), mời quản lý (BR-NOTI-06) | ✅ Đọc đúng schema Version 3, deploy thành công. Phần gửi thật (TODO) vẫn chờ chọn provider SMS/Zalo + tạo Firebase project cho FCM |
| `send-otp-sms` | Auth Hook (Send SMS) — gửi OTP qua eSMS.vn | Supabase Auth gọi khi **bất kỳ tài khoản nào** đăng ký/quên mật khẩu | Đã tích hợp eSMS thật (09/09/2026) — đang dùng Brandname demo "Baotrixemay" để test, cần đổi sang Brandname CSKH thật trước production |
| ~~`create-manager-user`~~ | ~~Tạo tài khoản Manager qua Supabase Admin API~~ | | **Đã xoá** — mời quản lý giờ chỉ là 1 dòng ghi vào `tb_user_house_access` qua PostgREST, không cần Edge Function/service-role key — xem [ARCHITECTURE.md](ARCHITECTURE.md) và [BUSINESS-RULES.md](BUSINESS-RULES.md) BR-ROLE-04 |

> Cả 3 function (`generate-invoice`, `generate-payment-qr`, `send-notification`) đã viết lại theo schema Version 3 và deploy thử thành công lên Supabase dev (2026-09-09). Còn thiếu: prorate tiền nhà theo ngày, và phần gửi Push/SMS/Zalo thật (chờ chọn provider).

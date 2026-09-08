# API.md — Đặc tả API
> **Version 3 — Last updated 2026-09-08.** Cập nhật theo bản chốt thay đổi Version 2 → Version 3. Xem [DECISIONS.md](DECISIONS.md).

## CRUD (House, Room, Tenant, Contract/ContractVersion/ContractRoom, ElectricityReading/WaterReading, Invoice, User House Access...)

Không có API tự viết — dùng trực tiếp **Supabase auto-generated REST/GraphQL API** (PostgREST) từ schema database, bảo vệ bằng Row Level Security (RLS) — RLS cho mọi bảng nghiệp vụ join qua `tb_user_house_access` (kiểm cả `role` khi thao tác cần quyền `owner`) — xem [DATABASE.md](DATABASE.md) cho schema Version 3. **Mời/thu hồi quyền quản lý** (`INSERT`/`DELETE` trên `tb_user_house_access`) cũng đi thẳng qua PostgREST + RLS, **không cần Edge Function riêng** (khác Version 2).

## Edge Functions (logic phía server)

| Function | Mô tả | Trigger | Trạng thái |
|----------|-------|---------|---|
| `generate-invoice` | Tính & tạo Invoice — **đơn lẻ hoặc hàng loạt theo 1 Nhà/Dãy trọ + 1 kỳ**. Đọc lại chỉ số đã ghi sẵn trong `tb_electricity_reading`/`tb_water_reading` (không nhận chỉ số nhập tay như Version 1/2), tính tiền nhà theo chu kỳ cấu hình (`rentCycleMonths`/`rentCycleAnchorYm`), phí dịch vụ theo m², prorate ngày ở khi có `MOVE_IN`/`MOVE_OUT` trong kỳ, gộp `utilityLines` theo từng phòng (BR-BILL-01..13) | Gọi từ B-02 (Batch)/B-03 (Single) | Logic tính đã code theo schema Version 1 — **cần viết lại hoàn toàn** theo schema Version 3 (đa phòng, đọc lại chỉ số thay vì nhận trực tiếp, chu kỳ tiền nhà, phí dịch vụ m²), đã deploy thử lên project dev theo schema cũ |
| `generate-payment-qr` | Sinh mã QR thanh toán chuẩn **VietQR/NAPAS-247** từ `tb_house.bankBin` + số tài khoản + `totalAmount` của 1 hoá đơn | Gọi từ `generate-invoice` lúc phát hành, hoặc gọi lại riêng lẻ từ B-05 (Invoice Detail → "Gửi lại") | **Mới** — chưa code, cần chọn thư viện/API sinh QR VietQR chuẩn NAPAS-247 |
| `send-notification` | Gửi **Push (FCM/APNs)** cho người có quyền trên Nhà/Dãy trọ liên quan + **SMS/Zalo** (kèm mã QR) cho Tenant | Gọi từ `generate-invoice`, nhắc thanh toán (BR-PAY-04), nhắc ghi chỉ số định kỳ (BR-NOTI-05), mời quản lý (BR-NOTI-06) | Khung đã có, phần gửi thật (TODO) chờ chọn provider + tạo Firebase project — cần thêm nhánh nhắc ghi chỉ số định kỳ |
| `send-otp-sms` | Auth Hook (Send SMS) — gửi OTP qua nhà cung cấp SMS Việt Nam | Supabase Auth gọi khi **bất kỳ tài khoản nào** đăng ký/quên mật khẩu | Khung đã có, TODO chờ chọn eSMS/Speedsms. **Áp dụng cho mọi tài khoản** — không còn ngoại lệ cho Manager (đã bỏ khái niệm tài khoản được tạo hộ) |
| ~~`create-manager-user`~~ | ~~Tạo tài khoản Manager qua Supabase Admin API~~ | | **Đã xoá** — mời quản lý giờ chỉ là 1 dòng ghi vào `tb_user_house_access` qua PostgREST, không cần Edge Function/service-role key — xem [ARCHITECTURE.md](ARCHITECTURE.md) và [BUSINESS-RULES.md](BUSINESS-RULES.md) BR-ROLE-04 |

> `generate-invoice`, `generate-payment-qr`, `send-notification` cần viết mới/viết lại hoàn toàn theo schema Version 3 (xem [DATABASE.md](DATABASE.md)) trước khi hoàn thiện phần gửi Push/SMS/Zalo/QR thật. `send-otp-sms` chỉ cần bỏ ngoại lệ Manager, giữ nguyên logic.

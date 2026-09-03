# API.md — Đặc tả API

## CRUD (Property, Room, Tenant, Contract, Invoice...)

Không có API tự viết — dùng trực tiếp **Supabase auto-generated REST/GraphQL API** (PostgREST) từ schema database, bảo vệ bằng Row Level Security (RLS). Xem [DATABASE.md](DATABASE.md) cho schema.

## Edge Functions (logic phía server)

| Function | Mô tả | Trigger | Trạng thái |
|----------|-------|---------|---|
| `generate-invoice` | Tính & tạo Invoice từ 2 kỳ meter_reading gần nhất + contract (BR-BILL-01..05) | Gọi từ L-13 (Xem trước & Gửi Hoá đơn), sau này thêm Scheduled Trigger hàng tháng | Logic tính đã code xong, đã deploy lên project dev |
| `send-notification` | Gửi Push (FCM/APNs) + SMS/Zalo, ghi vào bảng `notifications` | Gọi từ `generate-invoice`, nhắc thanh toán, yêu cầu mới... | Khung đã có, phần gửi thật (TODO) chờ chọn provider + tạo Firebase project |
| `send-otp-sms` | Auth Hook (Send SMS) — gửi OTP qua nhà cung cấp SMS Việt Nam | Supabase Auth gọi khi user đăng nhập/đăng ký | Khung đã có, TODO chờ chọn eSMS/Speedsms |

> Cả 3 function đã deploy thử lên project Supabase dev để verify compile — logic gửi Push/SMS/Zalo thật cần hoàn thiện khi có tài khoản nhà cung cấp.

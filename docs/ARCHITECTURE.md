# ARCHITECTURE.md — Kiến trúc hệ thống
> **Version 3 — Last updated 2026-09-08.** Cập nhật theo bản chốt thay đổi Version 2 → Version 3: bỏ mô hình 2 loại tài khoản (Landlord tự đăng ký / Manager do Landlord tạo qua Admin API), thay bằng **1 luồng đăng ký duy nhất cho mọi người**, vai trò xác định theo từng Nhà/Dãy trọ. Xem [DECISIONS.md](DECISIONS.md).

## Stack

- **Frontend**: Flutter (mobile app, iOS/Android) — thư mục `src/`.
- **Backend**: Supabase (Postgres DB, Auth, Storage, Edge Functions) — thư mục `supabase/`. Không dùng thêm Vercel, không dùng thêm Firebase (Auth Phone/OTP dùng Supabase Auth + custom Send SMS hook).
- **Auth**: Supabase Auth, **1 loại tài khoản duy nhất** (`tb_user`, 1-1 với `auth.users`) — **mọi người** (không phân biệt sẽ là chủ nhà hay quản lý) tự đăng ký bằng SĐT + OTP + tạo mật khẩu (`signInWithOtp`/`verifyOtp`). **Đã bỏ hoàn toàn** cơ chế Admin API tạo tài khoản hộ của Version 2 (`auth.admin.createUser` gọi từ Edge Function `create-manager-user`) — không còn tài khoản nào được tạo thay cho người khác. Vai trò (chủ nhà/quản lý) **không nằm trong `auth.users`/`tb_user`** mà hoàn toàn ở bảng `tb_user_house_access`, khoá theo số điện thoại — xem [DATABASE.md](DATABASE.md). OTP gửi qua **Send SMS Hook** tuỳ chỉnh, cắm nhà cung cấp SMS brandname Việt Nam (eSMS/Speedsms — xem [REQUIREMENTS.md](REQUIREMENTS.md) INT-02/INT-03), áp dụng cho **mọi tài khoản** (không còn ngoại lệ cho Manager như Version 2). **Tenant không có `auth.users` row** — chỉ là bản ghi dữ liệu (`tb_tenant`), không đăng nhập được.
- **Mời quản lý:** không phải một luồng Auth — chỉ là 1 thao tác ghi dữ liệu (`INSERT` vào `tb_user_house_access` theo số điện thoại), thực hiện trực tiếp từ client qua PostgREST + RLS (chủ nhà chỉ được ghi dòng cho nhà mình có `role=owner`), **không cần Edge Function/service-role key** cho việc này nữa.
- **Notification**: 2 kênh khác nhau theo đối tượng — Push notification trong app cho **người đang có quyền (owner/manager) trên Nhà/Dãy trọ liên quan**; SMS/Zalo **một chiều tới Tenant** (kèm mã QR thanh toán khi có hoá đơn) — xem [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 5.

## Thành phần

- **src/** — Flutter mobile app, 1 app dùng chung cho mọi tài khoản; UI theo vai trò **hiện tại của nhà đang xem**, không theo loại tài khoản (xem lưu ý quan trọng bên dưới). Kết nối trực tiếp Supabase qua SDK `supabase_flutter` (anon key) cho CRUD thông thường (House, Room, Tenant, Contract/ContractVersion/ContractRoom, ElectricityReading/WaterReading, Invoice...), có RLS (Row Level Security) bảo vệ dữ liệu — mọi bảng nghiệp vụ cách ly theo `tb_user_house_access` (join theo `houseId`, kiểm cả `role` khi thao tác cần quyền `owner`), xem [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 7 (Data Isolation).
  - ⚠️ **Vai trò không được cache vào session/state toàn cục** — vì cùng 1 tài khoản có thể có `role` khác nhau ở từng nhà. Mọi màn hình thao tác trên 1 Nhà/Dãy trọ cụ thể phải tự truy vấn quyền hiện tại cho nhà đó trước khi ẩn/hiện hành động (đây là chỗ dev dễ làm sai nhất nếu không đọc kỹ [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 4 và 7).
  - Nhận Push notification qua Firebase Cloud Messaging (Android) / APNs (iOS) — client đăng ký device token, lưu vào Supabase để Edge Function gửi push khi cần.
- **supabase/** — Edge Functions (Deno) + migrations. Dùng cho:
  - Sinh Bill/Invoice — **đơn lẻ hoặc hàng loạt** (1 Nhà/Dãy trọ + 1 kỳ), đọc lại chỉ số điện/nước đã ghi sẵn trong `tb_electricity_reading`/`tb_water_reading` (không nhận chỉ số nhập tay ngay lúc gọi function như Version 2), tính tiền nhà theo `rentCycleMonths`/`rentCycleAnchorYm`, phí dịch vụ theo m², prorate ngày ở, và **sinh mã QR thanh toán chuẩn VietQR/NAPAS-247** từ `tb_house.bankBin` + số tài khoản + tổng tiền. Chạy thủ công từ tab Bills hoặc theo lịch qua Scheduled Triggers (`pg_cron`) nếu cần nhắc tự động.
  - Gửi thông báo: **Push (FCM/APNs)** cho người có quyền trên nhà liên quan + **SMS/Zalo** (kèm mã QR) cho Tenant — cần gọi API bên thứ ba, không gọi trực tiếp từ mobile app.
  - Auth Hook tuỳ chỉnh (Send SMS) để gửi OTP qua nhà cung cấp SMS Việt Nam — dùng cho **mọi tài khoản** khi đăng ký/quên mật khẩu (không còn ngoại lệ cho Manager, vì không còn khái niệm tài khoản được tạo hộ).
  - Tác vụ cần Supabase service-role key (không được nhúng vào app client) — quy mô các tác vụ này **giảm** so với Version 2 vì đã bỏ hẳn Edge Function `create-manager-user`.
- **tests/** — Test cho Flutter app và Edge Functions.
- **design/** — File thiết kế UI/UX (Figma + logo assets).

## Sơ đồ tổng quát

```
[Flutter App: 1 tài khoản, vai trò theo từng nhà] --Supabase SDK (anon key)--> [Supabase: Auth/DB/Storage]
      |                                                              |
      | FCM/APNs device token                                [Scheduled Trigger: pg_cron - optional]
      |                                                              |
      |                                                  [Edge Function: generate-invoice + sinh QR] --service-role key--> [Supabase DB]
      |                                                              |
      +<----------- Push (FCM/APNs) ---------------------------------+-------> [SMS/Zalo Gateway] --> [Tenant: nhận SMS/Zalo kèm QR, không có app]
                                                                      |
                                                          [Send SMS Hook] --> [SMS brandname VN provider] (OTP cho MỌI tài khoản)

Mời quản lý: Flutter App --INSERT tb_user_house_access qua PostgREST (anon key + RLS)--> [Supabase DB]
  (không qua Edge Function, không cần service-role key)
```

> Cập nhật chi tiết khi triển khai cụ thể (schema Supabase, danh sách Edge Functions, chọn nhà cung cấp SMS/Zalo cụ thể, provider tạo mã QR VietQR/NAPAS-247).

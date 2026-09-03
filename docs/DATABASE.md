# DATABASE.md — Thiết kế dữ liệu (Supabase / Postgres)

> Đồng bộ theo [REQUIREMENTS.md](REQUIREMENTS.md) mục 5 (Data Overview) và [BUSINESS-RULES.md](BUSINESS-RULES.md). Đây vẫn là schema sơ bộ — cần thiết kế cụ thể (kiểu dữ liệu, ràng buộc, RLS policy) trước khi viết migration thật trong `supabase/migrations/`.

## Các thực thể

- **landlord** — hồ sơ Chủ trọ, liên kết 1-1 với `auth.users` (Supabase Auth).
- **tenant** — hồ sơ Người thuê (tên, SĐT, ảnh CCCD/CMND, giới tính, tuổi). Tồn tại **độc lập** với hợp đồng ("Tenant Pool" — BR-CTR-06), do 1 landlord tạo (`created_by_landlord_id`); có thể **không** gắn `auth.users` (do landlord tạo hộ) hoặc gắn khi tenant tự có tài khoản qua lời mời (FR-AUTH-04).
- **property** (Dãy trọ/Nhà) — thuộc `landlord_id`: tên, địa chỉ, mô tả, ảnh.
- **room** (Phòng) — thuộc `property_id`: tên/số phòng, diện tích, giá thuê, tiện ích, ảnh, trạng thái (`Trống` / `Đã thuê` / `Đang sửa chữa`), `is_public_listed` (BR-LIST-01/02 — tự tắt khi có hợp đồng Active).
- **contract** (Hợp đồng) — gắn `room_id` + `tenant_id`: ngày bắt đầu/kết thúc, tiền cọc, tiền thuê, đơn giá điện/nước mặc định (snapshot, có thể sửa mỗi lần tạo hoá đơn — BR-BILL-02/03), trạng thái (`Active`/`Ended`). Chỉ 1 hợp đồng `Active` trên 1 phòng tại 1 thời điểm (BR-CTR-04).
- **meter_reading** (Chỉ số điện/nước) — thuộc `room_id`, theo kỳ (`period`): chỉ số điện, nước. Ghi & lưu **độc lập** với việc tạo hoá đơn (BR-CTR-07) — không bắt buộc gắn `contract_id` ngay lúc ghi.
- **invoice** (Hoá đơn/Bill) — gắn `contract_id` + kỳ (`period`): tiền phòng + điện + nước + phí khác, tổng tiền, trạng thái (`Chưa thanh toán` → `Chờ xác nhận` → `Đã thanh toán` / `Quá hạn` — BR-PAY-03), kênh đã gửi (`sent_via`: push/sms/zalo).
- **payment** (Thanh toán) — gắn `invoice_id`: ảnh chứng từ chuyển khoản (Tenant tự đánh dấu), trạng thái xác nhận, `confirmed_by_landlord_id`.
- **maintenance_request** (Yêu cầu) — gắn `tenant_id` + `room_id`: loại (sửa chữa/bảo trì/đăng ký lưu trú/khác), mô tả, ảnh, trạng thái (`Tiếp nhận`/`Đang xử lý`/`Đã xử lý`/`Từ chối`).
- **rental_inquiry** (Yêu cầu liên hệ — Flow #3 Search) — gắn `tenant_id` + `room_id`: trạng thái (`Mới`/`Đã liên hệ`/`Không chốt`). Không tự tạo `tenant`/`contract` (BR-LIST-05).
- **notification** — gắn `user_id` (landlord hoặc tenant qua `auth.users`): loại sự kiện, nội dung, đã đọc/chưa, kênh đã gửi (push/sms/zalo) — nguồn cho Trung tâm thông báo (S-03).

## Sơ đồ quan hệ

```
landlord (1) --- (N) property (1) --- (N) room (1) --- (N) meter_reading
   |                                        |
   |                                        +--- (N) contract (N) --- (1) tenant --- (N) [tenant tồn tại độc lập, chưa gắn contract nào]
   |                                                    |                    |
   |                                                    +--- (N) invoice     +--- (N) rental_inquiry --- (1) room
   |                                                    |         |
   |                                                    |         +--- (N) payment
   |                                                    +--- (N) maintenance_request --- (1) tenant
   |
   +--- (N) notification            tenant --- (N) notification
```

## Multi-tenancy & RLS (xem [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 6)

- Mỗi `landlord` chỉ thấy `property`/`room`/`tenant`/`contract`/`invoice` do chính mình tạo (`landlord_id` = `auth.uid()` tương ứng).
- Mỗi `tenant` (khi có tài khoản riêng) chỉ thấy `contract`/`invoice`/`maintenance_request` gắn với chính mình.
- 1 `tenant` (tài khoản) có thể có `contract` với **nhiều landlord khác nhau** theo thời gian (BR-DATA-03) — không giới hạn 1 tenant thuộc 1 landlord duy nhất.

> Cập nhật schema chi tiết (kiểu dữ liệu, ràng buộc, index, RLS policy cụ thể) khi viết migration thật.

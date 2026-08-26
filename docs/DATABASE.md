# DATABASE.md — Thiết kế dữ liệu (Supabase / Postgres)

## Các thực thể

- **house** — địa chỉ (address), số tầng (floor), diện tích (area_m2)
- **room** — thuộc một house (house_id)
- **tenant** — tên (name), giới tính (gender: M/F), tuổi (age), email (email), số điện thoại (phone)
- **contract** — gắn room_id + tenant_id, gồm: ngày bắt đầu/kết thúc (term), giá thuê (rent_price), giá điện (electricity_price), giá nước (water_price), phí gửi xe (parking_fee), kỳ thanh toán (payment_period)
- **meter_reading** — thuộc contract_id, theo kỳ (period): chỉ số điện, nước, phí dịch vụ (electricity_reading, water_reading, service_fee)
- **bill** — sinh từ contract + meter_reading của kỳ: tổng tiền, trạng thái đã gửi (sent_via: email/sms), trạng thái thanh toán

## Sơ đồ quan hệ

```
house (1) --- (N) room (1) --- (N) contract (N) --- (1) tenant
                                     |
                                     +--- (N) meter_reading
                                     |
                                     +--- (N) bill
```

> Cập nhật schema chi tiết (kiểu dữ liệu, ràng buộc, RLS policy trên Supabase) khi thiết kế cụ thể.

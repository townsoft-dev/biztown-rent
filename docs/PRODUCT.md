# PRODUCT.md — Yêu cầu sản phẩm

## Tổng quan

RentEase là ứng dụng mobile (Flutter) giúp chủ nhà quản lý nhà/phòng cho thuê: đăng ký nhà/phòng, khách thuê, hợp đồng, ghi số điện nước và gửi hóa đơn hàng tháng.

## Đối tượng người dùng

- Chủ nhà trọ / chủ căn hộ cho thuê
- (Tùy chọn mở rộng sau) Khách thuê

## Luồng nghiệp vụ chính

1. **Đăng ký House/Room** — địa chỉ, số tầng, diện tích (m²), danh sách phòng.
2. **Đăng ký Tenant** — tên, giới tính, tuổi, email/số điện thoại liên hệ.
3. **Tạo Contract** — gắn Room + Tenant, gồm: thời hạn hợp đồng, giá thuê, giá điện, giá nước, phí gửi xe, kỳ thanh toán.
4. **Check meter** (định kỳ hàng tháng) — ghi số điện, nước, phí dịch vụ.
5. **Sinh Bill** — tự động tính hóa đơn từ số liệu check meter + đơn giá trong Contract.
6. **Gửi Bill** — qua Email hoặc SMS cho khách thuê.

## Tính năng chính (dự kiến)

- [ ] Quản lý House/Room
- [ ] Quản lý Tenant
- [ ] Quản lý Contract
- [ ] Check meter (điện/nước/dịch vụ) hàng tháng
- [ ] Sinh & gửi Bill qua Email/SMS
- [ ] Báo cáo doanh thu

> Cập nhật danh sách tính năng chi tiết khi có yêu cầu cụ thể hơn.

-- Đơn giá điện/nước riêng theo từng PHÒNG (dungtv yêu cầu 16/09/2026).
--
-- Lý do: trước đây đơn giá chỉ khai ở cấp Nhà (`tb_house.default_*_price`) và
-- form Hợp đồng luôn điền sẵn từ đó. Nhưng thực tế chủ trọ có thể ưu tiên giá
-- điện khác cho một phòng cụ thể — dungtv: *"biết đâu người thuê có thể được
-- ưu tiên tính giá điện khác"*. Không có chỗ khai ở cấp Phòng thì mỗi lần tạo
-- hợp đồng phải nhớ sửa tay, rất dễ quên và tính sai tiền.
--
-- Thứ tự ưu tiên khi điền sẵn form Hợp đồng: giá của PHÒNG → nếu trống thì lấy
-- giá của NHÀ. Lưu ý quan trọng: đây vẫn chỉ là giá trị ĐIỀN SẴN cho tiện.
-- Nguồn tính tiền hoá đơn LUÔN là bản snapshot trên `tb_contract_version`
-- (xem docs/DATABASE.md mục "Đơn giá tồn tại ở 2 nơi") — nay thành 3 nơi khai
-- báo nhưng vẫn đúng 1 nguồn tính tiền, không đổi nguyên tắc cũ.

alter table tb_room
  add column if not exists default_electricity_price numeric,
  add column if not exists default_water_price numeric;

comment on column tb_room.default_electricity_price is
  'Đơn giá điện riêng của phòng này, ghi đè giá mặc định của Nhà khi điền sẵn form Hợp đồng. NULL = dùng giá của Nhà. Không phải nguồn tính tiền — nguồn tính tiền là snapshot trên tb_contract_version.';

comment on column tb_room.default_water_price is
  'Đơn giá nước riêng của phòng này, ghi đè giá mặc định của Nhà khi điền sẵn form Hợp đồng. NULL = dùng giá của Nhà. Không phải nguồn tính tiền — nguồn tính tiền là snapshot trên tb_contract_version.';

-- P-06 Manager Detail (Figma node 220:5099) có field "Note" (textarea, VD
-- "Manages the Binh An row on weekdays") — chưa có cột nào chứa được thông
-- tin này trên `tb_user_house_access`. Thêm 1 cột text optional, đồng bộ
-- xuống mọi dòng của cùng 1 Manager khi lưu (giống full_name/id_number,
-- xem UserRepository.saveManager) — không phải note RIÊNG cho từng nhà.
alter table tb_user_house_access
  add column note text;

comment on column tb_user_house_access.note is 'Ghi chú tự do do chủ nhà nhập lúc mời/sửa Manager (P-06) — đồng bộ giống nhau trên mọi dòng của cùng 1 người, không riêng theo từng nhà.';

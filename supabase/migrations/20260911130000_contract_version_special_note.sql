-- T-06/T-07 Figma đều có field "Special note" (textarea) riêng biệt với
-- "Late fee terms" — phát hiện lúc code T-07 (11/09/2026): T-06 đã hiện field
-- này trên form nhưng KHÔNG lưu (không có cột tương ứng), dữ liệu người dùng
-- gõ bị mất khi Lưu. Thêm cột thật, không lồng vào late_fee_terms/real_estate.
alter table tb_contract_version
  add column special_note text;

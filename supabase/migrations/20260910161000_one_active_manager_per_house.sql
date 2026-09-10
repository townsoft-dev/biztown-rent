-- Quyết định chốt cùng dungtv 2026-09-10 (đợt P-0x): 1 Nhà chỉ được có ĐÚNG
-- 1 Manager active tại 1 thời điểm (khác `owner`, không giới hạn số lượng).
-- Ở P-06, nếu chủ nhà tick 1 nhà đã có Manager khác đang active, checkbox đó
-- phải bị disable + hiện tên Manager hiện tại — ràng buộc này ở DB là lưới
-- chặn cuối, đảm bảo không lỡ lưu 2 Manager active cùng lúc cho 1 nhà dù UI
-- có lỗi hay có 2 request chạy đồng thời.
create unique index one_active_manager_per_house
  on tb_user_house_access (house_id)
  where role = 'manager' and is_active = true;

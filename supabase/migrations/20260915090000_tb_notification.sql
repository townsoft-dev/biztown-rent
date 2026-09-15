-- Bảng thông báo trong app (Notification Center, S-03) — trước giờ màn này
-- chỉ là UI giả với dữ liệu cứng, chưa có bảng lưu thật. Làm trước 3 loại
-- BR-NOTI tức thời (01 hoá đơn tạo & gửi, 03 đánh dấu đã thu tiền, 06 được
-- mời làm quản lý) — 3 loại còn lại (02/04/05) chạy theo lịch (cron), để đợt
-- sau. Xem docs/DECISIONS.md.
--
-- Lưu payload dạng có cấu trúc (`type` + `payload` jsonb), KHÔNG lưu sẵn
-- title/body dựng thành câu — vì nội dung hiển thị cho chủ nhà/quản lý phải
-- theo đúng ngôn ngữ UI người đó đang chọn (EN/VI/KO, FR-MGR-05), không cố
-- định tiếng Việt như SMS/Zalo gửi Tenant (BR-NOTI-07 chỉ áp dụng cho Tenant).
-- Flutter tự dựng câu qua AppStrings.t('notifications.<type>...', payload)
-- tại thời điểm hiển thị, đúng ngôn ngữ của người đang xem.
create table tb_notification (
  id uuid primary key default gen_random_uuid(),
  recipient_phone text not null,
  house_id uuid references tb_house (id) on delete cascade,
  type text not null check (type in ('invoice_sent', 'invoice_collected', 'manager_invited')),
  payload jsonb not null default '{}'::jsonb,
  target_invoice_id uuid references tb_invoice (id) on delete cascade,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index tb_notification_recipient_idx on tb_notification (recipient_phone, created_at desc);

alter table tb_notification enable row level security;

-- Chỉ chủ nhân (đúng SĐT) mới thấy dòng của mình — mọi INSERT đều đi qua
-- Edge Function bằng service role (bypass RLS) sau khi tự kiểm tra quyền,
-- không có policy INSERT nào cho user thường ở đây.
create policy "Notification visible to recipient" on tb_notification
  for select using (recipient_phone = current_user_phone());

-- Cho phép tự đánh dấu đã đọc (chỉ đúng dòng của mình).
create policy "Notification markable by recipient" on tb_notification
  for update using (recipient_phone = current_user_phone())
  with check (recipient_phone = current_user_phone());

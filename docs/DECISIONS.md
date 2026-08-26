# DECISIONS.md — Nhật ký quyết định

Ghi lại các quyết định quan trọng và lý do, để hiểu "tại sao" thay vì chỉ "cái gì".

## 2026-08-26 — Khởi tạo project

- Tên tạm thời: **RentEase**.
- Cấu trúc thư mục: `src/` (frontend), `backend/` (Go), `tests/`, `design/`, `docs/`.
- Design assets nằm trong repo tại `design/` (ban đầu định để ngoài repo, sau đổi lại để trong git cho dễ đồng bộ với code).

## 2026-08-26 — Chốt stack: Flutter + Vercel/Supabase

- Frontend: **Flutter** (mobile, iOS/Android) thay vì React Native — bỏ `package.json` ở root, thêm `pubspec.yaml` placeholder trong `src/`.
- Backend: **Supabase** (Postgres, Auth, Storage) làm nguồn dữ liệu chính, app gọi trực tiếp qua SDK. **Vercel** hosting serverless functions cho tác vụ cần service-role key hoặc gửi Email/SMS — không dùng Go nữa, xóa `go.mod` ở root, thêm `backend/package.json` (Node, cho Vercel functions).
- Lý do tách Vercel functions riêng: tránh nhúng Supabase service-role key vào mobile app (rủi ro bảo mật), và cần gọi API bên thứ ba (Email/SMS) từ server.

## 2026-08-26 — Kênh thông báo Bill: Email/SMS thay vì Zalo

- Bỏ Zalo khỏi kênh gửi Bill, chỉ dùng **Email hoặc SMS**.
- Lý do: Zalo yêu cầu đăng ký Zalo Official Account (OA) và xin duyệt quyền gửi tin nhắn, thêm rào cản không cần thiết; Email/SMS tích hợp đơn giản hơn (Resend/SendGrid cho email, Twilio/eSMS/Speedsms cho SMS) và không cần approval từ bên thứ ba.

## 2026-08-26 — Thêm folder `changelog/` riêng cho nhật ký thay đổi

- Tạo thư mục `changelog/` ở root, tách biệt với `docs/CHANGELOG.md`.
- `docs/CHANGELOG.md` giữ vai trò tóm tắt thay đổi theo release (hướng người dùng cuối, theo chuẩn Keep a Changelog).
- `changelog/` là nhật ký chi tiết cho developer: mỗi ngày một file (`YYYY-MM-DD.md`), mỗi entry ghi giờ, người thực hiện, tính năng/khu vực, mô tả cụ thể đã sửa.

## 2026-08-26 — Bỏ Vercel, dùng Supabase-only cho backend

- Bỏ Vercel khỏi stack. Backend chạy hoàn toàn trên **Supabase**: CRUD qua auto-generated REST API (PostgREST) + RLS, logic phía server (sinh Bill, gửi Email/SMS) qua **Supabase Edge Functions**, lịch định kỳ qua **Scheduled Triggers** (`pg_cron`).
- Đổi thư mục `backend/` (Vercel, Node) thành `supabase/` (Edge Functions + migrations).
- Lý do: quy mô dự án không cần thêm một hạ tầng/tài khoản riêng cho Vercel — Supabase Edge Functions đã đáp ứng đủ (cron + gọi API bên thứ ba an toàn với service-role key), giảm số lượng dịch vụ phải quản lý và số tài khoản/token cần cấp cho agent.

## 2026-08-26 — Thêm CLAUDE.md (root) + rule Flutter cho Claude Code

- Tạo `./CLAUDE.md` (root, thật sự được Claude Code auto-load) — import lại `docs/CLAUDE.md` sẵn có + thêm quy tắc quy trình (changelog, decisions, không tự quyết kiến trúc lớn).
- Tạo `.claude/rules/flutter.md` (path-scoped, chỉ load khi làm việc trong `src/**/*.dart`) làm nơi đặt tiêu chuẩn code Flutter senior-dev — hiện để placeholder, điền chi tiết (state management, cấu trúc `lib/`...) sau khi có design UI + mô tả nghiệp vụ.
- Lý do: `docs/CLAUDE.md` nằm trong subfolder nên Claude Code không tự load nó làm instruction ở đầu session — cần file `CLAUDE.md` thật ở root. Rule path-scoped giúp quy tắc Flutter không tốn context khi làm việc ngoài `src/`.

## 2026-08-26 — GitHub repo: chuyển sang Organization `townsoft-dev`

- Repo tạo ban đầu ở tài khoản cá nhân (`dungtv1291`), sau đó **transfer sang Organization `townsoft-dev`** ngay khi nhận ra, để tránh phải làm lại lúc bàn giao.
- Git remote local cập nhật sang `git@github.com:townsoft-dev/rentease.git`.

## 2026-08-26 — Supabase: tạm thời tạo bằng email cá nhân

- Project Supabase sẽ được tạo bằng email cá nhân của dungtv (không phải tài khoản/org khách), do khách chưa có tài khoản sẵn tại thời điểm này.
- Chấp nhận đánh đổi: sẽ cần **transfer ownership project** sang tài khoản khách khi bàn giao (Supabase hỗ trợ transfer project giữa các organization ngay trong dashboard, xem thảo luận trước đó).

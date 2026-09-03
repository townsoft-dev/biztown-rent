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

## 2026-08-26 — Thêm docs/SETUP.md cho bàn giao

- Tạo `docs/SETUP.md`: hướng dẫn setup môi trường đầy đủ (Flutter SDK, Node/Supabase CLI, lấy API keys từ Supabase Dashboard, `supabase link`, cả 2 kịch bản dùng lại project hiện có hoặc tạo project mới).
- Lý do: chủ động không lo bảo mật token/key trong giai đoạn dev nội bộ (khách sẽ tự lấy key riêng của họ khi nhận bàn giao), nhưng cần tài liệu rõ ràng để bước bàn giao chỉ còn là "đọc file này và làm theo" thay vì phải giải thích lại từ đầu.

## 2026-08-26 — Chốt tên chính thức: BizTown Rent-Manager

- Khách hàng chốt tên: **Brand = BizTown**, **Product = Rent-Manager**. Thay thế tên tạm "RentEase" trên toàn bộ docs/code.
- GitHub repo đổi tên từ `rentease` sang `biztown-rent` (org `townsoft-dev` không đổi) — git remote local đã cập nhật.
- Flutter package name (`src/pubspec.yaml`) đổi sang `rent_manager` (snake_case theo quy tắc Dart, không dùng được dấu gạch ngang).
- `package.json` (tooling) đổi sang `biztown-rent-tooling`.
- Supabase project trên dashboard **vẫn giữ tên `rentease`** (chỉ là tên hiển thị, không ảnh hưởng chức năng) — có thể đổi tay trên Supabase Dashboard sau nếu muốn đồng bộ, không bắt buộc.
- Các entry cũ trong `changelog/` giữ nguyên tên "rentease"/"RentEase" vì là nhật ký lịch sử tại thời điểm đó, không sửa lại.

## 2026-08-28 — Nhận bộ docs nghiệp vụ + design từ Dream, đảo ngược quyết định kênh thông báo

Dream (dreamnguyen@townsoftvina.com) push lên bộ docs nghiệp vụ đầy đủ (PRODUCT-OVERVIEW, REQUIREMENTS, BUSINESS-RULES, USER-FLOWS, SCREEN-SPEC, DESIGN-SYSTEMS) + file Figma wireframe. Đây là nguồn spec chính thức, có độ ưu tiên cao hơn các giả định ban đầu của dungtv/Claude khi chưa có thông tin nghiệp vụ. Rà soát và chốt lại các điểm mâu thuẫn với quyết định cũ:

- **Kênh thông báo: đảo ngược quyết định "Email/SMS thay Zalo" (2026-08-26) → dùng Push notification + SMS/Zalo, áp dụng cho CẢ Landlord và Tenant.** Lý do: đây là yêu cầu Must trong REQUIREMENTS.md (FR-NOTI-01/02) và BUSINESS-RULES.md (mục 5), do đội sản phẩm xác nhận là cần thiết cho người dùng Việt Nam (không phải ai cũng mở app/email thường xuyên). Chấp nhận chi phí phải tích hợp Zalo ZNS/OA (đã lường trước ở quyết định cũ) vì giờ đã là yêu cầu chính thức, không phải giả định. Email bị loại bỏ hoàn toàn khỏi kênh thông báo (không xuất hiện trong spec mới).
- **Auth: dùng Supabase Auth (Phone + OTP) thay vì thêm Firebase.** REQUIREMENTS.md ghi "Firebase Phone Auth" nhưng đã verify: Supabase Auth hỗ trợ sẵn `signInWithOtp`/`verifyOtp`, và có **Send SMS Hook** cho phép cắm nhà cung cấp SMS Việt Nam (eSMS/Speedsms) thay vì Twilio/MessageBird/Vonage mặc định — đáp ứng đúng yêu cầu INT-02/INT-03 mà không cần thêm Firebase vào stack, giữ đúng hướng "Supabase-only" đã chốt trước đó.
- **Quy mô sản phẩm**: xác nhận đây là SaaS 2 chiều đa Landlord (multi-tenant) có marketplace tìm phòng công khai cho Tenant (Flow #3), không phải công cụ quản lý nội bộ 1 chủ trọ như hiểu ban đầu — ảnh hưởng tới thiết kế RLS multi-tenant trong Supabase (xem BUSINESS-RULES.md mục 6 Data Isolation).
- Đã cập nhật `docs/ARCHITECTURE.md` theo các điểm trên. `docs/DATABASE.md` cần cập nhật tiếp theo cho khớp entity đầy đủ (Property, Room, Tenant, Contract, Invoice, Payment, MaintenanceRequest, Notification, RentalInquiry).

## 2026-09-03 — Chốt state management: Riverpod

- Dùng **Riverpod** cho toàn bộ Flutter app, thay vì Bloc. Lý do: type-safe, ít boilerplate hơn Bloc, phù hợp app có nhiều role (Landlord/Tenant) và nhiều loại state cần chia sẻ giữa các màn hình liên quan (VD: Room ↔ Contract ↔ Invoice).
- Chiến lược chuẩn bị: **hạ tầng/backend dựa trên business rules đã chốt (schema DB, Edge Functions) được làm ngay**, không đợi design hoàn thiện vì không phụ thuộc pixel UI. **Code UI/màn hình Flutter đợi design final** (hiện Figma còn là Low-fi Ver1, tránh code rồi sửa đi sửa lại khi design đổi).

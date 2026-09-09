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

## 2026-09-03 (chiều) — Thu hẹp phạm vi Phase 1: bỏ app Tenant, thêm Manager sub-account, đổi cấu trúc app sang 5 menu

**Đây là thay đổi phạm vi lớn nhất kể từ khi bắt đầu dự án**, do Dream trao đổi trực tiếp với sếp và quyết định:

- **Bỏ hẳn app/tài khoản Tenant khỏi Phase 1.** Tenant không đăng nhập, không dùng app — chỉ là hồ sơ dữ liệu (tên, SĐT, CCCD...) và là người nhận hoá đơn/nhắc thanh toán một chiều qua SMS/Zalo. Toàn bộ mảng "2 chiều" (Landlord + Tenant cùng dùng app) từng là định hướng cốt lõi từ 2026-08-28 nay bị đảo ngược hoàn toàn.
- **Thêm vai trò Manager** — tài khoản phụ do Landlord tạo trực tiếp (không tự đăng ký), được cấp quyền truy cập theo **từng Nhà/Dãy trọ cụ thể** (bảng `manager_house_access`), không mặc định thấy toàn bộ dữ liệu của Landlord.
- **Cấu trúc app đổi từ "8 core flows" sang 5 menu chính** (bottom nav): House/Room Management, Tenant Management, Contract Management, Bill Management (core), User Setting. **Bill Management (tự động tạo & gửi hoá đơn hàng tháng) là chức năng quan trọng nhất.**
- **Ngoài phạm vi Phase 1 (dời Phase 2):** House/Room Search/Discovery (marketplace tìm phòng — từng là Flow #3, tưởng đã là core flow chính thức từ 2026-08-28), Service Request Management (yêu cầu sửa chữa/bảo trì qua app — Flow #8 cũ), Revenue Report như 1 màn hình/menu riêng (số liệu tổng/đã thu/chưa thu nay xem tạm qua filter trong Bill Management).
- **Trạng thái hoá đơn đổi** từ `Chưa thanh toán → Chờ xác nhận → Đã thanh toán/Quá hạn` sang `Draft → Sent → Collected/Overdue` — bỏ hoàn toàn bước Tenant tự đánh dấu đã chuyển khoản + đính ảnh chứng từ (không còn ý nghĩa vì Tenant không có app). Landlord/Manager là bên duy nhất cập nhật trạng thái thu tiền.
- **Thêm Contract Versioning** — mỗi lần tạo/gia hạn/sửa điều khoản hợp đồng tạo 1 bản ghi `contract_version` mới (`changeReason`: New/Renewal/Amendment), giữ lịch sử đầy đủ thay vì ghi đè như trước. Hoá đơn snapshot `contractVersionId` tại thời điểm phát hành.
- **Thêm trường thông tin môi giới/cò nhà** (`realEstate`: tên, liên hệ, phí) — optional, theo từng phiên bản hợp đồng.
- Nguồn tham khảo cho đợt cập nhật: Dream mô tả bằng văn bản + chia sẻ FigJam board `PAuYWdSon7WcPKdRQStoPR` (entity + luồng theo 5 menu) qua phiên làm việc với Claude (Cowork), 2026-09-03.

**Tác động cần dev lưu ý:**
- Migration `supabase/migrations/20260903121605_initial_schema.sql` (11 bảng, đã áp lên Supabase dev thật) được viết theo schema **Version 1** (còn `payments`, `maintenance_requests`, `rental_inquiries`, notification cho Tenant) — **chưa khớp** schema Version 2 mô tả ở [DATABASE.md](DATABASE.md). Cần viết migration mới trước khi code UI theo scope mới.
- Edge Function `generate-invoice` cần rà soát lại theo `contract_version`/snapshot mới; `send-notification` cần bỏ nhánh push cho Tenant.
- Toàn bộ `docs/*.md` (PRODUCT-OVERVIEW, REQUIREMENTS, BUSINESS-RULES, USER-FLOWS, SCREEN-SPEC, DESIGN-SYSTEMS, ARCHITECTURE, DATABASE, API, CLAUDE) đã được cập nhật lên Version 2 trong cùng đợt này (2026-09-04)
- File Figma wireframe .fig cũ được xóa đi, thiết kế mới được cập nhật liên tục - tham khảo trực tiếp từ đường link figma đính kèm trong file [DESIGN.md](DESIGN.md)

## 2026-09-04 — Rà soát chéo docs/, chốt 4 điểm mâu thuẫn

Sau đợt viết lại Version 2 (2026-09-03/04), rà soát chéo toàn bộ `docs/*.md` phát hiện 5 điểm chưa khớp; chốt xử lý 4/5 điểm (điểm thứ 5 — `docs/CHANGELOG.md` chưa cập nhật theo quy trình — tạm để nguyên, chưa xử lý đợt này):

- **Quy ước đặt tên bảng:** thống nhất dùng `snake_case`, **không tiền tố** (`house`, `manager_house_access`, `contract_version`...) làm tên chính thức trên toàn bộ tài liệu. Trước đó tồn tại 3 cách viết khác nhau: `tb_xxx` (SCREEN-SPEC.md, USER-FLOWS.md, một số chỗ trong BUSINESS-RULES.md — di sản từ FigJam board nháp), không tiền tố (DATABASE.md), và PascalCase (REQUIREMENTS.md mục 5, di sản Version 1). Đã sửa lại `SCREEN-SPEC.md`, `USER-FLOWS.md`, `BUSINESS-RULES.md`, `REQUIREMENTS.md` cho khớp `DATABASE.md`, đồng thời thêm ghi chú quy ước ngay đầu mục "Các thực thể" trong `DATABASE.md` để làm nguồn tham chiếu duy nhất.
- **`invoice` thiếu mốc thời gian gửi/thu tiền:** `DATABASE.md` chưa có field lưu thời điểm chuyển trạng thái, trong khi SCREEN-SPEC.md (B-03) và Figma cần hiển thị lịch sử. Thêm `sentAt` (Draft→Sent) và `collectedAt` (→Collected) vào entity `invoice`.
- **"Đến hạn ghi số" (FR-NOTI-01) chưa có rule/điều hướng tương ứng:** REQUIREMENTS.md nhắc tới push "đến hạn ghi số" nhưng BUSINESS-RULES.md không có rule nào khớp, và bản thân cụm từ này mâu thuẫn với BR-CTR-07 (đã bỏ bước ghi số riêng, chỉ số điện/nước nhập trực tiếp lúc tạo hoá đơn). Làm rõ: đây là nhắc **đến hạn tạo hoá đơn kỳ mới** (trong đó có nhập chỉ số), không phải một luồng "ghi số" độc lập. Thêm **BR-NOTI-05** vào BUSINESS-RULES.md mục 5, và thêm điều hướng tương ứng (tap → màn Tạo hoá đơn) vào SCREEN-SPEC.md S-03.
- **Mô hình auth của Manager chưa rõ ràng:** ARCHITECTURE.md mô tả Manager dùng chung Supabase Auth với Landlord, nhưng DATABASE.md lại mô tả `manager_account` tự lưu `phone`/`passwordHash` riêng như một bảng auth độc lập — không nhất quán. Chốt: **Manager là 1-1 với `auth.users`, dùng chung Supabase Auth**, được tạo bởi Landlord qua Edge Function (service-role key) gọi Supabase Admin API (`auth.admin.createUser`) — không phải self-service signup, không có bảng `passwordHash` riêng. Đã sửa `DATABASE.md` (bỏ `passwordHash` khỏi `manager_account`) và `ARCHITECTURE.md` (nêu rõ cơ chế Admin API) cho khớp nhau.

## 2026-09-07/08 — Version 2 → Version 3: 3 thay đổi cốt lõi + đảo ngược 2 quyết định cũ

Nguồn: bản chốt "Chốt thay đổi version 3" (Dream, 07/09) tổng hợp qua phiên làm việc với Claude (Cowork), có tham chiếu thêm chỉ đạo của Mr. Han về nghiệp vụ ghi chỉ số (08/09) và kịch bản thật `시뮬레이션 케이스 (Mr.Han).md` (3 nhà A/B/C, chủ khác nhau, con gái làm quản lý — dùng để kiểm chứng thiết kế). Đã cập nhật FigJam board `PAuYWdSon7WcPKdRQStoPR` (khu vực "Version 3 — CURRENT") và toàn bộ `docs/*.md` trong cùng đợt này. Ba thay đổi cốt lõi:

- **Cấu trúc app: 5 menu → 4 tab.** Gộp Tenant Management + Contract Management thành 1 tab "Tenant & Contract" (chuyển qua lại bằng segmented control), tách Bill Management thành tab riêng "Bills" (chức năng cốt lõi), đổi User Setting thành "Profile". Lý do: giảm số lần bấm. Số màn hình tăng từ 22 lên 34 (Home 4→8, Tenant&Contract 7→10, Bills 3→5, Profile 4→7) — xem [SCREEN-SPEC.md](SCREEN-SPEC.md) mục 1.
- **Thêm nghiệp vụ ghi chỉ số điện/nước** — thay đổi quan trọng nhất. Version 2 nhập chỉ số ngay lúc tạo hoá đơn, không khớp cách làm thực tế (đi ghi số cả nhà một lượt rồi mới tính hoá đơn sau) và không có chỗ lưu chỉ số cho phòng trống. Theo chỉ đạo của Mr. Han (*"검침은 1개 호실이 1개의 계량기를 갖는다는 전제하에 별도의 계량기 등록, 관리는 하지 않는다"*): chỉ số gắn trực tiếp vào phòng, không có bảng/thực thể công tơ riêng. Có **3 loại chỉ số** trong cùng 1 chuỗi lịch sử theo phòng (định kỳ/nhận phòng/trả phòng, nối nhau bằng `previousReadingId`) — thiếu 2 loại sau thì mỗi lần đổi khách sẽ tính nhầm tiền điện/nước của khách cũ sang khách mới (đã kiểm chứng bằng ví dụ số học trong bản chốt). Đặt `MOVE_IN`/`MOVE_OUT` thành bước chặn bắt buộc trong flow Hợp đồng (không phải nút tự do trong 1 menu riêng) để tránh bỏ sót ngoài hiện trường — bỏ sót thì mất dữ liệu vĩnh viễn.
- **Hoá đơn: tự động hoá sâu hơn.** Thêm tạo hàng loạt (chọn 1 nhà + 1 kỳ → tạo cho mọi hợp đồng Active, hợp đồng thiếu chỉ số thì bỏ qua chứ không ước lượng), chu kỳ thu tiền nhà cấu hình được (tách biệt khỏi chu kỳ điện/nước luôn hàng tháng), prorate theo ngày ở khi đổi khách giữa tháng, phí dịch vụ tính theo m² (chốt cứng vào hợp đồng lúc tạo), hạn thanh toán = ngày cố định trong tháng (thay vì N ngày sau khi gửi), và sinh mã QR chuẩn VietQR/NAPAS-247 kèm theo hoá đơn.

Kèm theo đó, **hợp đồng đổi từ 1 hợp đồng = 1 phòng sang 1 hợp đồng có thể gồm NHIỀU phòng** (bảng nối mới `tb_contract_room`, ràng buộc UNIQUE phòng khi hợp đồng Active) — phục vụ ca nhiều người thuê chung 1 tầng nhưng 1 người đại diện đứng tên ký (theo kịch bản của Mr. Han). Cọc chuyển từ tính theo phòng sang tính theo cả hợp đồng; hoá đơn tách điện/nước theo từng phòng nhưng gộp 1 dòng tiền nhà/phí dịch vụ cho cả hợp đồng.

**Đảo ngược 2 quyết định của Version 2:**

1. **Quy ước đặt tên bảng — quay lại dùng tiền tố `tb_`.** Quyết định "không tiền tố" chốt ngày 2026-09-04 (mục ngay phía trên) **không còn hiệu lực**. Theo đúng FigJam board và bản chốt V3 mục 6. `DATABASE.md` là nguồn tham chiếu duy nhất, đã cập nhật lại toàn bộ `SCREEN-SPEC.md`, `USER-FLOWS.md`, `REQUIREMENTS.md`, `BUSINESS-RULES.md` theo tên mới.
2. **Vai trò Chủ nhà/Quản lý — bỏ khỏi tài khoản, gắn theo TỪNG Nhà/Dãy trọ.** Version 2 gắn vai trò cứng vào loại tài khoản (`landlord_account` luôn là chủ, tạo `manager_account` qua Supabase Admin API). Vỡ ngay khi 1 người cần làm quản lý cho 2 chủ trọ không liên quan tới nhau bằng cùng 1 số điện thoại — kịch bản của Mr. Han chưa lộ vấn đề này vì cả 3 nhà đăng ký dưới 1 tài khoản, nhưng lộ ngay khi mở rộng (VD con gái quản lý nhà cho cả bố và mẹ, mà mẹ có tài khoản riêng). Chốt: gộp `landlord_account` + `manager_account` thành 1 bảng `tb_user` thuần danh tính (bỏ hẳn cột `role`/`createdByUserId`/`invitedAt`); vai trò chuyển hẳn sang `tb_user_house_access`, khoá theo **số điện thoại** (không phải `userId`) để mời được người chưa có tài khoản — dòng quyền tự có hiệu lực khi người đó đăng ký lần đầu. Một luồng đăng ký duy nhất (SĐT+OTP) cho mọi người, không còn "Main Manager tạo tài khoản cho quản lý". **Xoá hẳn Edge Function `create-manager-user`** và việc dùng Supabase Admin API cho việc này — đây là khoản tiết kiệm lớn nhất của đợt cập nhật. Thu quyền chỉ xoá dòng do chính người thu quyền đã cấp, không dùng cờ vô hiệu hoá tài khoản (tránh 1 chủ nhà giết nhầm quyền do chủ nhà khác cấp).

**Tác động cần dev lưu ý:** Migration `20260903121605_initial_schema.sql` (Version 1, đã áp lên Supabase dev) càng lạc hậu hơn — cần viết migration mới hoàn toàn theo `DATABASE.md` Version 3. Edge Function `generate-invoice` cần viết lại toàn bộ (đọc lại chỉ số thay vì nhận nhập tay, hỗ trợ hàng loạt, chu kỳ tiền nhà, phí dịch vụ m²); thêm `generate-payment-qr` mới. Figma wireframe MVP hiện tại vẫn là 22 màn/Version 2 (page "MVP Wireframes (EN) - OLD" gắn nhãn SUPERSEDED) — cần build lại 34 màn/4 tab theo `SCREEN-SPEC.md` trước khi code UI. Toàn bộ `docs/*.md` đã được cập nhật lên Version 3 trong cùng đợt này (2026-09-08).

## 2026-09-08 (đợt 2, cùng ngày) — 3 chỉnh sửa trực tiếp trong FigJam: bỏ unitPrice/totalAmount, gộp màn ghi chỉ số, rõ nghĩa recurringFees

Dream sửa trực tiếp 3 điểm trong FigJam board `PAuYWdSon7WcPKdRQStoPR` (khu vực "Version 3 — CURRENT") sau đợt viết lại tài liệu ở trên cùng ngày. Đã soi lại board trực tiếp để lấy đúng câu chữ rồi cập nhật toàn bộ `docs/*.md` liên quan:

- **Bỏ `unitPrice`/`totalAmount` khỏi `tb_electricity_reading`/`tb_water_reading`** (còn 17 field, trước đó 18). Lý do: đơn giá dùng tính tiền luôn phải lấy từ `contract_version.electricityUnitPrice`/`waterUnitPrice` **tại thời điểm lên hoá đơn**, giữ thêm 1 bản snapshot trên chính bản ghi chỉ số là dư thừa và dễ lệch nếu hợp đồng đổi đơn giá giữa lúc ghi số và lúc lên hoá đơn. Đơn giá/thành tiền theo từng phòng giờ chỉ tồn tại tại điểm tính hoá đơn, trong `tb_invoice.utilityLines`. Nhân tiện làm rõ thêm 3 điểm vốn đã đúng về logic nhưng chưa nói rõ bằng lời trong tài liệu cũ: `previousReading` chỉ là snapshot hiển thị, **không phải nguồn sự thật** (nguồn sự thật là `previousReadingId`); `isLocked` là **derived, không phải cột lưu trong DB** (= TRUE nếu có hoá đơn non-Draft tham chiếu bản ghi này ở vai trò from HOẶC to); `invoiceId` có định nghĩa chính xác là hoá đơn nơi bản ghi này là chỉ số **ĐÓNG kỳ (to)** — liên kết "MỞ kỳ (from)" cho hoá đơn kế tiếp lưu ở `tb_invoice`, không lưu ở bảng chỉ số. Thêm rule mới **BR-METER-13**: chỉ số đã khoá muốn sửa thì thêm dòng điều chỉnh vào `otherFees` của hoá đơn kế tiếp, không sửa/ghi đè bản gốc.
- **Gộp 3 màn ghi/xem/sửa chỉ số thành 1 màn duy nhất.** H-06 (Reading Entry), H-07 (Reading History), H-08 (Reading Correction) gộp thành **H-06 — Record Monthly Reading (PERIODIC)**: liệt kê theo phòng để nhập chỉ số mới, tap 1 phòng ra detail view xem lịch sử, sửa ngay tại đó khi `isLocked=false` — không chuyển màn riêng để sửa. `MOVE_IN`/`MOVE_OUT` **không** gộp vào đây, vẫn là bước bắt buộc riêng trong flow Hợp đồng như cũ. Tổng màn hình Home giảm 8→6, toàn app giảm 34→32 — xem [SCREEN-SPEC.md](SCREEN-SPEC.md) mục 1 và [USER-FLOWS.md](USER-FLOWS.md) Flow #1.
- **Làm rõ quan hệ mặc định `recurringFees` giữa `tb_house` và `tb_room`:** `tb_house.recurringFees` là giá trị mặc định optional, **tự động điền vào `tb_room.recurringFees` lúc tạo phòng mới** trong nhà đó; `tb_room.recurringFees` sau khi có giá trị mặc định thì **sửa độc lập theo từng phòng**, không tự đồng bộ ngược lại nếu nhà đổi giá trị mặc định sau này.

Đã cập nhật `DATABASE.md`, `BUSINESS-RULES.md` (mục 6 + BR-METER-13), `SCREEN-SPEC.md` (mục 1 + H-06), `USER-FLOWS.md` (Flow #1), `REQUIREMENTS.md` (FR-READ-05/06) trong cùng đợt này.

## 2026-09-08 (đợt 3, cùng ngày) — Build lại Figma wireframe theo Version 3, tổ chức lại Home tab đúng 6 màn

Sau khi docs đã đồng bộ theo 2 đợt chỉnh sửa FigJam ở trên, phát hiện file Figma wireframe MVP (`AElzfTBuL8YyA8OJ85f7aX`, page "MVP Wireframes (EN) — Version 3") thực ra **đã được build sẵn trước đó** (34 màn, design system riêng, prototype 7 flow/224 interaction) — chứ không phải vẫn là bản 22 màn/Version 2 như docs ghi. Yêu cầu: so sánh toàn bộ Figma với các file Version 3 (`SCREEN-SPEC.md` và liên quan) và sửa/thêm cho khớp. Các điểm chính đã xử lý trực tiếp trong Figma:

- **Tổ chức lại Home tab từ 8 màn xuống đúng 6 màn H-01→H-06** theo `SCREEN-SPEC.md` mục 1 (khớp việc gộp 3 màn ghi/xem/sửa chỉ số thành H-06 ở đợt 2): đổi tên/đánh số lại các frame, nối lại toàn bộ prototype reaction (back/save/cancel/tap-vào-phòng) theo cấu trúc mới, xoá màn "House Detail (Readings)" trùng lặp (không còn vai trò riêng sau khi gộp), H-06 tách thành 2 state Entry (nhập nhanh theo danh sách phòng) và Detail/Edit (xem lịch sử + sửa khi `isLocked=false`) nối vào nhau đúng như mô tả trong docs.
- **Sửa 1 lỗi vi phạm BR-READ-01 còn sót lại trong UI:** các list card ở màn Room List (H-03) vẫn hiển thị mã đồng hồ kiểu "EM-01 · WM-01" — sai vì Version 3 không có thực thể đồng hồ, chỉ số gắn thẳng vào phòng. Đã ẩn phần hiển thị này (dùng property `show meta` có sẵn trên component, không xoá cấu trúc).
- **Thêm UI còn thiếu cho `recurringFees`:** field "Default recurring fees" ở màn House Create/Edit (H-02) — trước đó chưa có trên Figma dù đã có trong DATABASE.md/BUSINESS-RULES.md từ đợt 2; kèm helper text giải thích quan hệ mặc định house→room (không tự đồng bộ ngược). Màn Room Create/Edit (H-05) đã có sẵn phần editor fee-pair, chỉ bổ sung helper text làm rõ nguồn gốc pre-fill.
- **Rà soát toàn trang các trích dẫn `BR-xxx-nn`** (không chỉ ở note, mà mọi text trên trang) đối chiếu với `BUSINESS-RULES.md` hiện hành — phát hiện và sửa 8 chỗ lệch số hiệu do Figma dùng theo 1 phiên bản đánh số rule cũ hơn (VD `BR-PRICE-01`→`BR-BILL-02/03`, `BR-METER-10`→`BR-CTR-10`, `BR-BILL-09`→`BR-BILL-12`...). Trong lúc rà soát, phát hiện thêm 1 chỗ sai nội dung thực chất (không chỉ sai số hiệu) ở màn Profile (P-05): copy cũ viết "Quản lý không bao giờ tự đăng ký tài khoản" — mâu thuẫn với mô hình vai trò Version 3 (1 luồng đăng ký SĐT+OTP duy nhất cho mọi người, xem đợt 2026-09-07/08 ở trên) — đã sửa lại copy cho đúng.
- Cập nhật lại các note thiết kế (design-rationale) nổi trên trang cho khớp cấu trúc 6 màn mới (bỏ nhắc "H-08"/"V4", nêu đúng cách H-06 xử lý gộp), và bổ sung 1 trích dẫn rule còn thiếu ở note "B-03 · Batch Billing" (`BR-BILL-11`).

**Không cần sửa migration/Edge Function nào thêm** — đây thuần là đồng bộ UI/UX với business rules đã chốt, không phát sinh thay đổi schema hay logic mới. Đã cập nhật `CLAUDE.md`, `DESIGN.md`, `CURRENT_STATUS.md` để không còn ghi Figma "vẫn còn 22 màn/Version 2".

## 2026-09-09 — Xử lý 6 điểm phát hiện từ gap analysis Version 3 (Đợt 2)

Nguồn: `Claude outputs/PHASE1-GAP-ANALYSIS-VERIFICATION.md` (Claude Sonnet 5, đối chiếu trực tiếp với docs V3 để xác minh 7 phát hiện trong `PHASE1GAPANALYSISV2.md`) + trao đổi trực tiếp với Dream để chốt hướng sửa cho từng điểm (09/09/2026). Đã cập nhật `DATABASE.md`, `BUSINESS-RULES.md`, `REQUIREMENTS.md`, `PRODUCT-OVERVIEW.md`, `SCREEN-SPEC.md`, `USER-FLOWS.md`, `DESIGN-SYSTEMS.md` trong cùng đợt này.

1. **`tb_tenant` thêm `houseId` bắt buộc.** Trước đó Tenant Pool chưa gắn phòng không có cách nào biết thuộc nhà nào, vi phạm `BR-DATA-04` (cô lập dữ liệu giữa các chủ nhà). Đã cân nhắc phương án thay thế — dùng chung Tenant Pool theo **chủ sở hữu thật** thay vì theo từng nhà (khớp thực tế Mr. Han: 1 tài khoản đứng tên/quản lý nhiều nhà) — nhưng **chốt không làm** vì `tb_house` hiện chưa có định danh chủ sở hữu thật (chỉ có `ownerFullName` dạng text, xem điểm 6 dưới đây), và việc thêm định danh đó kéo theo thay đổi lớn hơn phạm vi cần thiết lúc này. Giữ nguyên theo `houseId`, đơn giản hơn, chấp nhận phải tạo lại hồ sơ Tenant riêng cho từng nhà dù cùng 1 chủ. Xem `BR-DATA-05`.
2. **Thêm `BR-METER-14`** xử lý sửa chỉ số MOVE_OUT sau khi hợp đồng đã thanh lý (`BR-METER-13` không áp dụng được cho trường hợp này vì MOVE_OUT không bao giờ đóng vai trò "from" của hoá đơn nào). Điều chỉnh qua `tb_contract.damageDeduction`/`settlementNote` (tái dùng field settlement sẵn có), không mở lại/ghi đè chỉ số gốc, không phát hành lại hoá đơn cũ.
3. **Phí dịch vụ & phí định kỳ không chia theo ngày ở khi đổi khách giữa tháng** (khác tiền nhà — vẫn chia theo ngày như cũ). Chốt: tính trọn 100% cho hợp đồng đang `Active` tại **thời điểm hệ thống tạo hoá đơn** của kỳ đó; phòng còn trống lúc đó thì không tính khoản này cho ai — chủ nhà tự chịu. Đơn giản hơn phương án chia theo ngày cho mọi khoản, đổi lại có thể có trường hợp 1 bên "được lợi"/"chịu thiệt" nếu đổi khách sát ngày tạo hoá đơn — chấp nhận đánh đổi này cho Phase 1. Cập nhật `BR-BILL-08`.
4. **Làm rõ phòng `FLAT` (khoán) vẫn ghi chỉ số đầy đủ** (định kỳ + nhận/trả phòng) như phòng tính theo chỉ số thật — **có chủ đích**, không phải thiếu sót: dữ liệu không dùng để tính tiền (vẫn dùng `electricityFlatAmount`/`waterFlatAmount`) nhưng làm căn cứ theo dõi mức tiêu thụ thực tế, phục vụ việc cân nhắc chuyển sang tính theo chỉ số sau này nếu cần. Chỉ `NOT_BILLED` được miễn ghi chỉ số. Cập nhật `BR-READ-05`.
5. **Bỏ hẳn tính năng đổi số điện thoại.** Thay vì xây cơ chế cascade cập nhật các field "FK logic theo SĐT" (`tb_user_house_access.phone`, `recordedByUserId`, `grantedByUserId`) khi đổi SĐT, chốt đơn giản hơn: **SĐT là khoá chính, không cho đổi sau khi tạo tài khoản** — loại bỏ hẳn nhu cầu cascade. Người dùng vẫn đổi mật khẩu và mọi thông tin cá nhân khác bình thường. Nếu mất quyền truy cập SĐT đã đăng ký (mất SIM), Phase 1 chưa có luồng khôi phục sang SĐT mới — coi là ngoài phạm vi, xử lý hỗ trợ thủ công. Thêm `BR-ROLE-09`, sửa `FR-MGR-01`, `P-02` (SCREEN-SPEC.md).
6. **Nhóm nhà theo `ownerFullName` (H-01) — giữ nguyên như mô tả**, chấp nhận rủi ro gõ sai giữa các lần nhập tên chủ sở hữu. Không sửa gì ở `DATABASE.md`/`SCREEN-SPEC.md` cho điểm này.
7. **Đổi hướng ngôn ngữ UI: hỗ trợ song ngữ Anh–Việt ngay từ Phase 1** (khác quyết định trước đó dời "đa ngôn ngữ" sang Phase 2). Người dùng chọn ở Profile → thêm màn mới **P-08 — Language Setting** (tổng màn hình 32 → 33). Bản thiết kế Figma vẫn dựng bằng tiếng Anh làm chuẩn — việc song ngữ xử lý ở tầng code (i18n, 2 bộ string EN/VI), không cần dựng lại Figma theo 2 ngôn ngữ. Cập nhật `NFR-02`, thêm `FR-MGR-05`, `DESIGN-SYSTEMS.md` mục 0, bỏ "đa ngôn ngữ" khỏi mục Ngoài phạm vi ở `PRODUCT-OVERVIEW.md`/`REQUIREMENTS.md`.

**Tác động cần dev/Figma lưu ý:** Migration DB sắp viết cần thêm cột `tb_tenant.houseId`. Figma MVP Wireframes (đã build 32 màn ở đợt trước) **còn thiếu đúng 1 màn P-08 — Language Setting**, cần bổ sung trước khi coi là nguồn thiết kế đầy đủ cho code UI Phase 1.

## 2026-09-09 (Đợt 3) — Điều chỉnh mục 7: chọn ngôn ngữ ngay tại P-01, thêm tiếng Hàn

Sửa lại quyết định #7 của entry "Đợt 2" cùng ngày (song ngữ Anh–Việt qua màn riêng P-08), theo yêu cầu của Dream:

1. **Bỏ màn riêng P-08 — Language Setting.** Thay vào đó, thêm 1 dòng **"Ngôn ngữ / Language"** ngay trong màn **P-01 — Profile (màn gốc tab)**, dạng inline picker (không điều hướng sang màn khác) — chọn xong áp dụng ngay tại chỗ. Tổng màn hình app trở lại **32** (không tăng lên 33 như đợt 2 đã chốt tạm).
2. **Mở rộng từ 2 lên 3 ngôn ngữ hỗ trợ ngay Phase 1: English / Tiếng Việt / 한국어 (Hàn).** Ngôn ngữ khác ngoài 3 ngôn ngữ này vẫn để Phase 2 như định hướng ban đầu trước "đợt 2". Mặc định theo ngôn ngữ máy lúc cài lần đầu, fallback English nếu máy dùng ngôn ngữ ngoài 3 lựa chọn trên.
3. Bản thiết kế Figma/FigJam vẫn dựng bằng tiếng Anh làm chuẩn — 3 ngôn ngữ xử lý ở tầng code (i18n, 3 bộ string EN/VI/KO), không cần dựng lại Figma theo nhiều ngôn ngữ.

Cập nhật `FR-MGR-05`, `NFR-02` ([REQUIREMENTS.md](REQUIREMENTS.md)); `SCREEN-SPEC.md` (xoá P-08, cập nhật P-01, Screen Inventory 33 → 32); `DESIGN-SYSTEMS.md` mục 0; `PRODUCT-OVERVIEW.md` mục 5.2 và mục 8 (KPI); `USER-FLOWS.md` Flow #4 (node ngôn ngữ đổi thành nhánh inline cùng màn thay vì điều hướng).

**Tác động cần dev/Figma lưu ý:** Không cần thêm màn Figma nào cho việc này nữa (bỏ yêu cầu build P-08 của đợt 2) — chỉ cần bổ sung 1 dòng "Ngôn ngữ / Language" vào màn P-01 hiện có, số màn Figma giữ nguyên 32.

## 2026-09-09 (Đợt 4) — Xử lý 3 phát hiện từ gap analysis Version 3 (Đợt 3)

Nguồn: `PHASE1GAPANALYSISV3.md` (Claude Sonnet 5, đối chiếu 15 tài liệu Version 3 sau đợt 2/3, xác nhận cả 7 điểm đợt 2 đã xử lý đúng) + trao đổi trực tiếp với Dream để chốt hướng cho 3 phát hiện mới (A, B, C). Phát hiện D (CHANGELOG.md chưa cập nhật) và E (ghi chú FigJam bị đồng bộ theo quyết định trung gian rồi lỗi thời) **chưa xử lý trong đợt này** — Dream đã tự xác nhận đồng bộ lại FigJam ở phiên trước, còn D vẫn để nguyên như các lần trước.

A. **(Phát hiện Cao) Mất SIM + quên mật khẩu cùng lúc → khoá tài khoản vĩnh viễn.** Chốt: đây là rủi ro do **sơ suất của người dùng**, Phase 1 **không xử lý** — không có quy trình hỗ trợ thủ công/runbook nào trong phạm vi Phase 1 (khác với đề xuất "nên có runbook nội bộ" của gap analysis — Dream chọn phương án đơn giản hơn: chấp nhận rủi ro). **Phase 2** sẽ bổ sung kênh khôi phục mật khẩu thứ 2: gửi OTP tới **email đã đăng ký**, khi đó `email` chuyển từ optional sang **bắt buộc**. Nhân tiện phát hiện `tb_user` trong `DATABASE.md` đang **thiếu hẳn cột `email`** dù `SCREEN-SPEC.md` P-02/`FR-MGR-01` đã mô tả field này từ trước — bổ sung luôn (optional ở Phase 1). Cập nhật `BR-ROLE-09`, `FR-AUTH-05`, `DATABASE.md` (tb_user).
B. **(Phát hiện Trung bình) Thiếu ràng buộc Tenant phải cùng nhà với hợp đồng.** Chốt theo đúng đề xuất của Dream: màn T-04 hỗ trợ **2 chiều chọn** — (a) chọn Nhà/phòng trước (mặc định) → Tenant Pool tự lọc theo đúng nhà đó, rỗng thì tạo nhanh Tenant mới; (b) chọn Tenant trước → danh sách Nhà/phòng tự lọc lại chỉ còn nhà của Tenant đã chọn. Thêm `BR-CTR-13`, `FR-CTR-11`; cập nhật `SCREEN-SPEC.md` T-04, `USER-FLOWS.md` Flow #2.
C. **(Phát hiện Thấp-Trung bình) Ngôn ngữ tin nhắn Zalo/SMS gửi Tenant chưa định nghĩa.** Chốt: **cố định tiếng Anh**, độc lập hoàn toàn với ngôn ngữ hiển thị (EN/VI/KO) của người tạo hoá đơn — Tenant không có tài khoản nên không tự chọn ngôn ngữ. Thêm `BR-NOTI-07`; cập nhật `FR-NOTI-02`, `DESIGN-SYSTEMS.md` mục 0 (ghi chú phân biệt ngôn ngữ UI tài khoản vs ngôn ngữ nội dung gửi Tenant). *(Quyết định này được sửa lại ở "Đợt 5" cùng ngày — xem bên dưới.)*

**Tác động cần dev lưu ý:** Migration DB cần thêm cột `tb_user.email` (optional). Chưa cần xây kênh OTP-qua-email ở Phase 1 — chỉ cần chỗ lưu trữ sẵn cho Phase 2. Validation 2 chiều Nhà/phòng ↔ Tenant ở T-04 (`BR-CTR-13`) cần cả ở client lẫn server (RLS/constraint tầng ứng dụng), vì đây là ràng buộc nghiệp vụ chứ không phải FK đơn thuần.

## 2026-09-09 (Đợt 5) — Sửa lại ngôn ngữ SMS/Zalo sang tiếng Việt; bổ sung thiếu sót đợt 4; cập nhật CHANGELOG.md

Dream tự sửa trực tiếp vào repo một phần của đợt 4 (đổi `BR-NOTI-07`/`FR-NOTI-02`/`DESIGN-SYSTEMS.md` mục 0 sang phương án song ngữ Anh+Việt, kèm vài lỗi gõ trùng chữ), sau đó yêu cầu Claude chốt lại theo hướng khác và xử lý thêm 2 việc còn sót. Cụ thể:

1. **Đổi ngôn ngữ nội dung SMS/Zalo gửi Tenant: tiếng Anh (đợt 4) → tiếng Việt.** Lý do Dream đưa ra: gửi song song cả tiếng Anh và tiếng Việt trong cùng 1 tin nhắn làm tăng độ dài tin nhắn, đội chi phí gửi tin (SMS tính phí theo đoạn ký tự — tin có dấu tiếng Việt dùng bảng mã UCS-2, giới hạn ký tự/đoạn thấp hơn nhiều so với tiếng Anh thuần). Chốt: **chỉ 1 ngôn ngữ — tiếng Việt**, không song ngữ. Khôi phục lại nguyên văn quyết định gốc của "Đợt 4" (mục C ở trên, vốn đã bị ghi đè thành song ngữ khi Dream tự sửa) để giữ đúng tính chất "không sửa entry cũ" của file này, rồi ghi quyết định mới (tiếng Việt) vào entry này. Cập nhật `BR-NOTI-07`, `FR-NOTI-02`, `DESIGN-SYSTEMS.md` mục 0.
2. **Bổ sung tham chiếu `BR-CTR-13` còn thiếu trong `DATABASE.md`.** Đợt 4 đã thêm rule `BR-CTR-13` vào `BUSINESS-RULES.md`/`FR-CTR-11` nhưng quên chú thích lại trong mô tả field `tenantId` của `tb_contract` ở `DATABASE.md` — nay bổ sung: `tenantId` phải cùng `houseId` với các phòng trong hợp đồng, tham chiếu `BR-CTR-13`.
3. **Cập nhật `CHANGELOG.md`** (file gốc ở `docs/`, khác với nhật ký hàng ngày `changelog/*.md`) — đây là phát hiện D còn tồn đọng từ `PHASE1GAPANALYSISV3.md` (chưa cập nhật từ 2026-09-04), nay bổ sung đầy đủ các mục "Changed" cho toàn bộ đợt 2/3/4/5 trong ngày 09/09/2026, coi như đóng phát hiện D.

**Tác động cần dev lưu ý:** Không có thay đổi schema DB mới ở đợt này (chỉ thêm chú thích cho field đã có). Nếu backend/Edge Function `send-notification` đã bắt đầu code theo hướng song ngữ (đợt 4 cũ) thì cần sửa lại chỉ dùng 1 template tiếng Việt.

## 2026-09-09 (Đợt 6) — Đối chiếu số màn T-0x (Tenant & Contract) với Figma thật, sửa SCREEN-SPEC.md theo Figma

Dream báo hiệu design đã "ready to build" (commit cuối `43555b0`). Trước khi bắt đầu viết lại migration/Edge Function theo schema Version 3, dungtv yêu cầu Claude đọc trực tiếp Figma (qua Figma MCP) đối chiếu với `SCREEN-SPEC.md` để tìm điểm bất hợp lý còn sót — đây chính là phát hiện phụ "nhãn số màn T-03→T-10 lệch so với Figma" đã ghi nhận nhưng chưa xử lý ở `CURRENT_STATUS.md` (đợt "Figma prototype", 09/09).

**Phát hiện qua `get_metadata`/`get_screenshot` trực tiếp trên file Figma (fileKey `AElzfTBuL8YyA8OJ85f7aX`, page "MVP Wireframes (EN) — Version 3"):**

- Toàn bộ số thứ tự T-01→T-10 trong `SCREEN-SPEC.md` (soạn trước khi Figma build xong) lệch với tên/thứ tự frame thật trên Figma — chỉ T-05 (Contract Detail) và T-08 (Version History) khớp sẵn, 8/10 màn còn lại lệch số.
- **Phát hiện thêm 1 màn Figma đã có nhưng `SCREEN-SPEC.md` bản cũ chưa mô tả:** "Tenant Detail (View)" — màn xem hồ sơ Tenant (đọc/không sửa), có nút Call/Zalo liên hệ nhanh và danh sách các hợp đồng của Tenant đó. Đã đọc nội dung qua screenshot, viết spec mới cho màn này (nay là T-03).
- **Phát hiện thực chất (không chỉ lệch số):** `SCREEN-SPEC.md` bản cũ mô tả "Renew Contract" và "Amend Contract" là **2 màn tách riêng** (T-06/T-07 theo số cũ). Nhưng Figma thật chỉ có **1 frame duy nhất** "Contract Renew / Amend" — đã đọc metadata + screenshot, xác nhận nội dung chỉ có các field kiểu Renew (ngày, tiền, đơn giá, khối so sánh "CHANGED VS...") — **không có UI đổi danh sách phòng** (thêm/bớt phòng) như mô tả "Amend" trong bản cũ.

**Quyết định (theo yêu cầu dungtv "làm theo Figma mới"):** Coi Figma là nguồn đúng (mới nhất, đã "ready to build"), sửa lại `SCREEN-SPEC.md` khớp hoàn toàn theo Figma thật, không chờ Dream xác nhận lại số màn. Cụ thể:

1. Viết lại bảng Screen Inventory mục 1.4 và toàn bộ đặc tả chi tiết mục 2.3 (T-01→T-10) theo đúng tên/nội dung Figma. Bảng mapping số cũ → số mới:

   | Cũ | Mới | Màn hình |
   |---|---|---|
   | T-01 | T-01 | Tenant Pool List (nay là tab "Tenants" của màn gộp) |
   | T-03 | T-02 | Contract List (nay là tab "Contracts" của màn gộp) |
   | — | T-03 | **Tenant Detail (View) — mới** |
   | T-02 | T-04 | Tenant Profile Create/Edit |
   | T-05 | T-05 | Contract Detail (không đổi) |
   | T-04 | T-06 | Create Contract |
   | T-06 + T-07 | T-07 | **Gộp Renew + Amend thành 1 màn** |
   | T-08 | T-08 | Version History (không đổi) |
   | T-10 | T-09 | End Contract (Settlement) |
   | T-09 | T-10 | Invoice Schedule Preview |

2. Cập nhật toàn bộ tham chiếu chéo T-0x bị ảnh hưởng ở các file khác: `REQUIREMENTS.md` (FR-CTR-11), `BUSINESS-RULES.md` (BR-CTR-13) — cả 2 đổi "T-04" → "T-06"; `DESIGN-SYSTEMS.md` mục note kỳ hoá đơn tương lai — đổi "T-09" → "T-10".
3. **Chưa xử lý, để ngỏ:** khoảng trống "Amend có đổi được danh sách phòng hay không" — vì Figma hiện không có UI cho việc này dù `BUSINESS-RULES.md`/`REQUIREMENTS.md` mô tả trước đó có nhắc tới. Đã ghi rõ trong `SCREEN-SPEC.md` T-07 là "cần Dream xác nhận trước khi code UI màn này" — khác với cách xử lý phần renumbering (làm luôn theo Figma), vì đây là khoảng trống về **tính năng** chứ không đơn thuần là lệch tài liệu.
4. Chưa xử lý 2 phát hiện phụ khác đã biết từ trước (không thuộc phạm vi yêu cầu lần này): B-01 vẫn dùng 4-chip lọc nhà (T-02 đã đổi dropdown, chưa đồng bộ); H-03 chưa chốt tab mặc định (House detail hay Rooms).

**Tác động cần dev lưu ý:** Chỉ ảnh hưởng tài liệu (`docs/*.md`), không phát sinh thay đổi schema DB hay Edge Function nào. Khi code UI tab Tenant & Contract, dùng đúng số T-0x mới trong `SCREEN-SPEC.md` (đã khớp Figma) — không dùng lại số cũ trong các phiên bản trước đó của tài liệu.

## 2026-09-09 (Đợt 7) — Chốt bỏ tính năng đổi danh sách phòng (Amendment) khỏi Phase 1

Nối tiếp khoảng trống để ngỏ ở Đợt 6 (màn T-07 Renew/Amend không có UI đổi phòng). Trao đổi trực tiếp với dungtv, không cần hỏi lại Dream — dungtv tự đánh giá và quyết định dựa trên phân tích của Claude về mức độ ảnh hưởng:

- **Quyết định: bỏ hẳn tính năng đổi danh sách phòng của 1 hợp đồng đang Active (thêm/bớt phòng qua Amendment) khỏi Phase 1, dời Phase 2.** Khớp đúng thực tế Figma (T-07 không có UI cho việc này).
- **Lý do kỹ thuật (Claude phân tích):** Nếu giữ tính năng này, `tb_contract_room` (bảng nối hợp đồng↔phòng) cần thêm cơ chế **versioning theo từng `contract_version`** để giữ đúng "danh sách phòng tại thời điểm phát hành mỗi hoá đơn cũ" — nhưng schema hiện tại trong `DATABASE.md` chưa thiết kế cơ chế này (`tb_contract_room` chỉ là bảng nối phẳng theo `contractId`, không theo version). Bỏ tính năng này giúp **giữ nguyên schema đơn giản đã có**, không cần thiết kế thêm.
- **Lý do nghiệp vụ (dungtv xác nhận):** Đổi phòng thuê về bản chất là chấm dứt quan hệ thuê cũ, bắt đầu quan hệ thuê mới — hợp lý hơn khi xử lý bằng **kết thúc hợp đồng cũ (T-09) + tạo hợp đồng mới (T-06)** thay vì sửa ngầm vào hợp đồng đang có, kể cả về mặt pháp lý/giấy tờ.
- Cập nhật: `BUSINESS-RULES.md` (BR-CTR-07 đánh dấu bỏ, BR-VER-03/BR-VER-06 sửa lại không còn nhắc đổi phòng), `REQUIREMENTS.md` (FR-CTR-05/07, mục 6 Ngoài phạm vi), `PRODUCT-OVERVIEW.md` (mục 5.2), `USER-FLOWS.md` (Flow #4, bỏ nhánh MOVE_OUT khi loại phòng), `SCREEN-SPEC.md` (T-07, đổi từ "chờ Dream xác nhận" thành quyết định dứt khoát).

**Tác động cần dev lưu ý:** Không có thay đổi schema DB nào phát sinh (ngược lại, tránh được 1 thay đổi đáng lẽ phải thêm). `tb_contract_version.contractAreaSqm` giờ chốt cứng vĩnh viễn từ lúc tạo hợp đồng (`changeReason=New`), không đổi được nữa qua Amendment.

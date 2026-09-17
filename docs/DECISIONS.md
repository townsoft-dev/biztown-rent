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

## 2026-09-09 (Đợt 8) — Viết lại migration DB từ đầu theo Version 3

dungtv yêu cầu xoá sạch schema Version 1 (đã áp lên Supabase dev tuần trước, chỉ là dữ liệu test, không có dữ liệu thật) và dựng lại từ đầu theo `DATABASE.md` Version 3 hiện hành, "cho sạch gọn" thay vì viết thêm migration vá lỗi từng phần.

- Tạo `supabase/migrations/20260909133320_v3_schema_rebuild.sql`: mở đầu bằng `DROP TABLE` cho toàn bộ 11 bảng Version 1 (`landlords`, `tenants`, `properties`, `rooms`, `contracts`, `meter_readings`, `invoices`, `payments`, `maintenance_requests`, `rental_inquiries`, `notifications`), sau đó tạo mới 12 bảng Version 3 đúng `DATABASE.md`, kèm RLS đầy đủ theo mô hình `tb_user_house_access` (vai trò theo từng nhà, khoá theo SĐT qua `auth.jwt() ->> 'phone'`), 2 trigger (tự cấp quyền `owner` khi tạo nhà; đồng bộ cờ `is_active` trên `tb_contract_room` để enforce "1 phòng chỉ 1 hợp đồng Active" bằng partial unique index, vì Postgres không cho partial index tham chiếu cột bảng khác).
- **Giữ nguyên** file migration Version 1 cũ (`20260903121605_initial_schema.sql`) làm lịch sử — không xoá, đúng nguyên tắc "không sửa lịch sử" của repo này; file mới tự xoá sạch nội dung file cũ khi áp lên.
- Áp thành công lên Supabase dev thật (`supabase db push`), verify qua Supabase Management API: đủ 12 bảng, RLS bật cả 12, 20 policy, 3 trigger, 6 function; xác nhận 11 bảng Version 1 đã biến mất hoàn toàn.
- **2 điểm tự quyết khi viết migration, lệch nhẹ so với văn bản `DATABASE.md`, cần Dream xác nhận/chính thức hoá lại sau:**
  1. **Bỏ cột `passwordHash` khỏi `tb_user`** — theo đúng quyết định kiến trúc đã chốt (`ARCHITECTURE.md`: "Manager là 1-1 với auth.users, dùng chung Supabase Auth"), Supabase Auth tự quản lý mật khẩu nội bộ, app không cần tự lưu hash. `DATABASE.md` mục "Các thực thể" vẫn liệt kê field này — nhiều khả năng là sót lại khi gộp `landlord_account`+`manager_account` thành `tb_user`, chưa dọn theo đúng quyết định 2026-09-04 (đã từng bỏ `passwordHash` khỏi `manager_account` ở Version 2).
  2. **Thêm bảng `tb_device_token`** (lưu FCM/APNs token cho push, khoá theo `tb_user.id`) — không có trong danh sách "Các thực thể" của `DATABASE.md`, nhưng `ARCHITECTURE.md` yêu cầu rõ ("client đăng ký device token, lưu vào Supabase"), và phần đầu `DATABASE.md` ghi "12 bảng" trong khi mục "Các thực thể" chỉ liệt kê đủ 11 — suy đoán hợp lý đây chính là bảng thứ 12 còn thiếu trong tài liệu.

**Tác động cần dev lưu ý:** Toàn bộ dữ liệu test cũ (nếu có) trên Supabase dev đã mất theo schema V1 — chấp nhận được vì chưa có dữ liệu thật. Trước khi viết Edge Function `generate-invoice`/`generate-payment-qr` mới, dev cần đọc kỹ cơ chế `isLocked` (derived, không phải cột — phải tự query kết hợp `invoice_id` trên bảng reading + tìm kiếm trong `tb_invoice.utility_lines` jsonb của các hoá đơn khác) vì migration không tạo view/cột hỗ trợ sẵn cho việc này.

## 2026-09-09 (Đợt 9) — Viết lại 3 Edge Function theo schema Version 3

Tiếp nối Đợt 8 (migration DB). Viết lại `generate-invoice`, thêm mới `generate-payment-qr`, cập nhật `send-notification` theo đúng công thức BUSINESS-RULES.md mục 1 (Billing) và mục 5 (Notification).

- **`generate-invoice`**: hỗ trợ `mode: "single"` (1 hợp đồng + 1 kỳ) và `mode: "batch"` (1 nhà + 1 kỳ, BR-BILL-11 — bỏ qua hoàn toàn hợp đồng thiếu chỉ số, không ước lượng). Đọc chỉ số qua `previousReadingId` (nguồn sự thật, không dùng field `previousReading` snapshot để tính — chỉ hiển thị), tính tiền điện/nước theo `BY_READING`/`FLAT`/`NOT_BILLED` (BR-BILL-02/03), tiền nhà theo `rentCycleMonths`/`rentCycleAnchorYm` (BR-BILL-07), phí dịch vụ + phí định kỳ tính trọn không chia ngày (BR-BILL-08), hạn thanh toán theo ngày cố định có xử lý tràn tháng (BR-BILL-09), tự sinh mã QR lúc tạo (BR-BILL-10). Sau khi tạo hoá đơn, cập nhật `invoice_id` lên các bản ghi chỉ số đã dùng (khoá `isLocked` qua BR-READ-04).
  - ⚠️ **TODO chưa xong**: prorate tiền nhà theo ngày khi `MOVE_IN`/`MOVE_OUT` rơi giữa kỳ (BR-BILL-08 vế đầu) — code hiện tạm tính trọn tháng; cần xác nhận cách làm tròn ngày cụ thể (tính cả ngày đầu/cuối hay không) trước khi hoàn thiện, không tự đoán để tránh sai số tiền thật.
- **`generate-payment-qr`** (mới): sinh mã VietQR/NAPAS-247 chuẩn EMVCo, tách thành module dùng chung `supabase/functions/_shared/vietqr.ts` (cả `generate-invoice` lẫn hàm này đều gọi). **Không cần chọn nhà cung cấp/tài khoản bên thứ 3** — đây là chuẩn mở, tự sinh được hoàn toàn (khác SMS/Zalo cần vendor). Verify thuật toán CRC16/CCITT-FALSE đúng test vector chuẩn quốc tế (`123456789` → `29B1`) bằng Python độc lập với code Deno. Chưa test bằng máy quét QR ngân hàng thật — cần làm trước khi tin tưởng dùng thật.
- **`send-notification`**: đổi nguồn người nhận Push từ bảng cũ sang `tb_user_house_access` (theo `house_id`, gộp cả owner/manager — đúng BR-NOTI-01/02/05 "người có quyền trên nhà đó" không phân biệt role) + `tb_device_token` (bảng mới thêm ở Đợt 8). Phần gửi SMS/Zalo/Push thật vẫn TODO (chờ provider).
- Cả 3 function deploy thử thành công lên Supabase dev (`supabase functions deploy`), không lỗi.

**Tác động cần dev lưu ý:** Chưa test end-to-end với dữ liệu thật (cần app Flutter hoặc script tạo house/room/contract/reading mẫu trước). Prorate tiền nhà là điểm cần hoàn thiện sớm nhất vì ảnh hưởng trực tiếp số tiền thu — đừng dùng thật cho ca có đổi khách giữa kỳ tới khi xong.

## 2026-09-09 (Đợt 10) — Bắt đầu code UI: cài Android Studio + code khung app/Auth, chạy thật trên emulator

dungtv xác nhận sẵn sàng bắt đầu code UI (design Figma "ready to build" + docs nghiệp vụ đầy đủ). Thứ tự đã chọn: **khung app + Auth trước** (mọi tính năng khác đều cần đăng nhập được trước), và **cài Android Studio ngay để xem app chạy thật** trong lúc code thay vì chỉ dựa vào `flutter analyze`.

- **Cài môi trường Android**: tải trực tiếp Android Studio (.dmg từ Google, không cần tài khoản) + Android SDK qua `sdkmanager` (command-line, dùng JDK bundled sẵn trong Android Studio thay vì cài Java riêng) — không mở GUI Android Studio, tất cả qua CLI. Cài platform 35 + 36, build-tools, emulator, system-image; tạo AVD `rentmanager_pixel` (Pixel 6, API 35) qua `avdmanager`. `flutter doctor` Android toolchain lên xanh. **Xcode không tự cài được** — bắt buộc qua Mac App Store với Apple ID của dungtv, để dungtv tự làm khi cần.
- **Code khung app**: thêm `go_router`, `google_fonts`, `pin_code_fields` vào `pubspec.yaml`. Viết `core/theme.dart` (design tokens đầy đủ từ `DESIGN-SYSTEMS.md`: màu, bo góc, spacing, badge trạng thái), `core/router.dart` (go_router, tự redirect theo session qua `GoRouterRefreshStream`), `data/auth_repository.dart` (bọc Supabase Auth: `signInWithPassword`, `signInWithOtp`, `verifyOTP`, `updateUser` để đặt mật khẩu).
- **Code 3 màn Auth theo `SCREEN-SPEC.md` mục 2.1**: S-00 Splash (tự kiểm tra session), S-01 Đăng nhập (SĐT+mật khẩu), S-02 Đăng ký (3 bước: nhập SĐT → OTP 6 số có đếm ngược → tạo mật khẩu, dùng `pin_code_fields`). S-03 (Trung tâm thông báo) và H-01 (Home thật) chưa code — router tạm trỏ `/home` sang 1 màn placeholder.
- **Build & chạy thật lên emulator** (`flutter run -d emulator-...`, kèm `--dart-define` cho Supabase URL/key) — build lần đầu ~200s (Gradle tự tải thêm NDK + build-tools 36 + CMake). App chạy được, Supabase init thành công (log xác nhận). Chụp màn hình qua `adb screencap` để tự kiểm tra bằng mắt (không chỉ dựa vào build thành công) — **phát hiện 1 lỗi UI ngay lần đầu**: dòng "Welcome to BizTown" gần như vô hình (chữ trắng trên nền sáng) do `titleMedium`/`bodyMedium`/`labelLarge` trong `theme.dart` thiếu `color` tường minh, bị `.copyWith` ghi đè mất màu đã set qua `.apply()` trước đó. Sửa bằng cách set `color: AppColors.textPrimary` tường minh cho từng style. Build lại, chụp màn hình xác nhận đúng.
- Test thêm 1 bước điều hướng thật (bấm link "Chưa có tài khoản? Đăng ký" qua `adb shell input tap`) — xác nhận màn Signup (bước nhập SĐT) render đúng.

**Bài học quy trình (áp dụng cho các màn tiếp theo):** viết code UI xong không tính là hoàn thành — phải build thật + chụp màn hình tự xem lại bằng mắt trước khi báo xong, vì lỗi màu/hiển thị kiểu này `flutter analyze` không bắt được (chỉ bắt lỗi cú pháp/type, không bắt lỗi styling khiến chữ vô hình).

**Chưa làm/chưa test**: luồng gửi + xác thực OTP thật (cần chọn nhà cung cấp SMS trước, `send-otp-sms` vẫn TODO), rate-limit đăng nhập sai 5 lần, "Quên mật khẩu" (chưa nối), S-03 và H-01 thật.

## 2026-09-09 (Đợt 11) — Sửa S-00/S-01/S-02 khớp đúng Figma thật, sau phản hồi "chưa giống thiết kế"

Bản Auth code ở Đợt 10 build từ mô tả text trong `SCREEN-SPEC.md`/`DESIGN-SYSTEMS.md` (không có ảnh Figma thật do bị giới hạn quota MCP đúng lúc cần). dungtv xem app chạy thật, phản hồi **rõ ràng chưa giống Figma**, gửi trực tiếp 2 ảnh chụp màn hình (Figma S-00/S-01/S-02/S-03 ghép 4 khung, và ảnh app chạy thật) để so sánh — không cần chờ Figma MCP nữa.

**Nguyên nhân gốc (tự nhận, không đổ lỗi công cụ):** mô tả text trong docs chỉ liệt kê **có gì trên màn** (input SĐT, nút Đăng nhập...), không mô tả được **cách trình bày** (canh trái hay canh giữa, label cố định hay floating, nguyên văn copy chính xác) — nên phần đó bị tự suy diễn/tự viết lại, sai khá nhiều so với bản thật.

**Đối chiếu cụ thể tìm được qua ảnh:**
- Toàn bộ heading/label/form ở Figma **canh trái**, bản code canh giữa.
- Copy sai hoàn toàn: Figma "Log in"/"Welcome! Please sign in to continue."; bản code tự viết "Welcome to BizTown"/"Manage your rentals...".
- Figma dùng **label tĩnh phía trên** mỗi field; bản code dùng floating label kiểu Material mặc định.
- "Forgot password?" Figma canh **phải**; bản code canh giữa.
- **Cấu trúc màn Đăng ký khác hẳn:** Figma là **1 màn liên tục** (AppBar "Create account"/"Main Manager" + thanh tiến trình 4 chấm + phần "Verify your phone" và "STEP 3 — SET PASSWORD" cùng hiện trên 1 trang); bản code tách thành 3 bước chuyển đổi nội dung hoàn toàn riêng biệt (dù cùng 1 widget, không phải 3 route khác nhau, nhưng UI thay thế hẳn chứ không cộng dồn).
- Splash dùng nhầm tagline cũ ("Simple rental management" — sót lại từ thời chưa có bản dịch/copy chính thức) thay vì đúng "Houses and Rooms Renting Management Tool".
- Logo dùng icon Material (`Icons.home_work_outlined`) generic thay vì asset thật trong `design/Logo/`.

**Đã sửa toàn bộ 3 màn theo đúng ảnh:** dùng logo SVG thật (`biztown-rent-manager-lockup.svg` nền sáng, `-lockup-on-navy.svg` cho Splash), Login/Signup đổi sang canh trái + `_FieldLabel` widget tĩnh phía trên field, copy đúng nguyên văn tiếng Anh, nút full-width (`SizedBox(width: double.infinity)`), Signup viết lại thành 1 màn liên tục với `_ProgressDots` (4 chấm, màu xanh/cam/xám theo bước) + 2 section (Verify phone, Set password) cộng dồn hiển thị khi `_otpVerified=true` thay vì switch-case thay thế hoàn toàn.

**Kỹ thuật kiểm chứng:** vì không gọi được OTP thật (chưa có SMS provider), tạm sửa 2 dòng khởi tạo state (`_step`/`_otpVerified`) để ép hiển thị thẳng section "STEP 3" mà không cần OTP thật, chụp màn hình so khớp, rồi **revert lại ngay** 2 dòng debug đó trước khi commit — không để lại code test tạm trong commit.

**Tác động cần dev lưu ý:** ⚠️ Cơ chế chính xác OTP+Password "cộng dồn trên 1 màn" mới chỉ là suy đoán hợp lý nhất từ 1 ảnh tĩnh (không thấy được animation/tương tác thật của prototype Figma) — cần verify lại khi Figma MCP hết giới hạn quota hoặc hỏi Dream trực tiếp, trước khi coi đây là chuẩn cuối cùng cho các màn nhiều-bước khác (nếu có) trong app.

## 2026-09-09 (Đợt 12) — Figma MCP có Editor access thật (tài khoản CEO): rebuild S-00→S-03 bằng dữ liệu chính xác, xác nhận nghi ngờ ở Đợt 11 là đúng

dungtv tự đăng nhập Figma bằng tài khoản CEO (`ceo@townsoftvina.com`, seat Full trên gói Pro, đúng team sở hữu file BizTown) và re-auth lại kết nối Figma MCP phía Claude (qua Settings → Connectors, không phải việc AI tự làm được). `whoami` xác nhận đổi danh tính thành công; `get_metadata`/`get_design_context` gọi được không giới hạn.

**2 phát hiện quan trọng, sửa lại quyết định đã ghi ở Đợt 11:**

1. **Cấu trúc Sign Up thật sự KHÁC** với suy đoán ở Đợt 11: Figma có **3 frame riêng** — "S-02 Sign Up Step 1" (SĐT + OTP gộp chung 1 trang, không tách rời như suy đoán ban đầu trước đó nữa, mà đúng là 1 trang cho cả 2 việc), "Step 2" (SET PASSWORD, **trang điều hướng riêng**, không phải section cộng dồn trong cùng 1 trang), và "Step 3" — thực chất là **bottom sheet thành công** hiện đè lên Step 2 (đang mờ 30%) sau khi tạo tài khoản xong, không phải 1 bước nhập liệu. Stepper chỉ có **3 chấm** (không phải 4 như bản đoán trước), vẽ bằng toạ độ SVG gốc (dot r=4 tại x=4/52/100, line dài 28px). Rebuild lại `signup_screen.dart` thành 2 trang điều hướng nội bộ (`_SignupPage` enum) + `showModalBottomSheet` cho thành công.
2. **File SVG logo trong `design/Logo/` bị sai tỉ lệ** (viewBox 354×164, dư khoảng trắng đáy) so với artwork thật xuất từ Figma (viewBox chuẩn 279.589×93.986 cho bản OnNavy, 199.706×67.133 cho bản Light) — đây chính là nguyên nhân dungtv hỏi lại "khoảng cách dưới RENT MANAGER có đúng không". Đã tải lại đúng file SVG qua `download_assets`/export URL của Figma, ghi đè cả `design/Logo/` (nguồn thiết kế) và `src/assets/logo/` (asset app dùng).

**Bài học quy trình quan trọng nhất:** việc chủ động ghi chú nghi ngờ ngay trong code/DECISIONS.md khi phải suy đoán từ ảnh tĩnh (như đã làm ở Đợt 11 với dòng "⚠️ Chưa chắc 100%...") có giá trị thật — khi có dữ liệu chính xác, biết ngay chỗ nào cần rà soát lại thay vì phải đoán lại từ đầu toàn bộ màn hình.

**Đã verify bằng build thật + chụp màn hình trên emulator** cho cả 4 màn (S-00, S-01, S-02×2 trang+sheet, S-03 — màn hoàn toàn mới, build lần đầu). Phần OTP/Set Password/bottom sheet phải tạm ép state debug để chụp (chưa có SMS provider thật) — đã revert sạch trước khi commit (`grep DEBUG TEMP` rỗng).

## 2026-09-09 (Đợt 13) — go_router: KHÔNG dùng redirect để tự chuyển sang /home sau khi đăng nhập; điều hướng tường minh

**Quyết định**: bỏ hẳn rule `if (loggedIn && atLogin) return '/home';` trong `redirect` callback của `appRouter` (`core/router.dart`). `redirect` từ nay **chỉ** dùng để chặn truy cập khi CHƯA đăng nhập (guard), không dùng để tự động đưa người dùng đi đâu sau khi đăng nhập/đăng ký thành công — việc đó do chính màn hình gọi `context.go('/home')` tường minh ngay sau khi thao tác auth thành công.

**Lý do (phát hiện qua test thật, không phải lý thuyết)**: `signup_screen.dart` dùng `context.push('/signup')` (đổi từ `go()` ở Đợt 09/09 16:00 để sửa nút Back — xem phần trên). Trong go_router 14.x, `push()` đẩy thêm 1 trang lên Navigator stack nhưng **không cập nhật** `GoRouterState.matchedLocation` — router vẫn coi vị trí "chính thức" là `/login` dù đang hiển thị SignupScreen. Supabase tạo session ngay sau `verifyOTP` (**trước khi** người dùng đặt mật khẩu ở Step 2) — khi đó rule `loggedIn && atLogin → /home` bị đánh giá lại (do `refreshListenable` lắng nghe auth state), thấy "loggedIn=true, matchedLocation=/login" (dù thực tế đang ở Step 1 của Sign Up) và bắn thẳng người dùng sang `/home`, bỏ qua hoàn toàn bước Set Password. Lỗi này **luôn xảy ra với mọi user thật** (không phải edge case), chỉ được phát hiện khi test toàn bộ luồng Sign Up bằng session thật (trước đó mọi test đều dừng ở lỗi kết nối/thiếu dart-define nên chưa bao giờ chạm tới đoạn này).

**Bài học quy trình**: `push()` và `go()` trong go_router không tương đương về mặt "vị trí" mà `redirect` nhìn thấy — trộn lẫn 2 kiểu điều hướng (1 số nơi dùng `push()` để giữ back-stack, số khác dựa vào `redirect` để tự chuyển trang theo auth state) tạo ra lỗi khó thấy bằng mắt (UI vẫn hiện đúng SignupScreen, chỉ lộ ra khi tạo session thật giữa chừng). Quy tắc từ nay: **không dựa vào `redirect` cho bất kỳ điều hướng nào xảy ra SAU một hành động của người dùng trong 1 flow nhiều bước** (kể cả khi flow đó dùng `go()` chứ không phải `push()`) — chỉ dùng `redirect` cho việc chặn/guard truy cập lúc vào màn, còn "đi tiếp tới đâu sau khi xong việc" luôn gọi tường minh từ chính màn đó.

**Verify**: build thật, test toàn bộ Sign Up (SĐT → OTP → Set Password → Create account → bottom sheet → Get started → Home) bằng Test OTP number + backend Supabase thật (không phải giả lập) — chạy đúng, dừng lại ở Step 2 chờ đặt mật khẩu, không còn bị bắn sớm sang Home.

## 2026-09-09 (Đợt 14) — Chọn xong nhà cung cấp SMS: eSMS.vn (thay SpeedSMS)

**Quyết định**: dùng **eSMS.vn** cho `send-otp-sms` (Send SMS Hook), không dùng SpeedSMS nữa.

**Lý do**: dungtv đăng ký thử cả 2 nhà cung cấp trong cùng phiên. SpeedSMS: tài khoản demo (2000đ) không gửi được SMS nào — API luôn trả lỗi "sender not found" cho mọi `type` thử (2, 4/Verify), vì gửi SMS (kể cả test) đòi hỏi **Brandname đã đăng ký và duyệt** (cần giấy tờ: công văn, ĐKKD, CMND người đại diện, duyệt thủ công qua email, không có gì dùng ngay được). eSMS.vn: có sẵn **Brandname demo "Baotrixemay"** dùng test miễn phí ngay bằng tài khoản khuyến mãi có sẵn (5.000đ), chỉ cần đúng 1 template nội dung cố định (`"{code} la ma xac minh dang ky Baotrixemay cua ban"`) — verify thành công ngay trong phiên bằng curl thật (`CodeResult: "100"`) và bằng SMS thật nhận được trên điện thoại dungtv.

**Đã làm**:
- Viết lại `send-otp-sms/index.ts`: gọi `POST https://rest.esms.vn/MainService.svc/json/SendMultipleMessage_V4_post_json/` với `ApiKey`/`SecretKey`/`Phone`/`Content`/`Brandname`/`SmsType`. Thêm `toLocalVnPhone()` vì Supabase gửi payload SĐT dạng E.164 (`+84...`) nhưng eSMS cần dạng nội địa (`0...`).
- Lưu `ESMS_API_KEY`/`ESMS_SECRET_KEY` làm Supabase Secret, xoá secret `SPEEDSMS_ACCESS_TOKEN` không dùng nữa.
- Cập nhật `docs/REQUIREMENTS.md` INT-02, `docs/ARCHITECTURE.md`, `docs/API.md`, comment trong `send-notification/index.ts` — không còn nhắc SpeedSMS như 1 lựa chọn đang cân nhắc.

**⚠️ Chưa xong hẳn — cảnh báo quan trọng cho production**: Brandname "Baotrixemay" là **demo dùng chung của eSMS**, nội dung tin nhắn bắt buộc đúng template của họ, **không nhắc gì tới BizTown cả** — chỉ hợp lệ để test kỹ thuật, tuyệt đối không dùng cho user thật. Trước khi launch, phải đăng ký Brandname CSKH thật (tên "BizTown" hoặc tương đương) qua eSMS, đợi duyệt, rồi đổi `ESMS_BRANDNAME`/nội dung `Content` trong `send-otp-sms/index.ts` — đã ghi rõ cảnh báo này ngay đầu file code.

## 2026-09-10 (Đợt 15) — Bottom Navigation dùng `StatefulShellRoute.indexedStack`; component dùng chung cho toàn bộ H-0x trở đi

**Quyết định**: dựng khung 4-tab (Home/Tenant & Contract/Bills/Profile) bằng `StatefulShellRoute.indexedStack` của go_router (`AppShell` bọc `AppBottomNav`, khai báo branch trong `core/router.dart`), thay cho route `/home` phẳng trỏ 1 `HomePlaceholderScreen` như trước. Mỗi tab giữ nguyên Navigator/stack điều hướng riêng khi chuyển qua lại — đúng hành vi chuẩn của app có bottom nav (quay lại tab trước phải nhớ đúng vị trí đang xem, không reset về màn gốc).

**Lý do làm component dùng chung trước khi code H-01**: theo yêu cầu tránh trùng lặp code, trước khi viết `home_screen.dart` đã tạo 5 widget dùng chung trong `lib/shared/`: `StatusPill`, `ListCard` (thumb square/round), `StatCard`, `SectionLabel`, `AppFab` — đều map 1-1 với component đã định nghĩa sẵn trên Figma Design System (168:48, 168:49, 167:55, 168:61...) và đều có usage description trên chính component đó xác nhận sẽ dùng lại ở nhiều màn khác (`ListCard` dùng cho H-01/H-03/T-02/H-06/S-03...). Refactor luôn `NotificationCenterScreen` (S-03, code trước đó) để dùng `ListCard`/`StatusPill` thay vì widget riêng — tránh 2 bản code gần giống nhau ngay từ bây giờ thay vì để tích luỹ rồi dọn sau. `TopBar` cũng mở rộng thêm constructor `TopBar.home(...)` + `TopBarBellButton` thay vì tạo 1 widget Topbar riêng cho H-01 (component gốc trên Figma ghi rõ 3 variant Home/Title/Title+Action dùng chung 1 component).

**2 lỗi phát hiện qua test thật trên thiết bị (`R7AY3074GAD`), không phải suy đoán**:
1. `flutter build apk --release` không truyền `--dart-define=SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY` (dự án đọc 2 giá trị này từ `supabase/.env` qua `--dart-define`, xem `docs/SETUP.md` mục 5) khiến `Supabase.initialize()` chạy với URL/key rỗng — mọi lời gọi Auth thất bại và bị `catch (e)` chung trong `login_screen.dart`/`signup_screen.dart` hiển thị nhầm thành "Sai số điện thoại hoặc mật khẩu"/"Không gửi được OTP", trông y hệt lỗi sai mật khẩu thật dù tài khoản/OTP hoàn toàn đúng. Bài học: khi build release thủ công (ngoài `flutter run` có cấu hình sẵn), luôn nhớ truyền đủ 2 dart-define, lấy giá trị từ `supabase/.env` (URL + publishable key — 2 giá trị này công khai/an toàn nhúng client, khác secret key/access token).
2. `AppBottomNav` tự vẽ bằng `Container` (không dùng `BottomNavigationBar` có sẵn của Flutter, vốn tự bọc `SafeArea`) nên không tự trừ hao vùng thanh điều hướng hệ thống — trên máy Android dùng chế độ 3 nút điều hướng (không phải cử chỉ), thanh tab bị đè lên thanh 3 nút hệ thống, chỉ thấy rõ khi chụp ảnh trên máy thật. Sửa bằng cách bọc nội dung trong `SafeArea(top: false)` — giữ nguyên padding 14px thiết kế gốc (dành cho home indicator iOS) cộng thêm với inset hệ thống thật của Android.

**Verify**: build release đúng dart-define, cài lên thiết bị thật, đăng nhập bằng tài khoản test (`0356123970`) → H-01 hiện đúng pixel so với ảnh chụp Figma (màu thumb theo từng nhà, badge đúng tone, số liệu, layout); chuyển tab Tenant/Bills/Profile đúng trạng thái được chọn; bấm chuông ở H-01 → mở đúng S-03 Notification Center; nút "Đăng xuất" tạm ở Profile hoạt động. `flutter analyze` sạch, `dart format` đã chạy.

## 2026-09-10 (Đợt 16) — Nối CRUD thật House/Room + Storage ảnh; phát hiện & vá 2 lỗi RLS nghiêm trọng

Theo yêu cầu "tiến hành làm crud và store ảnh đi", nối `tb_house`/`tb_room` (H-01→H-05) từ dữ liệu mẫu tĩnh sang Supabase CRUD thật, và dựng Supabase Storage cho ảnh Nhà/Phòng.

**Hạ tầng mới**:
- Bucket Storage riêng tư `property-photos` (giới hạn 8MB, chỉ nhận `image/jpeg|png|webp|heic`), RLS trên `storage.objects` dùng `(storage.foldername(name))[1]::uuid` (segment đầu = houseId) tái dùng `has_house_access()` — 1 bộ policy dùng chung cho cả ảnh Nhà (`<houseId>/houses/<file>`) và ảnh Phòng (`<houseId>/rooms/<roomId>/<file>`).
- `HouseRepository`/`RoomRepository` (CRUD + upload/xoá ảnh + `signedPhotoUrl` — bucket riêng tư nên không dùng được `getPublicUrl`), `PhotoPickerController`/`RecurringFeesController` (state cho form ảnh + phí định kỳ, dùng chung giữa House form và Room form), package `image_picker`+`uuid`.
- 4 migration vá lỗ hổng Figma-vs-schema (field có trên thiết kế nhưng chưa có cột): `tb_house.owner_phone`, `tb_house.owner_email`, `tb_house.default_electricity_price`/`default_water_price`, `tb_room.note`.

**2 lỗi nghiêm trọng phát hiện khi test CRUD thật (không phải lý thuyết), cả 2 đều KHÔNG lộ ra khi test trên dữ liệu mẫu vì bảng liên quan lúc đó luôn rỗng:**

1. **RLS đệ quy vô hạn**: `has_house_access()` (SQL function thường, không `security definer`) đọc `tb_user_house_access` — nhưng policy SELECT của chính `tb_user_house_access` cũng gọi lại `has_house_access()`, cứ thế lặp vô hạn → Postgres báo `54001 stack depth limit exceeded` ngay khi tạo Nhà đầu tiên (lúc đó bảng `tb_user_house_access` mới thật sự có dữ liệu để policy phải evaluate). Vá bằng migration `20260910140000_fix_has_house_access_recursion.sql`: đổi hàm thành `security definer set search_path = public` để lời gọi bên trong hàm bỏ qua RLS của chính bảng nó đang bảo vệ — pattern chuẩn cho mọi hàm kiểm tra quyền cần tự đọc bảng mà nó đang gác.
2. **`INSERT ... RETURNING` bị RLS chặn dù INSERT tự nó hợp lệ**: sau khi vá lỗi (1), tạo Nhà vẫn báo `42501` — hoá ra Postgres áp lại policy SELECT ngay lúc trả về hàng vừa insert (`RETURNING`/`.insert().select().single()` của supabase-dart), nhưng dòng quyền `owner` do trigger `AFTER INSERT` cấp chưa "nhìn thấy" đúng lúc kiểm tra đó — dù insert không kèm RETURNING thì trigger vẫn chạy đúng (xác nhận qua Management API query trực tiếp `tb_user_house_access`). Vá bằng cách sinh `id` sẵn ở client (`uuid`), insert KHÔNG yêu cầu trả hàng, rồi gọi `getById` ở 1 request riêng sau đó — xem doc-comment chi tiết tại `HouseRepository.create()`.

**1 lỗi hạ tầng Android phát hiện song song (không liên quan RLS)**: build release cài lên máy thật báo `SocketException: Failed host lookup` ở mọi request — `adb shell dumpsys package ... | grep -A5 "requested permissions"` cho thấy bản release **không có quyền `INTERNET`**. Nguyên nhân: Flutter template mặc định chỉ đặt `<uses-permission android:name="android.permission.INTERNET"/>` ở `android/app/src/debug/AndroidManifest.xml` và `.../profile/AndroidManifest.xml`, KHÔNG có ở `.../main/AndroidManifest.xml` (áp dụng cho mọi build variant kể cả release) — thiếu suốt từ đầu project, chỉ lộ ra khi build release thật thay vì `flutter run` (debug). Đã thêm dòng permission (+ `CAMERA` cho `image_picker`) thẳng vào `src/main/AndroidManifest.xml`, kèm comment giải thích ngay tại chỗ để không ai vô tình xoá nhầm vì tưởng trùng lặp với debug/profile.

**Verify trên thiết bị thật (`R7AY3074GAD`)**: build lại release APK sau khi vá đủ 3 lỗi trên, cài lại, thực hiện toàn bộ luồng qua UI thật (không phải curl): tạo Nhà "Nha Tro Test" kèm ảnh chọn từ thư viện ảnh máy → hiện đúng trong H-01 (số liệu tổng hợp thật) và H-03; tạo Phòng "P.101" kèm chọn tiện ích → hiện đúng trong H-03/H-04; xoá Phòng (qua menu ⋮ → Delete → xác nhận dialog đúng Figma) → quay về H-03, danh sách phòng rỗng đúng; xoá Nhà tương tự → quay về H-01, về đúng trạng thái rỗng ban đầu ("You don't have any house yet."). `flutter analyze` sạch, `dart format` không có gì cần sửa.

**Chưa làm/còn nợ**: chưa test được luồng xoá Nhà/Phòng bị DB chặn bởi FK (còn phòng có lịch sử hợp đồng) vì chưa có dữ liệu hợp đồng thật để dựng tình huống đó — code đã bắt `PostgrestException` code `23503` và hiện thông báo phù hợp, nhưng chưa verify bằng dữ liệu thật. H-06 (ghi chỉ số điện nước) và các tab Tenant/Bills/Profile vẫn là `ComingSoonScreen`, chưa có CRUD.

## 2026-09-10 (Đợt 17) — Sửa menu "⋮" Edit/Delete khớp đúng Figma; nối CRUD thật H-06 (ghi chỉ số điện/nước), hoàn tất seri màn H-0x

**Sửa menu "⋮" Edit/Delete**: bản code ở Đợt 16 (menu Edit/Delete) tô màu đỏ cho "Delete" và không có gạch phân cách — dựa trên suy đoán thay vì Figma thật (lúc đó chưa lấy đúng frame). Lấy lại design context đúng frame "action pop-up" (node `400:2669`/`400:2759`) xác nhận Figma dùng **cùng 1 màu navy đậm cho cả "Edit" và "Delete"** (không đỏ), có 1 gạch chia mảnh dưới "Edit", bo góc 9px (token Figma "radius-xs", nay thêm `AppRadii.xs`). Viết lại `TopBarActionMenuButton` dùng `menuPadding` + widget `_ActionPopupRow` riêng thay cho `PopupMenuItem` mặc định (Material tự áp padding/màu cứng, không khớp Figma).

**Route H-06 đổi từ `readings/:readingId` sang `readings/:roomId/:utility`**: 1 phòng có 2 chuỗi chỉ số độc lập (`tb_electricity_reading`/`tb_water_reading`, tách riêng theo chủ đích đã chốt từ trước — BR-READ-02), nên "xem chi tiết 1 phòng" ở H-06 thực chất là "xem lịch sử 1 phòng + 1 tiện ích", không phải "xem 1 bản ghi chỉ số đơn lẻ" — route cũ không đủ thông tin xác định đúng phòng/tiện ích.

**`ReadingRepository` dùng chung 1 class cho cả 2 bảng** (điện/nước cấu trúc giống hệt nhau), chọn bảng qua tham số `UtilityType` ở mọi method — tránh viết 2 class gần như trùng lặp hoàn toàn.

**`isLocked` cài đúng logic dù hiện tại luôn trả `false`**: theo BR-READ-04, 1 chỉ số bị khoá nếu chính nó gắn `invoice_id`, HOẶC bị hoá đơn khác tham chiếu làm chỉ số "from" trong `utility_lines` (jsonb). Bills (tạo hoá đơn) chưa xây nên `tb_invoice` luôn rỗng — hàm này trong thực tế luôn trả `false`, nhưng cố tình cài đúng cả 2 nhánh kiểm tra ngay từ bây giờ để tự đúng khi Bills xây xong.

**2 lỗi tự phát hiện qua test tay trên thiết bị thật (dữ liệu thật của dungtv — nhà "Nha tro của tao", phòng "p.101"; chỉ số test do tôi tạo để verify đã xoá sạch qua Management API ngay sau khi xong, không để lại dữ liệu rác), cả 2 là lỗi suy luận sai khi ghép provider, không phải lỗi Postgres/RLS:**

1. **"Previous" tự tham chiếu chính nó sau khi phòng đã ghi xong kỳ hiện tại**: `houseMeterEntriesProvider` ban đầu dùng `latestForRoom()` (chỉ số MỚI NHẤT bất kỳ) để hiển thị "Previous" cho mọi dòng — đúng khi phòng CHƯA ghi kỳ này, nhưng SAI ngay khi phòng ĐÃ ghi kỳ này, vì lúc đó "mới nhất" chính là bản ghi vừa tạo của kỳ hiện tại, khiến "Previous" hiện y hệt "Current". Sửa: khi `thisPeriod != null`, lần theo đúng `thisPeriod.previousReadingId` (nguồn sự thật của chuỗi, BR-METER-13) thay vì gọi lại `latestForRoom` — thêm method `ReadingRepository.byId`.
2. **Field "Current" của phòng đã "Recorded" hiện trống thay vì hiện đúng số đã ghi**, và **bộ nhớ controller lẫn giữa các kỳ**: controller không được điền sẵn `thisPeriod.currentReading`, và key controller ban đầu chỉ theo `room+utility` (không theo kỳ đang xem) — gõ dở ở kỳ này rồi chuyển kỳ khác vẫn thấy y nguyên chữ vừa gõ. Sửa: thêm `prefill` cho controller, đổi key thành `room+utility+năm-tháng`.

**Vẫn chưa có điểm vào H-06 Entry thật trong app** (ghi nhận từ Đợt 15 cùng ngày, chưa đổi): Figma không có nút "Ghi chỉ số kỳ này" ở H-03 như SCREEN-SPEC.md mô tả cũ — cố tình KHÔNG tự thêm nút vào H-03/H-04 vì sẽ là bịa layout ngoài Figma, chờ Dream xác nhận vị trí đúng. Đã nối thật "View reading history" ở H-04 (nút CÓ sẵn trên Figma) dẫn vào phần xem/sửa lịch sử theo từng phòng; riêng màn "ghi hàng loạt cho cả nhà" (Entry) route đã đăng ký và verify hoạt động đúng qua điều hướng trực tiếp lúc test (dùng 1 nút debug tạm, đã gỡ ngay sau khi xác nhận — `grep debug` rỗng trước khi build bản cuối). Chưa lọc theo `electricityBillingMethod`/`waterBillingMethod = NOT_BILLED` (BR-READ-05, field nằm trên `tb_contract_version`) vì Tenant/Contract (T-0x) chưa xây, chưa có hợp đồng nào để mà lọc.

**Verify trên thiết bị thật, dữ liệu thật (không phải giả lập)**: ghi chỉ số điện+nước kỳ 09/2026 → hiện đúng ở H-04 + H-06 Detail (đúng SĐT thật của tài khoản ở "Recorded by"); sửa tại chỗ chỉ số điện (100→125) → cập nhật đúng; validate chặn đúng 1 dòng khi nhập chỉ số nhỏ hơn chỉ số cũ, dòng còn lại vẫn lưu bình thường; chuyển sang kỳ kế tiếp → đúng "Not recorded" + "Previous" lấy đúng từ kỳ trước. `flutter analyze` sạch, `dart format` không có gì cần sửa.

## 2026-09-10 (Đợt 18) — Dream cập nhật Figma: H-06 có điểm vào thật (menu "⋮" House), H-04 đổi ảnh sang slider + lịch sử chỉ số dùng List card

**Đóng nợ "H-06 chưa có điểm vào thật"** (ghi nhận từ Đợt 15/17 cùng ngày): dungtv gửi ảnh Figma mới — Dream thêm dòng "Record monthly readings" vào giữa menu "⋮" của House ở H-03 (node `400:2652`, 3 mục Edit/Record monthly readings/Delete, cùng style navy + gạch chia đã sửa ở Đợt 17). Đây là quyết định thiết kế của Dream, không phải suy đoán — xác nhận qua `get_design_context` trực tiếp trên node thật trước khi code, không dựa vào ảnh chụp màn hình đơn thuần.

**`TopBarActionMenuButton` mở rộng tham số optional `onRecordReadings`** thay vì tạo widget menu riêng cho House — House (H-03) truyền tham số này, Room (H-04) không truyền (giữ đúng 2 mục Edit/Delete theo Figma, xác nhận qua node `400:2669`/`400:2759` vẫn chỉ 2 mục). Gỡ bỏ hẳn nút debug tạm dùng để test H-06 Entry trước đó — giờ có đường vào thật.

**H-04 cập nhật theo Figma mới**: ảnh phòng đổi từ khung ảnh đơn sang dạng slider (node `410:2908`, 2 mũi tên trái/phải luôn hiện kể cả khi chưa có ảnh) vì 1 phòng có thể có nhiều ảnh; phần "Reading history" đổi từ dòng text tóm tắt (tự vẽ ở Đợt 16) sang đúng component "List card" (168:48) đã có sẵn trong Design System — dùng lại component có sẵn thay vì tiếp tục tự vẽ riêng, đúng yêu cầu tránh tạo component trùng lặp.

**Bài học quy trình nhắc lại**: đây là lần thứ 2 trong ngày phát hiện code trước đó lệch Figma thật (lần 1 — Đợt 17, menu "⋮" tô nhầm màu đỏ) — cả 2 lần đều do sửa dựa trên suy đoán hợp lý thay vì gọi `get_design_context` đúng node ngay từ đầu. Từ nay, mọi thay đổi UI theo phản hồi "chưa giống thiết kế" đều phải lấy lại node thật qua Figma MCP trước khi sửa, kể cả khi đã có ảnh chụp màn hình người dùng gửi kèm.

**Verify trên thiết bị thật, dữ liệu thật**: bấm "Record monthly readings" ở menu House → mở đúng H-06 Entry (không cần nút debug); ghi thử 1 chỉ số điện (80 kWh, đã xoá sau khi xong) → quay lại H-04, card đổi đúng từ "no reading yet" sang "10/09/2026 · Electricity" + "— → 80 · — kWh · Periodic"; ảnh slider hiện đúng 2 mũi tên ở khung trống. `flutter analyze` sạch, `dart format` đã chạy.

## 2026-09-10 (Đợt 19) — H-03 House detail: bỏ field "Type" tự bịa, thêm field "Manager" đúng Figma thật + policy RLS mới cho phép xem tên người cùng truy cập 1 Nhà

dungtv đọc file `docs/시뮬레이션 케이스 (Mr.Han).md` (kịch bản nghiệp vụ thật từ CEO, dùng kiểm thử thiết kế) và phản hồi: (1) H-03 House detail đang hiện field "Type" không có ý nghĩa gì; (2) nghi ngờ đã bỏ sót khái niệm "Manager" (điểm #8 trong kịch bản: chủ trọ lớn tuổi giao việc quản lý hàng ngày cho con gái qua vai trò Manager theo từng Nhà).

**Lấy lại design context thật qua Figma MCP cho node H-03 House Detail (`312:2069`) — xác nhận cả 2 điều dungtv nói đều đúng:**
- **"Type" hoàn toàn không có trong Figma** — phần "House info" thật chỉ có 2 dòng: Description, Rooms. Field "Type" (hiện `house.houseType`) là do tôi tự thêm ở đợt code UI trước, không đối chiếu kỹ node thật lúc đó.
- **"Manager" CÓ trong Figma**, nằm cuối section "Owner" (sau "Owner email"), giá trị mẫu "Nguyễn Thị Lan" — đúng là điểm #8 của kịch bản Mr. Han (chủ trọ tạo tài khoản, đăng ký cả 3 nhà, thêm con gái làm Manager để con gái thao tác thay).

**Phát hiện phụ khi làm field Manager — lỗ hổng RLS chặn hẳn tính năng này:** `tb_user` chỉ có 1 policy SELECT `"User reads/updates own row" using (id = auth.uid())` — mỗi tài khoản chỉ đọc được đúng dòng của chính mình, không có cách nào lấy `full_name` của người khác (kể cả Manager mình đã mời). Đây không phải lỗ hổng bảo mật (ngược lại, quá chặt tới mức chặn cả chức năng hợp lệ) nhưng chặn đứng field Manager. DATABASE.md mục "Vai trò & phân quyền" đã có ý định rõ ràng cho việc này ("Riêng tư khi mời: nếu SĐT được mời đã có tài khoản, chỉ hiển thị tên ở dạng che một phần") — tức phải xem được tên người cùng truy cập 1 Nhà, chỉ là chưa có policy nào hiện thực hoá ý định đó.

**Đã làm**:
- Migration `20260910150000_tb_user_visible_to_housemates.sql`: thêm policy SELECT mới trên `tb_user` — cho đọc dòng của người khác nếu người đó và mình cùng có ít nhất 1 dòng quyền (`tb_user_house_access`) trỏ tới cùng 1 `houseId` ("housemate"). Không dùng `security definer` (không cần — đây là 2 bảng khác nhau tham chiếu nhau 1 chiều, không tự tham chiếu như lỗi đệ quy đã vá ở Đợt 16, nên không có nguy cơ đệ quy).
- `HouseRepository.listManagerDisplayNames(houseId)`: query 2 bước (không dùng embed PostgREST được vì `tb_user_house_access.phone` chỉ là FK logic, không phải FK thật trong DB) — lấy các dòng `role=manager` của nhà, rồi join tay với `tb_user` theo `phone`; người được mời nhưng chưa có tài khoản thì hiện thẳng SĐT thay vì tên (đúng dữ liệu thật có gì hiện nấy, không bịa).
- `room_list_screen.dart`: bỏ `DetailRow('Type', ...)`, thêm `DetailRow('Manager', ...)` đọc qua provider mới `houseManagersProvider`, nối nhiều tên bằng dấu phẩy nếu >1 Manager, hiện "—" nếu chưa có ai.
- Verify trên thiết bị thật: field Type biến mất; Manager hiện "—" đúng cho nhà chưa mời ai; chèn tạm 1 dòng quyền `role=manager` với SĐT chưa có tài khoản qua Management API → Manager hiện đúng SĐT (nhánh fallback); dọn sạch dữ liệu test ngay sau khi xác nhận. `flutter analyze` sạch, `dart format` đã chạy.

**Chưa làm (nợ mới, ngoài phạm vi lần này)**: mới chỉ có phần XEM "Manager" — chưa có màn nào để chủ nhà thực sự MỜI (thêm SĐT + gán role) hoặc THU quyền Manager. Theo DATABASE.md, thao tác này không tạo tài khoản/không đặt mật khẩu hộ (chỉ ghi 1 dòng `tb_user_house_access`, có hiệu lực ngay cả khi SĐT chưa có tài khoản) — nhiều khả năng thuộc P-0x (Profile tab, hiện vẫn `ComingSoonScreen`, có node Figma "P-06 — Manager Detail (Delete)" đã thấy trong lúc rà soát trước đó) chứ không phải H-0x. Cần rà lại đúng vị trí trong Figma trước khi code, không đoán.

## 2026-09-10 (Đợt 20) — Chốt mô hình mời Manager cho P-0x: `is_active`, hồ sơ riêng trên `tb_user_house_access`, "Main Manager" là phép kiểm tra sống, 1 Manager active/nhà, fallback hiện Owner; vá lỗi lệch định dạng SĐT `tb_user.phone`

Trước khi build P-0x, dungtv yêu cầu list việc cần làm để lên Trello, sau đó xác nhận 3 điểm mơ hồ về schema qua các câu hỏi làm rõ:

1. **`is_active`**: cần tồn tại thật trên `tb_user_house_access` để thể hiện 1 quyền đã cấp đang được bật hay tắt (VD tạm khoá 1 Manager mà không phải xoá hẳn quyền rồi cấp lại).
2. **`full_name`/`id_number` của Manager**: chủ nhà mời tự nhập tay ngay ở form mời (P-06, giống hệt màn tạo), lưu thẳng trên chính dòng `tb_user_house_access` — không phải trên `tb_user` của người được mời, vì tại thời điểm mời người đó có thể còn chưa có tài khoản; khi họ tạo tài khoản sau đó, dòng quyền tự "link" vào qua SĐT trùng khớp. Đây đúng là mô hình đã dùng cho `tb_tenant` (hồ sơ độc lập, không bắt buộc khớp 1 tài khoản thật) — áp lại cho Manager thay vì đặt ra 1 khái niệm mới.
3. **"Main Manager"**: KHÔNG phải 1 vai trò toàn cục cache sẵn — là phép kiểm tra sống "tài khoản này có đang sở hữu (`role=owner`) ≥1 Nhà nào không", tính lại mỗi lần cần hiện badge. 1 tài khoản có thể vừa là Manager (được người khác chỉ định ở nhà của họ) vừa là Main Manager (chủ sở hữu những nhà của riêng mình) cùng lúc — đúng với triết lý cốt lõi Version 3 "vai trò gắn theo từng Nhà, không gắn vào tài khoản" (đã có ở mục ⚠️ #1 của CLAUDE.md, nay áp dụng thêm cho khái niệm mới "Main Manager").

Giữa chừng, dungtv xem ảnh chụp node Figma P-06 (checkbox "House access") và bổ sung thêm 2 luật nữa, cả 2 đều KHÔNG có sẵn trong DATABASE.md/BUSINESS-RULES.md trước đó — quyết định mới, ghi lại ở đây làm nguồn sự thật:

4. **Nhà chưa mời Manager → mặc định chính Owner là người quản lý**, chỉ ở tầng HIỂN THỊ (không tạo thêm dòng DB nào) — về logic là hệ quả tự nhiên của ràng buộc `unique(phone, house_id)` sẵn có (1 SĐT không thể vừa là `owner` vừa là `manager` của cùng 1 Nhà), không cần thêm dữ liệu, chỉ cần UI biết fallback đúng chỗ.
5. **1 Nhà chỉ được có đúng 1 Manager active tại 1 thời điểm** (khác `owner`, không giới hạn số Nhà 1 Manager được quản lý). Hỏi lại dungtv về đúng UX khi chủ nhà cố tick 1 Nhà đã có Manager khác ở P-06 — xác nhận: **disable checkbox đó + hiện tên Manager hiện tại bên cạnh**, không phải tự động thay thế, không cho phép nhiều Manager cùng tick.

**Đã hiện thực hoá (schema + phần hiển thị H-03; UI P-06 thật với logic disable checkbox chưa code, xem changelog cùng ngày):**
- `tb_user_house_access` thêm cột `full_name`, `id_number`, `is_active` (migration `20260910160000`); `has_house_access()` bắt buộc thêm `is_active = true`; thêm policy UPDATE còn thiếu.
- Unique partial index `one_active_manager_per_house` (migration `20260910161000`) — ép luật #5 ở tầng DB, không chỉ dựa vào UI (an toàn cả khi có 2 request chạy đồng thời).
- `HouseRepository.getOwnerDisplayName()` + `houseOwnerNameProvider` — hiện thực luật #4, dùng ở field "Manager" của H-03.

**Vá thêm 1 lỗi lệch định dạng SĐT phát hiện đúng lúc verify luật #4 trên thiết bị thật** (không thuộc phạm vi 3-5 quyết định trên, nhưng phát sinh trực tiếp từ việc build `getOwnerDisplayName()`): `AuthRepository.ensureUserProfile()` ghi `tb_user.phone` bằng `normalizeVnPhone()` — luôn có dấu "+" (chuẩn E.164, đúng cho gọi Supabase Auth API) — nhưng toàn bộ phần còn lại của hệ thống (`current_user_phone()`, mọi cột `phone`/`granted_by_phone`/`recorded_by_phone` trên `tb_user_house_access` và các bảng khác) đều lưu KHÔNG dấu "+". 2 định dạng lệch nhau khiến mọi join theo SĐT giữa `tb_user` và phần còn lại của hệ thống luôn thất bại âm thầm (không lỗi, chỉ không khớp dòng nào) — lộ ra đúng lúc field "Manager" fallback sang Owner hiện thẳng SĐT thay vì tên thật. Sửa bằng cách bỏ dấu "+" trước khi ghi vào cột `tb_user.phone` (giữ nguyên `normalizeVnPhone()` có "+" cho các lệnh gọi Auth API), chạy 1 lần UPDATE sửa dòng dữ liệu cũ đã sai. Bài học: bất kỳ cột `phone` nào thêm mới sau này cũng phải đối chiếu ngay với quy ước "không dấu +" của `current_user_phone()`, không mặc định tái dùng `normalizeVnPhone()` cho mục đích lưu DB.

**Chưa làm**: toàn bộ UI P-0x (P-01→P-07) — mới xong nền schema + phần hiển thị "Manager"/"Owner fallback" ở H-03. P-06 (form mời/sửa Manager) cần cài đúng logic disable checkbox theo luật #5 khi code tới.

## 2026-09-10 (Đợt 21) — Cân nhắc rồi TỪ CHỐI tự động điền/khoá "Owner info" ở H-02 theo hồ sơ người tạo nhà

dungtv đề xuất đổi section "Owner info" ở H-02 (Owner full name/phone/ID number/tax code/bank account/email) từ nhập tay tự do sang **tự động điền theo hồ sơ người tạo nhà và khoá không cho sửa**. Trước khi làm, chỉ ra mâu thuẫn trực tiếp với lý do đã ghi sẵn ở [DATABASE.md](DATABASE.md) mục `tb_house` (dòng "mỗi nhà có thể đứng tên/nhận tiền khác nhau: nhà A đứng tên chủ trọ, nhà B đứng tên vợ, nhà C đứng tên con gái — dù cùng 1 tài khoản quản lý cả 3") — đúng kịch bản thật trong `docs/시뮬레이션 케이스 (Mr.Han).md`. Nếu khoá cứng theo hồ sơ người tạo, không thể còn hỗ trợ case 1 tài khoản đứng tên nhiều pháp nhân khác nhau cho từng nhà nữa.

Hỏi lại dungtv qua 3 phương án (giữ nguyên / tự động điền nhưng vẫn cho sửa / tự động điền và khoá cứng) — **dungtv chọn giữ nguyên như hiện tại: Owner info vẫn nhập tay tự do, không prefill từ hồ sơ tài khoản**. Không có thay đổi code nào ở H-02 (`house_form_screen.dart`) — ghi lại quyết định này để không ai vô tình "sửa lại cho tiện" mà quên mất lý do case Mr. Han đã được cân nhắc kỹ và cố tình giữ nguyên.

Field "Manager" ở H-02 (dropdown chọn Manager) không thuộc phạm vi câu hỏi này — vẫn giữ nguyên là 1 selector độc lập, sẽ nối vào dữ liệu Manager thật từ `tb_user_house_access` khi build P-0x/P-06.

## 2026-09-10/11 (Đợt 22) — Build UI seri P-0x (Profile & Settings), chuẩn hoá format số/tiền toàn app, sửa màu nút Danger sai Figma

dungtv yêu cầu build UI cho toàn bộ seri P-0x, kèm yêu cầu rà soát lại tất cả các chỗ nhập số/tiền trong app phải format chuẩn (dấu phẩy phân cách hàng nghìn).

**Quyết định: audit format số/tiền TRƯỚC khi build P-0x, không build song song.** Rà lại toàn bộ codebase phát hiện: `AppTextField` chưa từng có tham số `inputFormatters` — mọi field tiền (đơn giá điện/nước H-02, diện tích/tiền thuê H-05, phí định kỳ, chỉ số điện nước H-06) đều gõ số thô không dấu phẩy, dù phần LƯU (`_save()`) ở nhiều nơi đã sẵn `.replaceAll(',', '')` chờ dùng — tức code trước đó "biết" sẽ có dấu phẩy nhưng chưa ai nối input formatter vào để dấu phẩy thực sự xuất hiện lúc gõ. Thêm `core/number_format.dart` làm nguồn chuẩn DUY NHẤT: `formatNumber()` (hiển thị), `parseFormattedNumber()` (đọc lại), `ThousandsInputFormatter` (gõ tự thêm dấu phẩy) — `reading.dart`'s `formatReadingValue()` cũ nay chỉ là wrapper gọi hàm này, tránh 2 nguồn định dạng số khác nhau trong cùng 1 app.

**Phát hiện phụ, sửa luôn vì cùng nằm trong phạm vi "chuẩn hoá UI form": `AppButton.danger` sai màu so với Figma.** Nền đặc đỏ đậm + chữ trắng (giống hệt kiểu `primary`, chỉ đổi màu) — trong khi Figma "Button / style=Danger" (xác nhận lại qua `get_design_context` node P-06 Delete + P-07 Logout) là nền đỏ NHẠT (`errorBg`) + viền đỏ đậm + CHỮ đỏ đậm. Bug này có từ trước, đã âm thầm ảnh hưởng 2 dialog xoá House/Room đang chạy thật (`ConfirmDialog` mặc định dùng style Danger) — không ai để ý vì không có bước đối chiếu lại Figma riêng cho biến thể màu nút. Sửa 1 lần ở `app_button.dart`, tự động đúng lại cho MỌI nơi dùng `ConfirmDialog`/`AppButtonStyle.danger`, không cần sửa từng màn.

**Build P-0x (P-01→P-07)**: lấy design context thật qua Figma MCP cho từng node trước khi code (đúng quy trình đã thống nhất từ các Đợt trước). Các quyết định mô hình dữ liệu phát sinh khi build:
- P-06 có field "Note" nhưng `tb_user_house_access` chưa có cột chứa — thêm migration `20260910170000_manager_note_column.sql` (cùng mẫu với `full_name`/`id_number`/`is_active` đã thêm ở Đợt 20: đồng bộ giống nhau trên mọi dòng của 1 Manager, không riêng theo từng Nhà).
- Đổi mật khẩu (P-04): Supabase không có API "xác thực mật khẩu hiện tại" độc lập — dùng `signInWithPassword` lại làm bước xác thực trước khi `updateUser`, đây là pattern chuẩn được Supabase khuyến nghị cho trường hợp này, không phải giải pháp tự nghĩ ra.
- P-03 tái sử dụng nguyên các field tự do sẵn có trên `tb_house` (không tạo bảng riêng) — đúng tinh thần quyết định Đợt 21 (Owner info theo từng Nhà, không khoá theo tài khoản); nút "Apply to all houses" chỉ copy khi người dùng chủ động bấm, không tự động đồng bộ.
- "Main Manager" ở P-01/P-02 tiếp tục đúng mô hình đã chốt Đợt 20: tính SỐNG (`UserRepository.isMainManager`), không cache.

**Verify trên thiết bị thật** xác nhận đúng toàn bộ luồng nghiệp vụ đã chốt trước đó hoạt động end-to-end lần đầu tiên: tạo Manager → H-03 field "Manager" đổi tên ngay; tạo Manager thứ 2 cho cùng Nhà → checkbox tự disable + hiện đúng "Managed by {tên}" (luật 1-Manager-active/Nhà); xoá Manager → H-03 tự rơi về đúng fallback tên Owner. Phát hiện thêm (không sửa, chỉ ghi nhận): dữ liệu "Payout bank account" cũ của dungtv bị lệch cột do UX gộp field của H-02 trước đây (nhập không có dấu "·" nên toàn bộ rơi vào `bankAccountName`) — đây là dữ liệu thật của dungtv, không tự ý sửa, để dungtv tự chỉnh lại qua P-03 khi cần.

**Chưa làm**: chưa verify P-04 lưu thật (tránh khoá tài khoản thật dungtv trên máy test — chỉ verify checklist sống, không bấm Save).

## 2026-09-11 (Đợt 23) — Sửa tận gốc lỗi trộn lẫn biến thể "Select"/"Textarea" với "Readonly" trong `AppTextField`, tách component dùng chung cho P-06

dungtv báo P-03/P-06 chưa giống Figma, cụ thể chỉ ra dropdown "Bank name" ở P-03 sai, kèm yêu cầu: các thành phần form dùng lại ở nhiều màn phải tách thành shared component, không để mỗi màn tự làm 1 kiểu.

**Phân tích nguyên nhân**: Figma component "Input field" (node `165:60`) thực chất có 4 biến thể độc lập — Text, Readonly, Select, Textarea — nhưng `AppTextField` (widget dùng chung của toàn app) chỉ mô hình hoá đúng 2 trong số đó (Text/Readonly qua tham số `readOnly`), và xử lý `trailing: select` chỉ như 1 ICON trang trí cộng thêm, không phải 1 biến thể styling riêng. Hệ quả: bất kỳ ai (kể cả tôi) gán `readOnly: true` cho 1 field cần trailing "select" — theo phản xạ tự nhiên vì field đó "không gõ tay được" — sẽ vô tình biến nó thành biến thể Readonly (nền xám, không viền) thay vì Select (nền trắng, có viền, chữ nhạt) đúng Figma. Lỗi này xảy ra ở CẢ 2 nơi dùng `trailing: select` trong toàn bộ codebase (Status ở H-05, Bank name ở P-03) — không phải lỗi riêng lẻ 1 màn, mà lỗi hệ thống trong chính widget dùng chung. Đây cũng là lỗi CÙNG DẠNG đã gặp và vá 1 lần trước đó (field "Reading period" ở H-06, Đợt 16) nhưng lần đó chỉ sửa tại chỗ gọi, không sửa gốc rễ trong `AppTextField` — nên tái diễn.

**Quyết định**: sửa ngay trong `AppTextField` để `trailing: select` LUÔN tự áp đúng style Select (trắng/viền/chữ tertiary) bất kể tham số `readOnly` caller truyền vào là gì — biến nó thành bất khả thi để cấu hình sai thêm lần nữa, thay vì chỉ sửa 2 chỗ gọi hiện tại rồi hy vọng người sau nhớ đúng quy tắc. Thêm tham số `textarea: true` cho biến thể Textarea (Note ở H-05/P-06, cùng phát hiện qua lần rà soát này — Figma quy định chữ Note cũng dùng tone nhạt tertiary, khác field dữ liệu chính).

**Tách component dùng chung mới, đúng yêu cầu dungtv**: `CheckRow` (`shared/check_row.dart`) và `ToggleRow` (`shared/toggle_row.dart`) — trước đó là 2 class private (`_HouseCheckRow`, `_AccountActiveToggle`) chỉ định nghĩa bên trong `manager_form_screen.dart`. Dù hiện tại mới chỉ P-06 dùng, tách ra `shared/` ngay từ bây giờ (không đợi tới lần dùng thứ 2) vì đây là 2 component Figma có tên riêng, khả năng cao sẽ tái dùng ở các màn hình sau (VD chọn phòng cho hợp đồng nhiều phòng ở T-0x tương lai) — tránh lặp lại đúng vấn đề dungtv vừa chỉ ra. Nhân tiện phát hiện và sửa `CheckRow` đang dùng sai bán kính góc (14px thay vì đúng 12px theo token Figma "radius-md") — thêm hằng số `AppRadii.checkRow` riêng thay vì tái dùng nhầm `AppRadii.card` (14px, dùng cho ListCard).

**Phát hiện phụ cùng đợt rà soát**: `AppBanner` chỉ hỗ trợ đúng 1 tone (Info/xanh, hardcode) — banner cảnh báo "no payout account yet" ở P-03 cần tone Warning (cam) theo Figma nhưng bị dùng nhầm tone Info vì widget chưa cho chọn. Thêm `AppBannerTone` (info/warning) — sửa cùng lúc vì cùng bản chất "component dùng chung thiếu biến thể cần thiết" như 2 lỗi trên.

**Verify trên thiết bị thật**: xác nhận dungtv đã tự dùng P-03 (xây ở Đợt 22) để tách lại đúng dữ liệu "Payout bank account" bị lệch cột từ trước — tính năng hoạt động đúng mục đích thiết kế.

## 2026-09-11 (Đợt 24) — Đẩy sớm đa ngôn ngữ EN/VI/KO ra TOÀN BỘ app (đảo ngược quyết định "để Phase 2")

`docs/CLAUDE.md`/`.claude/rules/flutter.md` ghi sẵn "đa ngôn ngữ để Phase 2" — quyết định đó có từ trước khi có UI thật để đối chiếu. Nhân lúc dungtv hỏi P-0x đã gắn BE thật chưa và yêu cầu làm nốt 2 việc còn thiếu (đổi ảnh đại diện + đổi ngôn ngữ), tôi hỏi lại rõ ràng trước khi động vào quyết định đã ghi trong tài liệu (đúng rule "không tự chọn kiến trúc lớn khi chưa có trong docs"): giữ nguyên Phase 2 / làm ngay nhưng chỉ P-0x / làm ngay toàn app. **dungtv chọn làm ngay toàn app** — ghi đè quyết định "Phase 2" cũ bằng quyết định mới này.

**Phát hiện quan trọng trước khi bắt tay code**: rà lại codebase phát hiện app đã có sẵn 1 cơ chế đa ngôn ngữ tự viết từ một phiên làm việc trước đó (`lib/core/app_strings.dart` + `assets/lang/{en,vi,ko}.json`), nhưng mới chỉ 2 màn Login/Signup dùng — không phải "Phase 2 chưa từng đụng tới" như dòng ghi chú trong `docs/CLAUDE.md` khiến người đọc tưởng. Cơ chế này CỐ TÌNH không dùng `flutter_localizations`/ARB hay `easy_localization` (2 lựa chọn "mặc định" khi nói tới i18n Flutter) — lý do: dungtv cần tự sửa được bản dịch bằng cách mở thẳng file JSON, không cần biết Flutter tooling/không cần build lại gen-l10n. Quyết định lần này là MỞ RỘNG cơ chế có sẵn ra toàn app, không tự ý đổi sang thư viện chuẩn ngành dù có vẻ "đúng bài bản" hơn — vì đổi kiến trúc éo có trong docs, và đổi sẽ phá mất lý do ban đầu (dungtv tự sửa JSON được).

**Quy ước mới cần nhớ khi thêm màn/widget mới sau này**: `AppStrings.t()` đọc từ 1 biến static (`AppStrings.current`), KHÔNG phải nguồn dữ liệu Riverpod — nên mọi widget dùng `AppStrings.t()` bắt buộc phải tự `ref.watch(languageProvider)` (giá trị bỏ qua, chỉ để ép rebuild) thì đổi ngôn ngữ ở P-01 mới khiến màn đó tự vẽ lại chữ mới; quên dòng này là bug im lặng (không lỗi biên dịch, chỉ là màn đó "đứng yên" không đổi ngôn ngữ cho tới khi hot-restart). Cũng phát sinh ràng buộc Dart: tham số mặc định kiểu `this.label = 'Some text'` không gọi được `AppStrings.t()` (không phải hằng số biên dịch) — phải đổi sang `String?` nullable rồi resolve trong `build()`.

**Ca đặc biệt cần tách biệt dữ liệu LƯU vs nhãn HIỂN THỊ**: danh sách tiện ích cố định ở H-05 (`A/C`, `Water heater`, `Balcony`, `Window`) vừa là nhãn hiển thị vừa là giá trị so khớp/lưu thẳng vào `tb_room.amenities` — quyết định giữ nguyên danh sách tiếng Anh này làm DỮ LIỆU (để không phá dữ liệu cũ đã lưu khi đổi ngôn ngữ), chỉ thêm 1 hàm dịch riêng cho phần hiển thị trên chip. Bài học áp dụng chung: bất kỳ chỗ nào 1 chuỗi tiếng Anh vừa là literal hiển thị vừa là giá trị lưu DB (không phải qua bảng mã/enum có sẵn), phải tách rõ 2 vai trò này trước khi dịch, không được dịch thẳng chuỗi gốc.

**Verify trên thiết bị thật**: build APK release, cài lên `R7AY3074GAD`, tự tay đổi ngôn ngữ EN→VI→KO→EN qua P-01 và xác nhận toàn bộ các màn đã đi qua (Home, House detail, Room list/detail, H-06 Entry/Detail, toàn bộ P-01→P-06, khung Notification center) tự vẽ lại đúng ngôn ngữ ngay lập tức, không cần khởi động lại app, không vỡ layout.

## 2026-09-11 (Đợt 25) — Cho phép tạo hồ sơ Manager mà CHƯA gán Nhà nào (đảo ngược 1 phần giới hạn của Đợt 20)

Lúc dungtv tự tay test lại toàn bộ luồng P-0x (theo yêu cầu "test lại toàn bộ luồng điền đầy đủ các form"), phát hiện: tạo 1 Manager mới ở P-06 mà KHÔNG tick Nhà nào (VD nhà duy nhất đã có Manager active khác nên checkbox bị disable) → bấm Save vẫn quay về danh sách như thành công, không báo lỗi gì, nhưng **toàn bộ form (tên/SĐT/CCCD/note) bị mất trắng, không lưu ở đâu cả**. Nguyên nhân gốc: theo quyết định Đợt 20, 1 Manager KHÔNG có hồ sơ độc lập — mọi thông tin của họ chỉ tồn tại TRÊN chính dòng cấp quyền cho 1 Nhà cụ thể (`tb_user_house_access`), nên 0 Nhà = 0 dòng = Manager chưa từng "tồn tại" trong hệ thống.

Ban đầu đề xuất hướng nhẹ (chỉ thêm validation chặn Save + báo lỗi rõ khi 0 nhà, giữ nguyên kiến trúc). dungtv phản hồi muốn hướng khác: **"tôi chỉ muốn tạo một manager rồi để đấy thôi"** — tức muốn tạo trước hồ sơ Manager, gán Nhà sau khi có chỗ trống, không bị bắt buộc phải có Nhà ngay lúc tạo. Đối chiếu lại `BUSINESS-RULES.md` (BR-ROLE-01/04) và `DATABASE.md`/`SCREEN-SPEC.md` xác nhận: đây thật sự là kiến trúc đã chốt, không phải giới hạn UI đơn thuần — nên hỏi lại dungtv rõ ràng giữa 2 hướng (đổi kiến trúc / giữ nguyên + chỉ chặn lỗi) trước khi làm, đúng quy tắc "không tự ý đổi kiến trúc khi chưa có trong docs". **dungtv chọn đổi kiến trúc.**

**Đã làm — cho `houseId` được NULL, đại diện 1 hồ sơ Manager "nháp" chưa gán Nhà:**
- Migration `20260911110000_manager_profile_without_house.sql`: `tb_user_house_access.house_id` bỏ `NOT NULL`; thêm unique partial index `one_draft_profile_per_owner` trên `(phone, grantedByUserId) where role='manager' and houseId is null` — mỗi Owner chỉ có đúng 1 dòng nháp/1 SĐT Manager (không giới hạn 2 Owner khác nhau cùng tạo nháp cho cùng 1 SĐT — mỗi người vẫn độc lập, giữ đúng nguyên tắc cách ly dữ liệu giữa các Owner đã chốt từ Đợt 20). Thêm RLS policy riêng cho dòng nháp (`house_id is null and granted_by_phone = current_user_phone()`) vì policy cũ (`has_house_access(house_id, ...)`) luôn `false` khi `house_id` NULL nên không áp dụng được cho trường hợp này.
- `UserRepository.saveManager()`: khi `houseIds` rỗng → tự tạo/cập nhật 1 dòng nháp (upsert thủ công: SELECT rồi INSERT hoặc UPDATE, không dùng `.upsert()` của Postgrest vì client không hỗ trợ nhắm đúng partial unique index qua `onConflict`); khi `houseIds` chuyển từ rỗng sang có Nhà thật → tự xoá dòng nháp (hồ sơ nay sống trên dòng Nhà thật, không cần nháp nữa). `listManagerAccounts()` gộp thêm dòng nháp (lọc theo `granted_by_phone = tôi`) vào cùng danh sách theo SĐT; `removeManager()` xoá cả dòng nháp nếu có.
- `manager_form_screen.dart`: thêm hint "Manager này được lưu mà chưa gán Nhà nào — có thể gán Nhà bất cứ lúc nào sau này" khi đang có ≥1 Nhà nhưng chưa tick cái nào.

**Verify trên thiết bị thật** (tự tay dựng lại đúng ca dungtv mô tả): tạo Manager "Le Thi Test" không tick Nhà nào (nhà duy nhất đang bị disable do "Nguyen van B" active) → Save thành công thật, P-05 hiện đúng "No house granted" (trước đó: biến mất hoàn toàn). Tắt "Account active" của "Nguyen van B" để giải phóng Nhà → sửa lại "Le Thi Test", tick Nhà đó → Save → đối chiếu DB xác nhận dòng nháp đã bị xoá, thay bằng 1 dòng thật với `house_id` đúng; H-03 "Manager" hiện đúng "Le Thi Test". Test thêm 1 tình huống dungtv chủ động hỏi: bật lại "Account active" cho "Nguyen van B" trong khi "Le Thi Test" đang active CÙNG 1 Nhà → bị chặn đúng bởi unique index `one_active_manager_per_house` có sẵn từ Đợt 20, hiện lỗi rõ ràng, dữ liệu không bị hỏng (không có 2 Manager active cùng lúc cho 1 Nhà) — xác nhận 2 cơ chế (nháp + 1-active-manager-per-house) hoạt động đúng cùng lúc, không xung đột nhau.

## 2026-09-11 (Đợt 26) — T-09 End Contract KHÔNG tự tạo hoá đơn cuối (sửa lại `SCREEN-SPEC.md` cho khớp Figma thật)

Trước khi bắt đầu code seri T-0x (Tenant & Contract), rà lại toàn bộ 10 màn T-0x thật trên Figma (đối chiếu `SCREEN-SPEC.md`/`BUSINESS-RULES.md`/`DATABASE.md`) theo đúng quy trình đã áp dụng cho H-0x/P-0x trước đó — phát hiện `SCREEN-SPEC.md` mục T-09 ghi "Xác nhận → ... → tạo hoá đơn cuối với số tiền đã tính" nhưng Figma thật (frame "T-09 — End Contract (Settlement)") có banner cảnh báo ngược lại: **"Ending a contract does NOT create a final invoice. If anything is still owed, create that invoice in Bills first."**

Hỏi lại dungtv theo đúng 2 lựa chọn (theo Figma mới / theo văn bản cũ) trước khi code, tránh tự đoán. **dungtv chọn theo Figma** — T-09 chỉ tính và ghi lại số liệu đối soát (`unpaidInvoicesTotal`, `damageDeduction`, `refundAmount`, `settlementConfirmedAt`) vào `tb_contract`, chuyển `status=Ended`, chuyển mọi phòng về "Empty" — **không** tự sinh bất kỳ dòng `tb_invoice` nào. Muốn thu/hoàn thêm khoản gì sau khi kết thúc hợp đồng thì chủ nhà tự tạo hoá đơn riêng ở B-0x (đơn lẻ, B-03). Đã sửa lại `SCREEN-SPEC.md` mục T-09 cho khớp — không cần sửa `BUSINESS-RULES.md` (`BR-CTR-02` vốn đã chỉ nói "ghi vào các field settlement trên `tb_contract`", không có chỗ nào nói tự tạo hoá đơn — chỉ riêng `SCREEN-SPEC.md` bị lệch).

Nhân tiện phát hiện thêm 2 điểm Figma T-0x khác có thể lệch với văn bản, dungtv xin để dành quyết định sau (chưa chốt, ghi lại để không quên):
- T-06 (Create Contract): Figma chỉ vẽ chọn đúng 1 phòng, trong khi `BR-CTR-04`/`BR-CTR-05` ghi rõ 1 hợp đồng có thể gồm nhiều phòng (multi-select). dungtv sẽ tự chốt lại với Dream (designer) trước.
- T-10 (Invoice Schedule Preview): Figma vẽ xem trước ĐÚNG 1 kỳ (khi tap 1 chip từ dải "Invoice Schedule" ở T-05), khác mô tả `SCREEN-SPEC.md` ("list 3-6 kỳ sắp tới cùng lúc").

## 2026-09-11 (Đợt 27) — T-06 chốt multi-room + thêm `service_billing_method`, T-10 chốt single-period

Cả 2 điểm để ngỏ ở Đợt 26 nay đã chốt:

- **T-06 multi-room:** dungtv xác nhận đã chốt lại với designer ("đã có design mới rồi") — kéo lại Figma T-06 (node `220:3669`) thấy field "Room" nay hiển thị nhiều phòng gộp dấu phẩy (VD "P101, P102"), khớp đúng `BR-CTR-04`/`BR-CTR-05` (nhiều phòng/1 hợp đồng) và khớp sẵn cấu trúc bảng `tb_contract_room` đã có — không cần sửa schema cho phần này.
- **T-10 single-period:** dungtv tự đọc lại Figma, thấy header T-10 hiển thị theo dạng "1 kỳ/tháng-năm" (VD "Period 12/2026") kèm banner "Preview only" — xác nhận T-10 xem trước ĐÚNG 1 kỳ khi tap 1 chip từ dải "Invoice Schedule" ở T-05, KHÔNG phải list 3-6 kỳ như `SCREEN-SPEC.md` mô tả trước đó. Sẽ sửa lại `SCREEN-SPEC.md` khi code T-10.

Kéo lại Figma T-06 lần này cũng lộ thêm 2 field mới chưa khớp schema — hỏi lại dungtv trước khi code (không tự đoán):

1. **"Service billing method"** (Select: Flat/khác) + "Price" — xuất hiện song song với Electricity/Water (đều có billing method + giá), và xuất hiện ở CẢ T-05 (Contract Detail, màn chỉ đọc dữ liệu đã lưu — "Service · Flat · 300,000/month") lẫn T-06 (form nhập) → xác nhận đây là field thật, không phải chỉ trang trí UI. Trong khi đó `tb_contract_version` hiện chỉ có `service_fee_rate_per_sqm × contract_area_sqm` (luôn tính theo m², không có khái niệm billing method).
   - **Đã chốt:** Thêm cột `service_billing_method text not null default 'ByArea' check (in ('Flat','ByArea'))` vào `tb_contract_version` (migration `20260911120000_contract_version_service_billing_method.sql`, đã push). `Flat` → nhập thẳng `service_fee_amount`/tháng; `ByArea` → giữ nguyên cách tính cũ `service_fee_rate_per_sqm * contract_area_sqm` (giữ tương thích ngược, cho nhà nào vẫn muốn tính theo m²). Model `ContractVersion` + enum `ServiceBillingMethod` (`flat`/`byArea`) đã thêm ở `data/models/contract.dart`.
2. **Phí định kỳ (recurring fee) có thêm field "Billing method" (Flat/None)** ở mỗi dòng trong form T-06 (VD "Parking / None / 0"). Đối chiếu T-05 (Contract Detail): dòng có `None` (Parking) **không hiển thị** trong danh sách phí định kỳ đã lưu (chỉ thấy Internet, Waste) → xác nhận "None" chỉ là toggle ẩn/bật dòng ngay tại form, KHÔNG phải field cần lưu riêng. **Đã chốt (tự suy luận từ bằng chứng T-05, không cần hỏi thêm):** giữ nguyên model `RecurringFee {name, amount}`/schema `recurring_fees jsonb [{name, amount}]` — dòng nào chọn "None" thì loại khỏi danh sách lưu (khớp cách `RecurringFeesController` đã bỏ qua dòng rỗng).

## 2026-09-11 (Đợt 28) — Code xong T-07→T-10, vá lỗi "Special note" mất dữ liệu ở T-06, loạt suy luận T-09/T-10 chưa có BR/DATABASE chốt sẵn

Code nốt 4 màn còn lại của seri T-0x: T-07 (Renew/Amend), T-08 (Version History), T-09 (End Contract/Settlement), T-10 (Invoice Schedule Preview). Ghi lại các quyết định/vá lỗi phát sinh trong lúc code, không hỏi lại dungtv cho từng cái (đều thuộc diện thấp rủi ro/đã có đủ bằng chứng Figma để suy luận hợp lý), nhưng ghi lại đầy đủ để dungtv soát lại nếu cần:

1. **Lỗi thật phát hiện khi code T-07: "Special note" ở T-06 hiện trên form nhưng KHÔNG được lưu.** Figma T-06/T-07 đều có 2 field textarea riêng biệt "Late fee terms" và "Special note", nhưng `tb_contract_version` trước đó chỉ có cột `late_fee_terms` — không có cột cho "Special note", và code T-06 (đợt trước) có tạo `_specialNoteController`, hiện đúng UI, nhưng quên gán vào `ContractVersion` lúc lưu → dữ liệu người dùng gõ vào bị mất trắng, không báo lỗi gì. Đã vá: thêm migration `20260911130000_contract_version_special_note.sql` (cột `special_note text`), thêm field `specialNote` vào model `ContractVersion`, sửa `contract_form_screen.dart` (T-06) để lưu đúng, và hiện field này ở T-05 (`ContractTermsDetailBlock`, dùng chung cho cả T-05/T-08).
2. **T-07 (Renew/Amend): Figma hiện tại (kéo lại 11/09/2026) đơn giản hơn T-06/T-05** — không có UI sửa billing method điện/nước (chỉ 1 field giá duy nhất/loại), không có field Phí dịch vụ, không có field Môi giới. Quyết định: giữ nguyên billing method + phí dịch vụ (rate/area/amount/method) + môi giới từ phiên bản hiện hành, KHÔNG cho sửa ở T-07 (khớp đúng những gì Figma thật sự vẽ) — chỉ trường giá điện/nước (unit price hoặc flat amount, tuỳ method đang khoá) là được sửa.
3. **T-09: "End reason" (Select) không có cột riêng trong `tb_contract`.** Figma vẽ 2 field độc lập "End reason" (dropdown, VD "Tenant moved out") và "Deduction reason" (textarea, lý do khấu trừ tiền cọc) — nhưng DB chỉ có đúng 1 cột `settlement_note` (text tự do). Quyết định: gộp `"{end reason label}. {deduction reason}"` thành 1 chuỗi lưu vào `settlement_note` — không thêm cột `end_reason` riêng vì đây chỉ là lý do phân loại, không ảnh hưởng số liệu đối soát, không cần truy vấn lọc theo lý do ở Phase 1.
4. **T-09 Move-out readings theo TỪNG phòng** (giống Move-in ở T-06) — Figma T-09 chỉ vẽ ví dụ 1 phòng (P.101, hợp đồng 1 phòng) nên không thấy rõ layout nhiều phòng, nhưng vì T-06 đã xác nhận hợp đồng nhiều phòng (Đợt 27), suy luận hợp lý là T-09 cũng lặp lại đúng pattern "1 khối chỉ số/phòng" y hệt T-06 — đã code theo hướng này.
5. **T-10 (Invoice Schedule Preview) — cách chia kỳ/tính hạn thanh toán KHÔNG có trong `BUSINESS-RULES.md`/`DATABASE.md`.** Đã tự suy luận (ghi rõ trong code `core/invoice_period.dart`): kỳ N = `[startDate + N×rentCycleMonths, kỳ kế tiếp − 1 ngày]` (ngày neo = ngày trong tháng của `startDate` phiên bản hiện hành), hạn thanh toán = ngày `paymentDueDayOfMonth` của THÁNG KẾT THÚC kỳ (lùi về ngày cuối tháng nếu không có, khớp đúng hint đã ghi ở T-06). Khớp đúng ví dụ Figma (kỳ 15/12/2026→14/01/2027, hạn 05/01/2027). Vì đây là màn CHỈ XEM TRƯỚC, không ghi gì vào DB ("Nothing is stored in the database" — banner Figma tự ghi rõ), nên đổi cách tính này sau (nếu sai) không ảnh hưởng dữ liệu cũ.
6. **T-10 "Estimated amounts" thêm dòng Service (phí dịch vụ) vào tổng "Fixed part total"** dù ví dụ tĩnh trên Figma không có dòng này (frame T-10 có thể chưa cập nhật theo field Service mới ở T-06/T-05, xem Đợt 27) — quyết định thêm cho khớp mô hình dữ liệu hiện tại (service fee cũng là khoản cố định hàng tháng, không phụ thuộc chỉ số), tương tự lý do đã áp dụng cho T-07 mục 2 ở trên (ưu tiên khớp dữ liệu thật hơn khớp pixel 1 frame cũ).

## 2026-09-14 (Đợt 29) — Test toàn luồng thật T-01→T-10, vá 2 bug thật lộ ra khi test

dungtv yêu cầu test đầy đủ luồng thật (tạo người thuê → tạo hợp đồng → mọi hành động hợp đồng) trước khi cho commit — bám sát Figma, form không bỏ trống ô nào, tối thiểu 2 nhà/2 phòng/2 hợp đồng. Test lộ ra 2 vấn đề thật, cả 2 đều đã vá:

1. **`roomStatusesByHouseProvider` (Home dashboard "Total/Empty rooms" + badge N/M từng nhà) không được `ref.invalidate()` sau khi tạo hoặc kết thúc hợp đồng** — trong khi `roomsProvider(houseId)` (tab Rooms trong 1 nhà) vẫn được invalidate đúng ở cả `contract_form_screen.dart` và `contract_end_screen.dart`. Hậu quả: Home dashboard hiện sai số phòng trống/đã thuê cho tới khi khởi động lại app. Đã thêm dòng invalidate còn thiếu vào cả 2 file, đúng theo pattern các màn khác (`room_form_screen.dart`/`room_detail_screen.dart`/`room_list_screen.dart`) đã làm sẵn.
2. **Room Detail (H-04) khối "CURRENT CONTRACT" luôn hiện cứng "No active contract."** dù phòng đang có hợp đồng Active — đây là `// TODO` bỏ ngỏ từ đợt T-05/T-06 (chưa từng nối `roomId → contract Active`), không phải bug mới nhưng lộ ra khi test full luồng lần này. Đã vá: thêm `ContractRepository.activeContractIdForRoom()` (tra bảng nối `tb_contract_room` theo `room_id` + `is_active=true`) + provider `roomActiveContractProvider` (ghép thêm điều khoản hiện hành + Tenant), `room_detail_screen.dart` hiện đúng `MiniProfileCard` (Figma đã có sẵn ý định dùng widget này ở H-04 — ghi trong comment của chính widget đó — nhưng chưa từng nối) + Monthly rent/End date + nút "View contract" (key ngôn ngữ có sẵn từ trước, cũng chưa từng dùng) trỏ sang T-05.

Cả 2 đều thuộc dạng "thiếu invalidate/thiếu nối provider", không phải lỗi logic nghiệp vụ — không cần đổi schema hay quyết định nghiệp vụ mới, chỉ ghi lại vì đúng quy ước "mọi thay đổi ảnh hưởng trạng thái phải ghi lại". Chi tiết đầy đủ xem `changelog/2026-09-14.md`.

## 2026-09-14 (Đợt 30) — Icon toàn app dùng sai font, đổi sang `material_symbols_icons`

dungtv gửi ảnh trang "DESIGN SYSTEM — V3 · components & tokens" trên Figma và nhắc lại rule bắt buộc bám theo design system chung, chỉ ra icon trong app chưa giống thiết kế.

**Phát hiện**: Component "Icon" (node `163:5`) trong Design System V3 ghi rõ dùng font **`Material Symbols Rounded`** (Google Material Symbols, ligature theo tên glyph — VD `home`, `bolt`, `water_drop`, `receipt_long`), khác với font "Material Icons" cổ điển mà Flutter dùng mặc định qua class `Icons` (`uses-material-design: true` trong `pubspec.yaml`). 2 bộ font có nhiều tên glyph trùng nhưng hình dạng thật sự khác nhau (nét, độ bo góc, độ dày) — nên dù code trước đó chọn đúng TÊN icon hợp lý (VD `Icons.bolt_rounded` cho điện, `Icons.water_drop_rounded` cho nước), hình ảnh hiển thị ra vẫn không khớp Figma. Đây là lệch xuyên suốt toàn app (64 chỗ dùng icon, 26 file) chứ không phải lỗi ở 1 màn cụ thể.

**Quyết định**: Thêm package `material_symbols_icons` (^4.2960.0) — bundle sẵn cả 3 biến thể font Material Symbols (Outlined/Rounded/Sharp), expose qua class `Symbols` với tên glyph + hậu tố kiểu (VD `Symbols.home_rounded`), không cần khai báo font thủ công trong `pubspec.yaml`. Thay toàn bộ `Icons.xxx` sang `Symbols.xxx_rounded` tương ứng (dùng biến thể Rounded xuyên suốt, khớp đúng tên font Figma dùng). Không tự dựng font/codepoint thủ công vì rủi ro sai codepoint cao hơn, package này là lựa chọn phổ biến/còn bảo trì cho đúng nhu cầu này.

Cập nhật `docs/DESIGN-SYSTEMS.md` mục 5 (Iconography) ghi rõ font chuẩn + tên package dùng trong code, tránh lặp lại nhầm lẫn `Icons.xxx` ở các đợt code sau.

## 2026-09-14 (Đợt 31) — Bắt đầu B-0x: sửa số màn lệch Figma, vá TODO prorate tiền nhà

Trước khi code B-0x, kéo lại Figma thật cho cả 5 frame (`220:4166..220:4667`) — phát hiện `SCREEN-SPEC.md` đánh số sai thứ tự B-02/B-03 (Batch/Single bị đảo) và B-04/B-05 (Send sheet/Invoice Detail bị đảo), cùng lỗi từng gặp ở T-0x trước đây. Đã sửa lại `SCREEN-SPEC.md` khớp đúng Figma: **B-01=Invoice List, B-02=Create Single, B-03=Create Batch, B-04=Invoice Detail, B-05=Send Invoice sheet**.

Phát hiện thêm: Edge Function `generate-invoice`/`generate-payment-qr` đã được viết + deploy từ trước (không thuộc phạm vi code Flutter), xử lý đúng phần lớn BR-BILL-01→11 — quyết định KHÔNG viết lại engine tính tiền bằng Dart, Flutter chỉ gọi 2 function này qua `supabase.functions.invoke(...)` (pattern mới, chưa có tiền lệ trong app — trước giờ chỉ dùng `auth.signInWithOtp`/`verifyOTP` có sẵn của SDK, chưa từng tự gọi Edge Function tuỳ biến). Đã vá 1 TODO còn sót trong `generate-invoice` (prorate tiền nhà theo ngày ở khi MOVE_IN/MOVE_OUT giữa kỳ — dungtv xác nhận vá trước khi làm UI), deploy lại thành công.

## 2026-09-14 (Đợt 32) — B-01/B-02 code xong, vá 3 bug nghiêm trọng phát hiện khi test thật

Test tạo hoá đơn thật đầu tiên (A.201/Nguyen Thi Lan, kỳ 09/2026) lộ ra 3 bug, cả 3 đều đã vá và verify lại:

1. **Edge Function chỉ chấp nhận secret key.** `generate-invoice`/`generate-payment-qr` cấu hình `auth: ["secret"]` — app mobile không thể gọi (không được nhúng service-role key). Sửa `auth: ["user", "secret"]`, thêm bước tự kiểm tra quyền qua `ctx.supabase` (RLS-scoped) trước khi dùng `ctx.supabaseAdmin` để ghi. `secret` giữ lại cho test/script nội bộ.
2. **`core/invoice_period.dart` tính kỳ hoá đơn sai mô hình.** Đợt 28 tự suy luận (không có `BR-BILL-xx` lúc đó tưởng là chưa quy định) neo kỳ theo ngày ký hợp đồng — nhưng `BR-BILL-07` đã quy định rõ "điện/nước luôn tính theo tháng dương lịch", và Edge Function `generate-invoice` (viết trước, đúng luật) đã dùng đúng tháng dương lịch. Sửa lại `_periodAt()`/`periodStartingAt()` theo tháng dương lịch, verify lại T-05 + T-10 không regression.
3. **So `period_ym` bằng `eq` sai cho MOVE_IN/MOVE_OUT.** Cột này lưu đúng ngày sự kiện thật (không phải ngày 1 đầu tháng), nên `eq(periodYm)` chỉ đúng khi dọn vào/ra đúng ngày 1 — sai với mọi trường hợp khác. Ảnh hưởng: prorate tiền nhà (mới thêm ở Đợt 31) không kích hoạt, và fallback tìm chỉ số MOVE_OUT có sẵn từ trước cũng bị lỗi tương tự (chưa ai phát hiện vì T-09 End Contract chưa từng thử tạo hoá đơn cuối kỳ qua đường này). Sửa cả 2 chỗ thành lọc theo khoảng ngày của tháng.

Kèm code xong B-01 (Bills List)/B-02 (Create Invoice Single) — xem `changelog/2026-09-14.md` cho chi tiết UI. B-03/B-04/B-05 còn lại.

## 2026-09-14 (Đợt 33) — B-03 (Create Invoice — Batch): thêm chế độ preview cho Edge Function

Figma B-03 (node `220:4448`) vẽ 1 danh sách checkbox cho chọn/bỏ chọn TỪNG hợp đồng trước khi tạo (kèm số tiền ước tính từng dòng, badge Ready/No reading/Already created) — nhưng `generate-invoice` (`mode: "batch"`) lúc đó chỉ hỗ trợ "tạo cho TOÀN BỘ hợp đồng Active của 1 Nhà", không nhận danh sách ID cụ thể, và không có chế độ "chỉ tính thử, không lưu" để hiện số tiền ước tính mà không tạo hoá đơn thật. Hỏi dungtv trước khi code (theo đúng chỉ dẫn "có gì không chắc thì hỏi trước") — dungtv chọn: thêm chế độ preview vào `generate-invoice` (tái dùng nguyên engine tính tiền, không viết lại), khi bấm tạo thì gọi lẻ `mode: "single"` cho từng hợp đồng đã tick chọn — KHÔNG mở rộng `mode: "batch"` để nhận danh sách ID riêng, giữ nguyên tiền lệ B-02 "mở màn/bấm tạo = gọi `generateSingle` cho 1 hợp đồng".

Đã thêm `mode: "previewBatch"` — lặp `generateSingleInvoice(..., {dryRun: true})` qua mọi hợp đồng Active của 1 Nhà, trả về trạng thái + số tiền ước tính từng hợp đồng mà KHÔNG ghi DB. Nhân tiện vá thêm 1 lỗ hổng liên quan: `mode: "single"` (dùng ở cả B-02 và B-03) trước đây không hề kiểm tra hoá đơn đã tồn tại cho đúng kỳ đó — gọi lại 2 lần cùng 1 kỳ sẽ tạo trùng. Đã thêm bước kiểm tra "kỳ này đã có hoá đơn chưa" ở đầu `generateSingleInvoice()`, trả về hoá đơn đã có (`alreadyExisted: true`) thay vì tạo mới — áp dụng cho mọi mode gọi tới hàm này.

Code B-01→B-03 (Bills List/Create Single/Create Batch) coi như xong phần UI+CRUD thật. Còn lại B-04 (Invoice Detail), B-05 (Send Invoice sheet — phải hỏi dungtv trước khi đụng Zalo OA/thêm QR code, theo chỉ dẫn đã nhận 2026-09-14).

## 2026-09-14 (Đợt 34) — B-04 (Invoice Detail): bỏ nhãn phụ "full month/N ngày" ở dòng tiền nhà

Figma B-04 (node `220:4544`) hiện dòng "Monthly rent" kèm nhãn phụ mô tả có prorate hay không (VD "3,200,000 · full month", ngụ ý ví dụ khác sẽ ghi "· 17/30 days" khi MOVE_IN/MOVE_OUT giữa kỳ). `tb_invoice`/model `Invoice` hiện chỉ lưu `rentAmount` đã tính xong (kết quả cuối), KHÔNG lưu lại số ngày ở thực tế/số ngày trong tháng dùng để tính — nên Flutter không tái dựng được nhãn phụ này mà không thêm cột mới vào `tb_invoice` (VD `rentDaysOccupied`/`rentDaysInMonth`). Quyết định: bỏ nhãn phụ, chỉ hiện số tiền — không tự thêm cột mới vì đây là chi tiết hiển thị nhỏ, để dungtv xác nhận có cần khớp đúng chi tiết này trước khi đổi schema.

Route `/bills/invoices/:invoiceId` (B-04) đặt SAU 2 route tĩnh `invoices/new`/`invoices/new-batch` trong cùng danh sách `routes` của go_router — thứ tự này bắt buộc vì go_router khớp theo thứ tự khai báo, route tham số `:invoiceId` phải đứng cuối để không "nuốt" mất 2 route tĩnh phía trước.

## 2026-09-14 (Đợt 35) — B-05 (Send Invoice): SMS thật qua eSMS, Zalo/Both khoá chờ OA

Trước khi code B-05, hỏi dungtv về Zalo OA (theo đúng chỉ dẫn "khi nào đến zalo OA thì hãy hỏi tôi") — dungtv xác nhận **đã hoàn tất thủ tục** đăng ký Zalo OA nhưng khi hỏi cụ thể cần 5 giá trị gì (OA ID/App ID/App Secret/Access+Refresh token/Template ID + tên tham số mẫu ZNS) thì gửi nhầm lại đúng cặp API key/Secret key của eSMS (đã set từ sáng) — tức 5 giá trị Zalo thật sự **chưa có trong tay lúc này**. Quyết định: tạm dừng phần Zalo, chờ dungtv gửi đúng bộ thông tin OA khi sẵn sàng; dungtv yêu cầu triển khai eSMS trước trong lúc chờ.

**Phát hiện thêm khi triển khai SMS**: eSMS hiện chỉ có Brandname DEMO "Baotrixemay" (SmsType "2", khoá cứng đúng 1 mẫu nội dung OTP đã duyệt — xem `send-otp-sms/index.ts`) — KHÔNG thể dùng để gửi nội dung hoá đơn tự do (số tiền, hạn thanh toán...). Hỏi dungtv có Brandname CSKH riêng (SmsType "8", nội dung tự do) chưa — chưa có. Quyết định: dùng **SmsType "1"** (tin thường qua đầu số/tổng đài dùng chung của eSMS) — gửi được nội dung thật NGAY, không cần đăng ký/duyệt trước, đánh đổi là người nhận thấy số điện thoại thay vì tên "BizTown". Nâng cấp lên Brandname CSKH (SmsType "8") sau chỉ cần đổi code trong `sendSmsViaEsms()`, không đổi luồng gọi.

**Đã code**:
- `supabase/functions/send-notification/index.ts` — hoàn thiện phần TODO gửi SMS Tenant (giữ nguyên phần Push/FCM vẫn TODO, ngoài phạm vi): thêm `sendSmsViaEsms()` (SmsType "1"), đổi `auth: ["secret"]` → `["user", "secret"]` + permission check qua `ctx.supabase` (policy `tb_house` có sẵn) — cùng pattern đã áp dụng cho `generate-invoice`/`generate-payment-qr` ở Đợt 32.
- `InvoiceRepository.sendSms()` (mới) — gọi `send-notification` (kênh `tenant`, `push: false`) rồi tự `updateStatus(Sent)`.
- `bills/send_invoice_sheet.dart` (mới, B-05, node `220:4667`) — bottom sheet đúng Figma: handle, "To {tenant} · {phone}", 3 lựa chọn kênh (SMS chọn sẵn + hoạt động thật; Zalo/Both vẽ đúng UI nhưng mờ 60% + phụ đề "Coming soon", không bấm được), khối "MESSAGE PREVIEW" (nội dung tiếng Việt CỐ ĐỊNH theo BR-NOTI-07 — không qua `AppStrings.t()`, độc lập ngôn ngữ UI đang chọn), Cancel/Send now. Gọi qua `showSendInvoiceSheet()` (hàm `showModalBottomSheet`, theo đúng pattern `pick_contract_sheet.dart` đã có — KHÔNG phải 1 GoRoute, sửa lại B-02/B-04 đang push tới route `/bills/invoices/:id/send` chưa từng tồn tại thành gọi hàm sheet này).
- Số điện thoại Tenant lấy qua `invoice.contractId → contract.tenantId → tenant.phone` (Invoice model chỉ snapshot `tenantName`, không có phone) — nếu không tìm được, khoá nút "Send now" + hiện cảnh báo, không cho gửi.

Còn nợ: Zalo ZNS (chờ dungtv gửi đúng 5 giá trị OA), Brandname CSKH thật cho eSMS (nếu dungtv đăng ký sau), Push/FCM (ngoài phạm vi B-0x).

## 2026-09-14 (Đợt 36) — Bug thật: "Forgot password?" nhầm sang luồng Sign Up, code lại đúng S-04

Lúc test B-0x cần đăng nhập lại, phát hiện `login_screen.dart` cho nút "Forgot password?" `push('/signup')` — tái dùng nguyên màn Sign Up (hỏi "Full name", nút "Create account"). Comment cũ ghi lý do "Figma không có màn Forgot Password riêng" — đúng tại thời điểm code (trước khi Figma có S-04), nhưng SAI ở thời điểm hiện tại: dungtv gửi ảnh chụp Figma S-04 (3 frame, node `386:2282`/`388:2375`/`388:2386`) cho thấy đã có hẳn màn riêng từ trước, chỉ là chưa ai đối chiếu lại khi code màn Login. Đúng tinh thần "thấy bug phải fix luôn" dungtv nhắc lại lần này — dừng ngay việc test, pull Figma S-04 thật, code lại đúng màn riêng thay vì tiếp tục dùng luồng sai.

**Đã code**: `shared/forgot_password_screen.dart` (mới) — 3 bước riêng (Verify phone+OTP chung 1 trang → Reset password KHÔNG có field Full name → bottom sheet "Well Done!"/"Go to login"), tái dùng đúng `authRepository.sendOtp/verifyOtp/setPassword` (đã có sẵn comment ghi rõ dùng chung cho cả Sign Up lẫn Forgot Password), KHÔNG gọi `ensureUserProfile()` (tránh ghi đè `full_name`/`phone` của tài khoản đã có). Tách `SendOtpChip` (trước là private class trong `signup_screen.dart`) thành widget dùng chung `shared/send_otp_chip.dart`, dùng lại ở cả 2 màn. Route `/forgot-password` đăng ký mới, thêm vào danh sách miễn redirect ép `/login` (`atForgotPassword`, cùng lý do `atSignup` — `verifyOTP` tạo session TẠM trước khi đổi mật khẩu xong). "Go to login" ở bước 3 chủ động `signOut()` rồi `context.go('/login')` — khác Sign up "Get started" đi thẳng `/home`, vì đây là phiên đăng nhập TẠM do `verifyOTP` tạo ra để xác thực chủ tài khoản, không phải phiên người dùng chủ động muốn giữ.

**Verify trên máy ảo, dữ liệu thật**: chạy trọn luồng SĐT `0356123970` → OTP test code `123456` (đã cấu hình sẵn trong Supabase Auth cho số này) → đặt mật khẩu mới → "Well Done!" → "Go to login" → đăng nhập lại bằng đúng mật khẩu mới thành công. Chụp ảnh cả 3 bước so khớp Figma S-04 (đúng tiêu đề Top bar, đúng chỉ hiện 2 field New/Confirm password không có Full name, đúng icon/copy/nút bottom sheet).

Phát hiện phụ lúc build test: `flutter build apk` phải truyền đúng `--dart-define=SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY` (đọc từ `supabase/.env`) — thiếu 2 tham số này khiến MỌI lệnh gọi Supabase Auth (kể cả gửi OTP) báo lỗi chung chung "Could not send the verification code", từng gặp y hệt ở 2026-09-10 — không phải bug code, chỉ là quên tham số build, ghi lại lần nữa vì lặp lại.

## 2026-09-14 (Đợt 37) — Vá lỗ hổng thật: "Create & send all" chưa hề gửi SMS

dungtv hỏi trực tiếp: bấm "Create & send all" ở B-03 (15-20 phòng) có hiện màn chọn kênh SMS/Zalo rồi gửi thật cả lô không? Kiểm tra lại code phát hiện: **đang giả** — chỉ gọi `updateStatus(Sent)` thẳng vào DB, không hề gọi eSMS, không hiện màn chọn kênh nào. Đây là lỗ hổng thật do sót khi code B-03 (đợt trước chỉ tập trung verify phần preview/tạo hoá đơn, chưa test kỹ nhánh "send").

Hỏi dungtv hướng sửa — chọn: hiện 1 sheet chọn kênh **1 LẦN duy nhất** cho cả lô (không lặp lại preview nội dung từng hoá đơn như B-05, vì mỗi hoá đơn 1 nội dung khác nhau — làm 15-20 lần sẽ rất mất công), sau khi xác nhận thì gửi SMS thật tuần tự cho từng hoá đơn đã tạo.

**Đã code**:
- `core/invoice_message.dart` (mới) — tách `buildInvoiceSmsMessage()` từ `send_invoice_sheet.dart` thành hàm dùng chung (B-05 gửi đơn lẻ + B-03 gửi hàng loạt đều cần).
- `shared/channel_option.dart` (mới) — tách widget "option kênh" (SMS/Zalo/Both) từ private class trong `send_invoice_sheet.dart` thành widget dùng chung.
- `bills/batch_send_channel_sheet.dart` (mới) — sheet chọn kênh 1 lần cho cả lô, tái dùng `ChannelOption`, chỉ SMS bật (Zalo/Both "Coming soon" như B-05).
- `invoice_create_batch_screen.dart`: nút "Create & send all" giờ mở sheet trên trước — Cancel thì KHÔNG tạo gì cả; xác nhận thì mới bắt đầu vòng lặp tạo hoá đơn + gửi SMS thật (tra `contract → tenant.phone` cho từng hợp đồng, dựng nội dung qua `buildInvoiceSmsMessage`, gọi `InvoiceRepository.sendSms`) — lỗi gửi của 1 hoá đơn không chặn các hoá đơn còn lại, gom lại hiện snackbar cuối cùng.

Phát hiện thêm khi hỏi dungtv về QR code cho luồng gửi: kiểm tra lại toàn bộ Figma thật (không chỉ B-04/B-05) xác nhận **không có màn nào vẽ ảnh QR** dù `BR-BILL-10` yêu cầu — lệch tài liệu/Figma giống các lần trước. dungtv quyết định **không** thêm QR vào B-04 (chủ nhà tự xem QR trên máy mình không có ý nghĩa — QR chỉ có ích khi tới tay người thuê) — hoãn hẳn phần vẽ+gửi QR tới khi có Zalo OA (Zalo ZNS hỗ trợ đính kèm ảnh, SMS thì không thể).

## 2026-09-14 (Đợt 38) — Bắt đầu test toàn luồng nghiệp vụ quy mô lớn (5 nhà, ~87 phòng)

dungtv yêu cầu test toàn bộ luồng nghiệp vụ với dữ liệu quy mô thật: tối thiểu 5 nhà, mỗi nhà random tới ~30 phòng, có case hợp đồng nhiều phòng (thuê cho nhân viên), có case mời quản lý. Trước khi làm rõ 2 điểm:

1. **"Mỗi phòng 1-3 người ở cùng"** — kiểm tra lại `PRODUCT-OVERVIEW.md` mục 5.2 xác nhận "Nhiều Tenant đại diện trên 1 hợp đồng" là **NGOÀI PHẠM VI Phase 1** (ghi rõ, không phải thiếu sót). dungtv xác nhận bỏ qua chi tiết này — mỗi hợp đồng vẫn đúng 1 Tenant đại diện.
2. **Chiến lược tạo dữ liệu quy mô 150 phòng** — thoả thuận: bay tạo dữ liệu số lượng lớn qua DB trực tiếp cho nhanh, nhưng MỌI case nghiệp vụ quan trọng (hợp đồng nhiều phòng, gia hạn, kết thúc, mời quản lý, tạo/gửi hoá đơn...) vẫn bấm tay qua UI thật để bắt bug. dungtv cũng lưu ý gửi SMS tốn tiền thật — thoả thuận: "Save all as draft" cho cả lô lớn (miễn phí, test hiệu năng/độ ổn định) + "Create & send all" chỉ cho lô nhỏ 2-3 hợp đồng (test cơ chế gửi thật).

**Đã seed qua DB** (script Python sinh SQL, chạy qua Management API): mở rộng 2 nhà có sẵn (Nha trong So 2: 2→10 phòng, Nhà trọ của tao: 2→8 phòng) + 3 nhà mới (Chung cu mini Binh Thanh 33 phòng — dành riêng test hiệu năng batch, Nha tro Tan Binh 16 phòng, Day tro Thu Duc 20 phòng) = **87 phòng, 67 hợp đồng Active** (mix trạng thái Empty/UnderRepair/Occupied, mix billing method BY_READING/FLAT/NOT_BILLED, mix chu kỳ thu tiền 1/3 tháng, mỗi hợp đồng có đủ chỉ số MOVE_IN + PERIODIC hàng tháng tới 09/2026 với `previousReadingId` nối đúng chuỗi).

**Bug tự phát hiện lúc seed (do lỗi thao tác của tôi, không phải bug code)**: `tb_house` có trigger tự tạo dòng `tb_user_house_access(role='owner')` dùng `current_user_phone()` (đọc từ `auth.jwt()->>'phone'`) — khi insert qua Management API (không có JWT thật) phải tự set `request.jwt.claims` giả lập. Lần đầu set nhầm SĐT dạng nội địa `"0356123970"` thay vì đúng chuẩn E.164-không-dấu-cộng `"84356123970"` mà **toàn bộ app dùng nhất quán** (`AuthRepository.normalizePhoneForDb`, JWT claim thật của Supabase Auth). Hậu quả: 3 nhà mới tạo xong nhưng **biến mất khỏi Home** (RLS lọc đúng theo policy, chỉ là không khớp SĐT) — không có lỗi/exception nào hiện ra, chỉ đơn giản là danh sách thiếu, dễ nhầm tưởng là bug thật. Đã tự phát hiện qua so sánh RLS-scoped query (`SET ROLE authenticated`) với truy vấn superuser, sửa lại `UPDATE ... SET phone='84356123970'` cho cả `tb_user_house_access` lẫn `recorded_by_phone` của các chỉ số đã seed (cũng bị seed sai cùng lỗi). Verify lại: Home hiện đúng "5 houses · 67/87 rooms occupied".

**Bài học ghi lại cho các lần seed dữ liệu qua DB sau này**: LUÔN dùng đúng định dạng SĐT chuẩn E.164-không-dấu-cộng (`84xxxxxxxxx`) khi giả lập `request.jwt.claims`/ghi trực tiếp `phone` vào `tb_user_house_access`/`recorded_by_phone` — sai định dạng không gây lỗi SQL nào cả (vẫn insert được bình thường), chỉ âm thầm làm RLS lọc rớt hết, rất dễ bị hiểu nhầm thành bug ứng dụng.

## 2026-09-14 (Đợt 39) — B-03: chuyển hẳn "Create & send all"/"Save all as draft" sang backend xử lý 1 lần

Test hiệu năng ở Đợt 38 (batch 28 hợp đồng) lộ ra rủi ro thật: luồng cũ để **app tự lặp gọi từng hợp đồng** (`generateSingle` + `sendSms` cho từng contract, dù đã chia lô song song 6-1) — nếu người dùng khoá màn hình/chuyển app giữa chừng lúc Android tạm dừng tiến trình nền, lô có thể tạo dở dang, không cách nào tự hoàn tất. dungtv hỏi thẳng "sao việc gửi tin này không phải backend làm" — đúng vấn đề. Đưa ra 2 lựa chọn: (a) giữ app tự lặp, đổi UI có % tiến độ chính xác nhưng vẫn có rủi ro trên; (b) chuyển hẳn cả việc tạo+gửi sang 1 lệnh gọi Edge Function duy nhất, chỉ mất khả năng hiện % tiến độ chính xác (chỉ còn spinner không xác định). **dungtv chọn (b) — chấp nhận đánh đổi.**

**Đã làm:**
- `supabase/functions/generate-invoice/index.ts` — thêm `mode: "batchSend"`: nhận `houseId` + `contractIds[]` + `send: bool`, tự lặp `generateSingleInvoice()` (chia lô song song `CONCURRENCY = 6` như `previewBatch`) rồi gửi SMS thật qua `sendSmsViaEsms()` nếu `send=true`, trả về `{ created, sent, errors[] }` gộp 1 lần. Trích 2 hàm dùng chung `_shared/esms.ts` (từ `send-notification`) và `_shared/invoice_message.ts` (bản TS song song `core/invoice_message.dart`) để không lặp code giữa gửi đơn lẻ (B-05) và gửi hàng loạt (B-03).
- `src/lib/data/invoice_repository.dart` — thêm `batchCreateAndSend()` gọi `mode: "batchSend"` 1 lần duy nhất, trả `BatchSendResult`.
- `src/lib/bills/invoice_create_batch_screen.dart` — bỏ hẳn vòng lặp client-side (`Future.wait` theo lô, `_completedCount`/`_totalToProcess`, `LinearProgressIndicator` xác định %) đã làm ở Đợt 38; thay bằng 1 lệnh `await batchCreateAndSend(...)` duy nhất + overlay spinner không xác định + text tĩnh "Đang tạo & gửi hoá đơn, vui lòng đợi..." — vẫn giữ khoá toàn bộ điều khiển tương tác (Back, chọn hợp đồng, đổi kỳ, 2 nút hành động) trong lúc chờ.

**Bug thật phát hiện khi live-test lại (không phải do đổi kiến trúc trên, mà lộ ra khi verify)**: sau khi bấm "Create & send all" (chọn 3 hợp đồng B.3/B.6/B.8 — batch nhỏ để test gửi SMS thật theo đúng giới hạn chi phí ở Đợt 38), backend tạo + gửi đúng cả 3 (verify trực tiếp qua REST API bằng JWT thật: cả 3 hoá đơn `status: "Sent"`, `sent_at` có giá trị) — nhưng **màn Bills List (B-01) vẫn hiện "Draft — chưa tạo"** cho các phòng đó, kể cả sau khi chuyển tab qua lại. Nguyên nhân: `billsHouseGroupsProvider` (đứng sau B-01/T-05) đọc hoá đơn qua 1 provider con khác — `contractInvoicesProvider(contractId)` (family theo từng hợp đồng) — mà `_submit()` chỉ `ref.invalidate(billsHouseGroupsProvider)` (invalidate provider CHA), không invalidate provider CON theo từng `contractId` vừa xử lý. Riverpod re-run provider cha nhưng provider con vẫn trả giá trị đã cache cũ, nên UI im lặng hiện sai — không có lỗi/exception nào. Cùng lỗi này cũng có ở `invoice_detail_screen.dart` (B-04: Mark as collected/Undo/Resend/Delete draft) và `send_invoice_sheet.dart` (B-05: gửi/gửi lại) — sửa cả 3 chỗ, thêm `ref.invalidate(contractInvoicesProvider(contractId))` đúng theo từng hợp đồng bị ảnh hưởng trước khi invalidate provider cha. Verify lại: chọn thêm B.4 "Save all as draft" (miễn phí), Bills List cập nhật ngay "Draft — chưa gửi" không cần chuyển tab/khởi động lại app.

**Bài học**: khi 1 `FutureProvider` (cha) đọc dữ liệu qua `ref.watch()` một `FutureProvider.family` khác (con), chỉ invalidate provider cha là KHÔNG đủ để lấy dữ liệu mới — Riverpod re-run cha nhưng provider con vẫn trả về giá trị đã cache nếu bản thân nó chưa bị invalidate. Bất kỳ hành động nào sửa hoá đơn của 1 hợp đồng cụ thể đều phải invalidate cả `contractInvoicesProvider(contractId)` tương ứng, không chỉ các provider tổng hợp phía trên nó.

## 2026-09-15 (Đợt 40) — S-03 Notification Center: nối dữ liệu thật (3 loại tức thời), vá 1 bug thật + 1 crash thật

dungtv yêu cầu làm nốt phần thông báo trong app — trước đó S-03 chỉ là UI giả (dữ liệu cứng viết sẵn), chưa bảng lưu thật, chưa nơi nào trong app thực sự tạo thông báo. Rà lại `BUSINESS-RULES.md` mục 5 (BR-NOTI-01→07): 3 loại **tức thời** (01 hoá đơn tạo & gửi, 03 đánh dấu đã thu tiền, 06 được mời làm quản lý) đã có sẵn chỗ kích hoạt trong code hiện tại; 3 loại còn lại (02 nhắc hạn thanh toán, 04 hợp đồng sắp hết hạn, 05 đến hạn ghi chỉ số) đều **chạy theo lịch** (cron) — cần 1 cơ chế hạ tầng riêng, để đợt sau. dungtv xác nhận làm 3 loại tức thời trước.

**Câu hỏi làm rõ trước khi code (dungtv hỏi, quan trọng — tránh hiểu nhầm phạm vi):**
1. "Sao lại nhắc chủ nhà, đâu phải chủ nhà trả tiền" (về BR-NOTI-02) — làm rõ: thông báo cho chủ nhà không phải "nhắc trả tiền" mà là "báo hoá đơn X vẫn `Sent` chưa `Collected` gần/quá hạn" để chủ nhà chủ động theo dõi — Tenant mới là bên nhận SMS/Zalo nhắc trả tiền thật (BR-PAY-04).
2. "Supabase có Realtime, cần chú ý app đóng vẫn phải nhận được, bấm vào dẫn màn nào" — làm rõ: **Supabase Realtime ≠ push notification** — Realtime chỉ đồng bộ dữ liệu khi app đang MỞ, không đánh thức app đã đóng, không hiện ở màn khoá máy. Để nhận được khi app đã đóng bắt buộc phải qua FCM/APNs (Firebase) — dungtv xác nhận muốn làm FCM luôn, đã gửi thông tin cần thiết (tạo Firebase project + `google-services.json` cho Android trước, iOS để sau do Apple Developer account đang chờ duyệt) — **phần FCM thật chưa làm trong đợt này**, chỉ mới xong phần lưu + hiện trong app. Đích đến khi bấm vào thông báo lấy đúng theo `SCREEN-SPEC.md` dòng mô tả S-03 (không tự đoán): hoá đơn mới/đã thu tiền → B-04; được mời quản lý → P-05.

**Đã làm:**
- Migration `20260915090000_tb_notification.sql` — bảng mới `tb_notification` (`recipient_phone`, `house_id`, `type`, `payload` jsonb, `target_invoice_id`, `read_at`) + RLS (chỉ thấy/tự đánh dấu đọc đúng dòng của mình qua `current_user_phone()`). Lưu `type` + `payload` có cấu trúc, KHÔNG lưu sẵn câu chữ dựng thành title/body — vì nội dung hiển thị phải theo đúng ngôn ngữ UI người xem đang chọn (EN/VI/KO, độc lập với BR-NOTI-07 chỉ áp dụng tiếng Việt cố định cho SMS/Zalo gửi Tenant) — Flutter tự dựng câu qua `AppStrings.t()` tại thời điểm hiển thị.
- `supabase/functions/_shared/notifications.ts` (mới) — `fanOutNotification()` dùng chung, ghi 1 dòng cho mỗi SĐT có quyền trên 1 nhà.
- `supabase/functions/generate-invoice/index.ts` — gọi `fanOutNotification()` ngay trong `generateSingleInvoice()` (dùng chung cho mọi mode: single/batch/batchSend) sau khi insert hoá đơn thành công — 1 chỗ, phủ hết mọi đường tạo hoá đơn.
- `supabase/functions/create-notification/index.ts` (mới) — 1 endpoint chung cho 2 loại còn lại (chạy từ client, không qua Edge Function nào khác sẵn có): `invoice_collected` (loại trừ chính người vừa bấm) và `manager_invited`.
- Flutter: `data/models/app_notification.dart`, `data/notification_repository.dart`, providers `notificationsProvider`/`unreadNotificationCountProvider`; nối gọi ở `invoice_create_batch_screen.dart`, `invoice_create_single_screen.dart` (BR-NOTI-01), `invoice_detail_screen.dart` (BR-NOTI-03), `user_repository.dart::saveManager()` (BR-NOTI-06). `TopBarBellButton` thêm chấm đỏ số chưa đọc. `notification_center_screen.dart` viết lại hoàn toàn từ UI giả sang dữ liệu thật, tap → đánh dấu đã đọc + điều hướng đúng theo `SCREEN-SPEC.md`.

**Bug thật #1 (cùng họ lỗi Đợt 39 — cache provider cha/con)**: sau khi tạo hoá đơn mới, chuông ở Home KHÔNG hiện chấm đỏ dù backend đã ghi đúng thông báo vào `tb_notification` (verify trực tiếp qua REST API bằng JWT thật). Nguyên nhân: `unreadNotificationCountProvider` đọc qua `notificationsProvider.future`, mà 2 màn tạo hoá đơn (B-02/B-03) không hề invalidate `notificationsProvider` sau khi tạo thành công — y hệt bài học Đợt 39, chỉ khác provider. Đã thêm `ref.invalidate(notificationsProvider)` ở cả 2 màn + B-04 (sau khi gọi `notifyInvoiceCollected`).

**Crash thật #2 (nghiêm trọng hơn — làm chết cả app, không chỉ sai UI)**: bấm vào 1 thông báo trong S-03 → app crash với `Failed assertion: '!keyReservation.contains(key)'` tại `navigator.dart`. Nguyên nhân: `/notifications` là 1 `GoRoute` nằm **ngoài** `StatefulShellRoute` (route gốc, không thuộc tab nào), trong khi 2 đích đến (`/bills/invoices/:id`, `/profile/managers`) đều nằm **bên trong** 1 nhánh shell (mỗi tab giữ Navigator riêng, luôn tồn tại suốt vòng đời app nhờ `IndexedStack`). Gọi `context.push()` từ ngoài shell vào 1 route bên trong shell khiến go_router dựng thêm 1 bản shell/branch thứ 2 chồng lên bản gốc đang có sẵn, đụng đúng `GlobalKey` của Navigator branch đó — lỗi đã biết của go_router (không phải bug tự viết mới). Sửa bằng `context.go()` thay vì `push()` ở `notification_center_screen.dart::_onTap()` — `go()` thay thế toàn bộ stack, dựng lại đúng 1 bản duy nhất, không chồng lấn. Verify lại: bấm thông báo → mở đúng B-04, bấm Back → về đúng Bills List, không crash.

**Bài học**: `context.push()` một route nằm **bên trong** `StatefulShellRoute` (thuộc về 1 tab cụ thể) từ 1 màn hình nằm **ngoài** shell đó (route gốc, như S-03) có rủi ro crash `GlobalKey` collision — vì go_router phải dựng thêm 1 bản sao của toàn bộ shell/branch trong khi bản gốc vẫn đang tồn tại. Luôn dùng `context.go()` khi điều hướng từ 1 route ngoài shell vào 1 route bên trong shell.

## 2026-09-15 (Đợt 41) — Chuẩn bị hạ tầng FCM (push) + Zalo ZNS, nhận 5/6 giá trị Zalo OA thật

dungtv gửi được 5 giá trị Zalo OA thật: OA ID, App ID, App Secret, Access token, Refresh token — thiếu Template ID (mục 6, đang chờ Zalo duyệt nội dung mẫu). dungtv cũng hỏi 1 mục ("miền townsoftvina.com") không rõ có cần không, và yêu cầu chuẩn bị sẵn code cho FCM để khi có Firebase project thật chỉ cần cắm secret vào là chạy.

**Trả lời câu hỏi "mục 4 — miền townsoftvina.com"**: mục này (thường gọi "OA domain"/"Callback URL") chỉ cần khi làm **luồng OAuth "Đăng nhập bằng Zalo"** trên web (Zalo redirect người dùng về đúng domain đã đăng ký sau khi họ đồng ý cấp quyền). App này **không** làm luồng đó — chỉ gửi tin ZNS một chiều từ server dùng access token đã có sẵn (dungtv đã tự lấy access+refresh token qua Zalo Developer Console) — nên **không cần** domain này. Có thể bỏ qua mục 4.

**Đã chuẩn bị (chưa bật tính năng nào, chỉ dựng hạ tầng):**
- Set 3 secret tĩnh qua `supabase secrets set`: `ZALO_OA_ID`, `ZALO_APP_ID`, `ZALO_APP_SECRET`.
- Migration `20260915100000_tb_zalo_token.sql` — bảng mới `tb_zalo_token` (1 dòng `id='default'`) lưu access+refresh token Zalo — KHÔNG lưu tĩnh trong Secrets vì access token Zalo hết hạn sau vài giờ, và mỗi lần làm mới bằng refresh token thì Zalo trả về **cả 2 giá trị mới** (refresh token cũ mất hiệu lực ngay) — cần 1 chỗ ghi lại được. Đã seed sẵn cặp access/refresh token dungtv gửi, đặt `expires_at` đã qua hạn để lần gọi thật đầu tiên tự làm mới ngay (an toàn hơn tin vào thời hạn dungtv đã giữ token bao lâu trước khi gửi).
- `supabase/functions/_shared/zalo.ts` (mới) — `sendZns()` + `getValidZaloAccessToken()` tự làm mới token khi gần hết hạn qua `oauth.zaloapp.com/v4/oa/access_token`. **Chưa gọi ở đâu trong app** — cần `templateId` thật (mục 6) mới bật được "Gửi qua Zalo" ở B-03/B-05 (hiện vẫn khoá "Coming soon" như cũ).
- `supabase/functions/_shared/fcm.ts` (mới) — `sendFcmPush()` dùng FCM HTTP v1 API (OAuth2 qua service account, tự ký JWT RS256 bằng `crypto.subtle`, không cần thư viện ngoài). Đọc secret `FCM_SERVICE_ACCOUNT` (nội dung file JSON service account dungtv sẽ gửi) — chưa có secret thì trả cảnh báo "chưa cấu hình", không throw, không chặn phần khác.
- `supabase/functions/send-notification/index.ts` — nối `sendFcmPush()` thay cho TODO cũ, chỉ gửi cho token `platform='android'` (iOS/APNs vẫn TODO riêng, cần Apple Developer account — dungtv đang chờ duyệt). Deploy + test thật qua curl: `push: {recipientCount: 0, sent: 0}` (đúng, vì app chưa có `firebase_messaging` nên chưa đăng ký device token nào) — không lỗi, không ảnh hưởng SMS Tenant.

**Còn thiếu để bật thật:**
- FCM: dungtv tạo Firebase project → thêm app Android (package `com.townsoftvina.biztown.rent_manager`) → gửi `google-services.json` (đặt vào `android/app/`) + tạo Service Account key (Project Settings → Service accounts) → gửi nội dung JSON để set secret `FCM_SERVICE_ACCOUNT`. Phía Flutter còn cần thêm `firebase_core`/`firebase_messaging` vào `pubspec.yaml` + đăng ký device token vào `tb_device_token` lúc đăng nhập — CHƯA làm (cần `google-services.json` mới build được, tránh phá build hiện tại).
- Zalo: chờ Template ID (mục 6) từ Zalo duyệt, rồi nối `sendZns()` vào `send-notification`/`generate-invoice` (batchSend) + mở khoá lựa chọn "Zalo"/"Both" ở `channel_option.dart`.

## 2026-09-15 (Đợt 42) — Hoàn tất kế hoạch test lớn: Renew/Amend hợp đồng, Kết thúc hợp đồng (2 case), mời quản lý (2 người) + verify RLS

Tiếp tục nốt phần test nghiệp vụ lớn còn nợ từ Đợt 38 — đều thao tác qua UI thật trên `emulator-5554`, không phải chỉ query DB.

**T-07 Renew/Amend hợp đồng (B.3, Tran Duc Long)**: Renew tăng tiền thuê 2.500.000 → 2.700.000 — đúng tự nối tiếp ngày bắt đầu từ ngày kết thúc bản cũ (18/12/2026), tạo v2, khối "CHANGED VS V1" hiện đúng diff. Amend sau đó (start date mặc định = HÔM NAY, khác Renew nối tiếp ngày cũ — đúng ý nghĩa "sửa giữa kỳ") đổi payment due day 10→15, tạo v3, "CHANGED VS V2" đúng diff. Không phát hiện bug.

**T-09 Kết thúc hợp đồng — case "còn nợ"** (B.3, sau khi đã Renew/Amend ở trên, có sẵn hoá đơn quá hạn T9): điền chỉ số move-out, hệ thống tính đúng "Tenant still owes 3.200.000" (= 2.500.000 cọc − 5.700.000 chưa thu). Bấm xác nhận → hợp đồng chuyển `Ended`, phòng về `Empty`.

**T-09 Kết thúc hợp đồng — case "hoàn tiền"** (B.5, Dang Minh Duy, chọn riêng 1 hợp đồng KHÔNG có hoá đơn chưa thu để đảm bảo đúng case sạch): "No outstanding invoices" hiện đúng, "Refund to tenant 2.500.000" (= đúng tiền cọc). Thêm khấu trừ hư hỏng 300.000 ("Broken window") → tự tính lại đúng "Refund to tenant 2.200.000". Không phát hiện bug ở phần tính toán.

**Tự gây lỗi (không phải bug có sẵn) lúc test case "còn nợ", đã tự sửa lại đúng ngay sau khi dungtv chỉ ra**: lúc live-test, thấy dialog xác nhận cuối "End contract and move-out?" có nút hành động chính ghi "Delete" — chỉ dựa vào suy luận ngữ nghĩa trong code hiện tại (so với 3 chỗ khác cũng dùng chung `confirmLabel: AppStrings.t('common.delete')` cho xoá bản ghi thật), Claude đổi thành "Confirm move-out" mà **không kiểm tra lại Figma/lịch sử trước** — hoá ra đây chính là quyết định ĐÃ CHỐT đúng theo Figma từ trước (xem Đợt liên quan ngày 2026-09-14, dungtv từng gửi ảnh chụp Figma thật node `400:2783` xác nhận nút này phải ghi "Delete", đã sửa đúng 1 lần trước đó). Tức là lượt "sửa" của Claude ở đây thực chất là **tự đảo ngược 1 quyết định đã verify bằng Figma thật**, không phải phát hiện bug mới. dungtv chỉ ra ngay, Claude sửa lại đúng thành "Delete" như cũ. Bài học + quy tắc mới (rà lại changelog/DECISIONS.md đầu mỗi phiên chat mới trước khi đổi bất kỳ thứ gì đã khớp Figma) đã lưu vào memory.

**P-06 Mời 2 quản lý mới qua UI thật**: "Nguyen Thi Manager1" (SĐT `0977000111`) → cấp quyền "Chung cu mini Binh Thanh"; "Tran Van Manager2" (SĐT `0977000222`) → cấp quyền "Nha tro Tan Binh". Form tự khoá (xám, không tick được) nhà đã có 1 quản lý active khác — đúng rule "1 quản lý active/nhà" đã quyết định từ trước. Verify BR-NOTI-06: `tb_notification` ghi đúng dòng `manager_invited` cho từng SĐT với đúng `houseName`.

**Verify RLS-isolation thật** (mô phỏng JWT qua `SET ROLE authenticated; SET request.jwt.claims`, không dùng superuser bypass — đúng phương pháp đã rút kinh nghiệm từ Đợt 38): SĐT `84977000111` chỉ `SELECT name FROM tb_house` (không where) ra đúng 1 dòng "Chung cu mini Binh Thanh"; SĐT `84977000222` ra đúng 1 dòng "Nha tro Tan Binh" — xác nhận RLS cách ly đúng, quản lý mới không thấy được 4 nhà còn lại của chủ nhà.

**Kết luận**: toàn bộ kế hoạch test nghiệp vụ lớn (Đợt 38 khởi động) đã hoàn tất — 5 nhà/~87 phòng, hợp đồng nhiều phòng, batch tạo/gửi hoá đơn ở quy mô, renew/amend/end contract (cả 2 case), mời quản lý + RLS. Không phát hiện bug thật mới nào ở phần tính toán/nghiệp vụ — chỉ có 1 lần Claude tự gây lỗi (đảo ngược nhãn nút dialog đã verify Figma từ trước) rồi tự sửa lại đúng ngay khi dungtv chỉ ra, xem chi tiết + bài học ở đoạn trên.

## 2026-09-15 (Đợt 43) — S-03: nối Supabase Realtime, chuông/danh sách tự cập nhật kể cả khi người khác tạo thông báo

dungtv hỏi tiếp: hiện tại có thông báo mới có phải load lại app mới thấy chấm đỏ không? Trả lời đúng thực trạng lúc đó: nếu CHÍNH người dùng vừa thao tác (tạo hoá đơn, đánh dấu thu tiền...) thì tự cập nhật ngay (đã tự invalidate provider) — nhưng nếu thông báo đến từ NGƯỜI KHÁC (quản lý khác/thiết bị khác) trong lúc app đang mở sẵn, sẽ KHÔNG tự hiện, kể cả chuyển tab qua lại, phải tắt hẳn app mở lại mới thấy. dungtv: "làm luôn đi chứ thông báo mà không hiện luôn thì cùi lắm".

**Đã làm**:
- Migration `20260915110000_tb_notification_realtime.sql` — `alter publication supabase_realtime add table tb_notification;`. RLS SELECT có sẵn (`recipient_phone = current_user_phone()`) tự áp dụng cho luồng Realtime, không cần policy/filter riêng.
- `NotificationRepository.watch()` (mới, thay `list()` — đã xoá vì không còn ai gọi) — dùng `supabase.from('tb_notification').stream(primaryKey: ['id'])`.
- `core/providers.dart` — đổi `notificationsProvider` từ `FutureProvider` sang `StreamProvider` (tự đẩy dữ liệu mới ngay khi có INSERT/UPDATE, không cần gọi lại); `unreadNotificationCountProvider` đổi từ `FutureProvider<int>` thành `Provider<int>` thuần (derive trực tiếp từ stream, không async riêng nữa).
- Dọn dẹp: bỏ toàn bộ `ref.invalidate(notificationsProvider)` thủ công đã thêm ở Đợt 40 (B-02/B-03/B-04/S-03 markAsRead) — không còn cần thiết vì Realtime tự đẩy dữ liệu bất kể ai/đâu gây ra thay đổi, kể cả thao tác của chính người dùng.

**Verify thật** (không phải suy đoán): mở app, đứng yên ở Home (không đụng gì) → dùng Management API chèn thẳng 1 dòng `tb_notification` giả lập "hệ thống/người khác vừa tạo thông báo" (không qua app) → chấm đỏ tự hiện ngay trên chuông, không cần chạm màn hình/chuyển tab/tắt mở lại. Mở Notification Center, nội dung hiện đúng payload vừa chèn, "Just now". Bấm vào → tự đánh dấu đã đọc, "0 unread" cập nhật ngay (UPDATE cũng qua đúng kênh Realtime, không cần invalidate tay).

Lưu ý: đây vẫn là Realtime (chỉ hoạt động khi app đang MỞ và có mạng), không phải push hệ thống ra ngoài màn khoá máy — phần đó vẫn chờ FCM (Android, khi có Apple Dev sẽ làm cả iOS cùng lúc theo yêu cầu dungtv) + Zalo ZNS (chờ Template ID).

## 2026-09-15 (Đợt 44) — Vá lỗi hiệu năng thật: Bills List (B-01) tải rất chậm ở quy mô lớn

dungtv phản hồi trực tiếp: "sao load cái bill mà chậm thế nhỉ xoay mãi". Rà lại `billsHouseGroupsProvider` (đứng sau B-01) phát hiện đúng lỗi **N+1 query** kinh điển: với MỖI hợp đồng Active (dữ liệu test hiện có ~67 hợp đồng), code gọi RIÊNG 2 lượt API tuần tự bên trong vòng lặp — `tenantProvider(contract.tenantId)` (lấy 1 tenant) và `contractInvoicesProvider(contract.id)` (lấy hoá đơn của 1 hợp đồng) — tức tới 134 lượt gọi mạng nối tiếp nhau chỉ để tải 1 màn hình, dù phần còn lại của cùng hàm này (version/room/house) đã làm ĐÚNG theo lối gộp lại 1 lượt gọi (`listVersionsByIds`, `roomIdsByContractIds`, `listByIds`...) — chỉ 2 chỗ tenant/invoice bị sót lại kiểu cũ.

**Đã sửa**: bỏ hẳn 2 lượt gọi trong vòng lặp — thay bằng dùng lại đúng 2 provider gộp sẵn có (`tenantsProvider`, `invoicesProvider`, đã tồn tại và dùng ở nơi khác), tự nhóm theo `tenantId`/`contractId` trong bộ nhớ. `buildInvoiceScheduleChips()` không phụ thuộc thứ tự input (tự dựng `Map<DateTime, Invoice>` theo `periodStart`) nên gộp dữ liệu không ảnh hưởng kết quả.

**Nhân tiện rà thêm 1 chỗ cùng họ lỗi** (nhẹ hơn, đã tự chạy song song bằng `Future.wait` nên không quá chậm nhưng vẫn N lượt gọi): `contractListProvider` (đứng sau tab Tenant & Contract, T-02) gọi `getById()` riêng cho từng tenantId duy nhất. Đổi sang dùng lại `tenantsProvider` cho nhất quán — giảm còn đúng 1 lượt gọi.

**Verify thật bằng đo thời gian** (chụp màn hình liên tiếp mỗi 0.5s ngay sau khi bấm tab Bills, đối chiếu timestamp): tải xong hoàn toàn trong khoảng ~2 giây — trước đó cùng màn hình này từng phải đợi 5-10+ giây (đã tự trải nghiệm nhiều lần trong lúc test suốt phiên làm việc). `flutter analyze` sạch.

**Bài học**: khi 1 hàm cần dữ liệu PHỤ (tenant, hoá đơn...) cho một tập hợp N bản ghi, luôn gộp lại thành 1 lượt gọi "lấy tất cả trong phạm vi" rồi tự nhóm trong bộ nhớ (dùng `Map` theo khoá) — không gọi lại provider/repository theo từng phần tử bên trong vòng lặp, kể cả khi đã dùng `Future.wait` để chạy song song (vẫn tốn N lượt round-trip mạng, chỉ đỡ chậm hơn gọi tuần tự chứ không giải quyết gốc vấn đề).

## 2026-09-15 (Đợt 45) — Rà toàn bộ app tìm N+1 query khác + kiểm tra index database + verify sống từng màn

dungtv, sau khi thấy vá Bills List (Đợt 44), hỏi tiếp: sửa vậy có ảnh hưởng gì không (nhắc phải test lại mỗi lần sửa), màn Tenant cũng có vẻ chậm, cần rà toàn bộ app, và kiểm tra database có đánh index hợp lý chưa — "app này không phải quá lớn mà dữ liệu chậm thì trải nghiệm cực kỳ tệ".

**Rà toàn bộ `providers.dart`** (đọc hết từng provider, không chỉ chỗ dungtv chỉ ra) — phát hiện thêm đúng 1 chỗ N+1 nghiêm trọng khác:

- **`houseMeterEntriesProvider`** (H-06 Record Monthly Reading) — với MỖI phòng × MỖI loại tiện ích (điện/nước), gọi RIÊNG tới 3 lượt API tuần tự (`periodicForPeriod` + `byId`/`latestForRoom`) — nhà 33 phòng = tới ~132 lượt gọi mạng nối tiếp, cùng họ lỗi hệt Bills List. Sửa: thêm `ReadingRepository.historyForRooms()` (lấy TOÀN BỘ lịch sử chỉ số của CẢ NHÀ cho 1 loại tiện ích trong 1 lượt gọi), tự khớp lại "kỳ này đã ghi chưa"/"chỉ số trước" trong bộ nhớ — giảm còn đúng 2 lượt gọi (1 điện + 1 nước) bất kể nhà có bao nhiêu phòng.
- Rà thêm mọi repository khác (`room_repository`, `contract_repository`, `house_repository`, `user_repository`, `invoice_repository`, `tenant_repository`) tìm vòng lặp có `await` bên trong — không phát hiện thêm chỗ nào khác ngoài 3 chỗ đã sửa (Bills List, Contract list, Meter Entries) và 1 chỗ chấp nhận được (`UserRepository.saveManager()` lặp theo số nhà được TICK trong 1 lần submit form — quy mô nhỏ, do người dùng chọn tay, không phải danh sách toàn hệ thống).

**Kiểm tra index database thật** (không chỉ đọc migration mà còn `pg_indexes` trực tiếp trên Supabase): mọi cột khoá ngoại đang thực sự dùng trong `.eq()`/`.inFilter()` ở code (house_id, contract_id, tenant_id, room_id, phone, recipient_phone) đều ĐÃ có index — kể cả 1 trường hợp tinh tế: `tb_contract_room` tưởng thiếu index `room_id`, nhưng thực ra có UNIQUE PARTIAL INDEX `one_active_contract_per_room (room_id) WHERE is_active` — vừa là ràng buộc nghiệp vụ (1 phòng chỉ 1 hợp đồng Active) vừa tự đóng vai trò index cho đúng truy vấn `activeContractIdForRoom()` đang dùng (luôn kèm `is_active = true`). Không cần thêm index nào — root cause của hiện tượng chậm 100% nằm ở tầng ứng dụng (N+1 query trong Dart), không phải thiếu index. Kiểm tra thêm `pg_stat_user_tables`: bảng lớn nhất hiện chỉ ~405 dòng (readings) — ở quy mô này Postgres tự chọn seq scan cho nhiều truy vấn dù có index (nhanh hơn với bảng nhỏ), nên index hiện có mang tính "đúng đắn khi dữ liệu lớn lên" chứ chưa phải yếu tố quyết định tốc độ ở quy mô test hiện tại.

**Verify sống từng màn sau khi build lại APK** (đo bằng chụp màn hình liên tiếp 0.5s + timestamp, đúng yêu cầu "test lại mỗi lần sửa"):
- Bills List: ~2s (giữ nguyên từ Đợt 44).
- Tenant tab — sub-tab "Tenants": ~1.4s. Sub-tab "Contracts": ~2s.
- Home tab: gần như tức thời.
- H-06 Record Monthly Reading (nhà 33 phòng, chỗ vừa sửa): ~2s — kiểm tra thêm ĐÚNG dữ liệu hiển thị (không chỉ nhanh mà còn phải đúng): "20/33 rooms recorded", Previous/Current/Usage của từng phòng khớp đúng chuỗi chỉ số cũ (VD phòng 333: Previous 246 → Current 267 → Usage 21 kWh) — xác nhận việc gộp query không làm sai lệch dữ liệu.

## 2026-09-16 (Đợt 46) — Bật thật FCM Push (Android), verify end-to-end bằng push thật

dungtv tạo xong Firebase project (bắt đầu từ Đợt 41 mới chỉ chuẩn bị hạ tầng, chờ 3 file này), gửi đủ:
1. `google-services.json` (Android) — `applicationId` khớp đúng `com.townsoftvina.biztown.rent_manager`.
2. `GoogleService-Info.plist` (iOS) — `BUNDLE_ID` khớp đúng `com.townsoftvina.biztown.rentManager` (đã đối chiếu với `PRODUCT_BUNDLE_IDENTIFIER` trong `project.pbxproj` trước khi copy).
3. Service account JSON (`firebase-adminsdk-fbsvc@...`) — dùng để ký JWT gọi FCM HTTP v1 API từ Edge Function (`_shared/fcm.ts`, code đã có sẵn từ Đợt 41).

**Việc dùng để bật thật (không chỉ chuẩn bị nữa)**:
- Copy 2 file config vào đúng chỗ Flutter cần (`android/app/`, `ios/Runner/`).
- `supabase secrets set FCM_SERVICE_ACCOUNT=<nội dung file JSON>` — không commit file JSON gốc lên git (đã xoá khỏi vùng làm việc sau khi set xong).
- Thêm `firebase_core`/`firebase_messaging` vào `pubspec.yaml`; wire plugin Gradle `com.google.gms.google-services` ở `android/settings.gradle.kts` + `android/app/build.gradle.kts` (dự án Flutter mới dùng Swift Package Manager cho iOS, không có Podfile, nên phần iOS không cần sửa gì thêm ở bước này).
- `ios/Runner/Info.plist` thêm `UIBackgroundModes: remote-notification`. KHÔNG tự sửa tay phần "Push Notifications" capability (file entitlements + ký số) — để dungtv tự bật qua Xcode "Signing & Capabilities" khi cần build iOS thật, đúng bài học từ lúc build iOS trước (sửa tay file ký số dễ vỡ, cần đúng Apple ID/Developer Portal của dungtv).
- `data/push_repository.dart` (mới): `registerDeviceToken()` xin quyền (`requestPermission()`) + lấy token (`getToken()`) + `upsert` vào `tb_device_token` (bảng đã có sẵn từ schema V3, trước đó chưa ai ghi vào). Gọi ở 2 chỗ: Splash (khi đã có session sẵn) và Login (ngay sau khi đăng nhập thành công) — đều gọi kiểu "bắn rồi quên" (`unawaited`), không `await` để không làm chậm điều hướng. Cả hai lệnh gọi tới Google (`requestPermission`, `getToken`) đều bọc `.timeout(15s)` — phòng trường hợp máy/mạng không tới được backend Google thì cũng không treo Future vô thời hạn. Mọi lỗi bị nuốt (`catch` + `debugPrint`) vì Push không phải luồng lõi, không được phép chặn đăng nhập/mở app.

**Bug thật tự phát hiện + tự sửa (không phải dungtv báo)**: bản đầu tiên đặt `Firebase.initializeApp()` (rồi gọi `pushRepository...`) TRƯỚC `initSupabase()` trong `main.dart`. `pushRepository` là biến top-level (`final pushRepository = PushRepository(supabase);`, giống cách khai báo mọi repository khác trong app) — dòng này đọc `supabase` (getter `Supabase.instance.client`) ngay khi Dart lần đầu chạm tới biến, tức là ngay lúc gọi `pushRepository.listenTokenRefresh()`. Vì lúc đó `initSupabase()` (nằm sau) chưa chạy, code crash `Failed assertion: '_instance._isInitialized': You must initialize the supabase instance before calling Supabase.instance`. Phát hiện ngay trong lần build+cài thử đầu tiên trên `emulator-5554` (đọc logcat thật), sửa bằng cách đổi thứ tự: `initSupabase()` chạy xong trước, khối `Firebase.initializeApp()` chuyển xuống sau.

**Verify thật, không chỉ "code xong không lỗi"** (toàn bộ trên `emulator-5554`, build APK debug **có đúng flag `--dart-define=SUPABASE_URL=...` + `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`** — lưu ý: quên 2 flag này app vẫn build/chạy được nhưng không nối đúng backend thật, dễ hiểu lầm thành "sai mật khẩu" khi test đăng nhập, đã tự gặp và tự sửa lỗi này giữa chừng):
1. Đăng nhập tài khoản test (`0356123970`) → hệ thống tự hiện dialog "Allow BizTown Rent Manager to send you notifications?" đúng lúc `registerDeviceToken()` chạy → bấm Allow.
2. Query trực tiếp `tb_device_token` qua Supabase REST (service role, không qua app) → thấy đúng 1 dòng mới: `platform: "android"`, `token` là chuỗi FCM token thật, `created_at` đúng thời điểm vừa test.
3. Lấy JWT thật của tài khoản test qua Auth API (`grant_type=password`), gọi thẳng Edge Function `send-notification` với `houseId` thật của tài khoản này → response `{"push":{"recipientCount":1,"sent":1}}`.
4. Đọc logcat máy ảo ngay sau bước 3 → thấy `FirebaseMessaging` xử lý 1 tin nhắn đến (`Unable to log event: analytics library is missing` — cảnh báo vô hại, chỉ vì app chưa cài thêm gói `firebase_analytics`, không liên quan tới việc nhận tin) → xác nhận chuỗi **Edge Function → Google FCM → thiết bị thật đã chạy trọn vẹn**, không dừng lại ở "gọi API không báo lỗi".

**Lưu ý khoanh vùng, chưa làm ở đợt này (không phải thiếu sót — ngoài phạm vi yêu cầu)**:
- Chưa hiện banner hệ thống lúc app đang mở sẵn (foreground) — cần thêm gói `flutter_local_notifications` để tự vẽ banner khi nhận `FirebaseMessaging.onMessage`. Không làm vì lúc app đang mở đã có Realtime (Đợt 43) lo phần hiển thị trong app rồi; Push chủ yếu nhắm tới lúc app đang tắt/nền — đúng đối tượng SCREEN-SPEC/ARCHITECTURE đặt ra ban đầu.
- Push iOS (APNs) vẫn chưa test được — cần dungtv tải APNs key (`.p8`) từ Apple Developer Portal rồi upload vào Firebase Console (Project Settings → Cloud Messaging → Apple app configuration) trước, việc dungtv đang làm dở (mới có Apple Dev access gần đây).
- Chưa dọn "trang trí" thêm (icon push riêng, màu, âm thanh tuỳ biến) — dùng mặc định hệ thống, đủ để verify pipeline hoạt động.

## 2026-09-16 (Đợt 47) — Xử lý nốt Push iOS: dungtv gửi thêm APNs key, tìm ra + vá 1 bug thật khiến Firebase không init được trên iOS

dungtv gửi thêm `AuthKey_NRRK43XV84.p8` (APNs Authentication Key), yêu cầu xử lý nốt phần iOS thay vì dừng ở Android như Đợt 46.

**Đã làm**:
- `send-notification/index.ts`: bỏ giới hạn "chỉ gửi Android" — gửi push cho MỌI token (Android + iOS) qua cùng 1 hàm `sendFcmPush()`, vì FCM HTTP v1 tự dịch payload sang đúng định dạng APNs cho token iOS, không cần code riêng theo nền tảng. Deploy lại function.
- `ios/Runner/Runner.entitlements` (mới, `aps-environment: development`) + wire `CODE_SIGN_ENTITLEMENTS` vào cả 3 build config (Debug/Release/Profile) trong `project.pbxproj`.
- Build thử thật `flutter build ios` (cả bản không ký cho device lẫn bản cho Simulator) để kiểm chứng, không chỉ đoán.

**Bug thật tự tìm ra khi build+chạy thử (không phải dungtv báo)**: đặt đúng `GoogleService-Info.plist` vào thư mục `ios/Runner/` là CHƯA ĐỦ — Xcode cần file này được khai báo vào chính `project.pbxproj` (1 `PBXFileReference` + 1 dòng trong `PBXResourcesBuildPhase`, tức mục "Copy Bundle Resources") thì mới thực sự đóng gói file vào app lúc build. Thiếu bước này, app build được (không lỗi biên dịch) nhưng chạy lên báo lỗi thật: `[FirebaseCore] Could not locate configuration file: 'GoogleService-Info.plist'` → mọi lệnh gọi Firebase sau đó lỗi tiếp `[core/no-app] No Firebase App '[DEFAULT]' has been created`. Vá bằng cách thêm đúng 4 chỗ cần thiết trong `project.pbxproj` (PBXBuildFile, PBXFileReference, PBXGroup, PBXResourcesBuildPhase) — có backup file gốc trước khi sửa tay (rút kinh nghiệm từ việc từng phải thận trọng với các thay đổi ký số/entitlements trong file này). Build lại, verify TRỰC TIẾP file `GoogleService-Info.plist` có mặt thật bên trong `Runner.app` vừa build (không chỉ tin theo log) — sau đó chạy app không còn lỗi Firebase nào.

**Verify sống trên iOS Simulator thật** (`iPhone 17`, `iOS 27`, đã Booted sẵn từ phiên trước): cài + chạy app → tự khôi phục phiên đăng nhập cũ → vào đúng Home hiển thị đúng dữ liệu thật (5 nhà, 87 phòng, khớp dữ liệu test đã biết) → hệ thống tự hiện đúng dialog iOS thật *"'BizTown Rent Manager' Would Like to Send You Notifications"* (có chụp màn hình xác nhận) — đây là bằng chứng trực tiếp Firebase + entitlements đã nối đúng dây ở tầng native iOS, không chỉ "code không báo lỗi".

**Giới hạn thật của môi trường (không phải lỗi code, đã xác minh kỹ trước khi kết luận)**:
- Máy chạy Claude Code này không có cách bấm "Allow" trên dialog hệ thống đó: Simulator ở đây chạy hoàn toàn không có cửa sổ hiển thị thật (như đã ghi nhận trước đây khi thử build iOS lần đầu), `xcrun simctl` không có lệnh giả lập chạm màn hình (khác hẳn `adb shell input tap` bên Android), và `xcrun simctl privacy grant notifications ...` bị hệ thống chặn ("Failed to create TCC authorization record") trong sandbox này.
- Quan trọng hơn, đây là giới hạn của chính Apple chứ không phải của máy này: **Simulator iOS về bản chất không thể đăng ký nhận push thật từ APNs** dù có bấm Allow thành công — Simulator chỉ hỗ trợ giả lập tin nhắn ĐẾN (`xcrun simctl push ...`) để test hiển thị UI, không lấy được token thật để server gửi ngược lại. Vì vậy bước "verify push thật tới thiết bị" trên iOS — giống như đã làm thành công với Android ở Đợt 46 — bắt buộc phải chạy trên 1 iPhone thật, không có cách nào thay thế bằng Simulator dù chạy ở máy nào.

**Việc CHỈ dungtv làm được (cần đăng nhập Firebase Console bằng tài khoản Google của dungtv)** — Project Settings → tab "Cloud Messaging" → mục "Apple app configuration" → phần "APNs Authentication Key" → Upload, cần đúng 3 giá trị:
- File: `AuthKey_NRRK43XV84.p8` (đã gửi).
- Key ID: `NRRK43XV84` (đọc thẳng từ tên file theo quy ước đặt tên của Apple).
- Team ID: `RZ9777C36G` (đọc từ `DEVELOPMENT_TEAM` đã có sẵn trong `project.pbxproj` — đúng team Apple Developer dungtv vừa đăng nhập lúc build thử iOS trước đó).

**Kết luận cho dungtv**: toàn bộ phần code (backend + Flutter + cấu hình Xcode) cho Push iOS đã xong và đã verify tới đúng điểm giới hạn thật của môi trường (dialog hệ thống hiện đúng, chứng minh cấu hình đúng). Muốn có push thật chạy trên iOS cần đúng 2 việc còn lại mà chỉ dungtv làm được: (1) upload APNs key vào Firebase Console theo 3 giá trị ở trên, và (2) cài app lên 1 iPhone thật (không phải Simulator) để bấm Allow và nhận verify — y hệt cách đã verify thành công với Android.

## 2026-09-16 (Đợt 48) — Zalo ZNS: chốt hướng "nút Chi tiết → tin tư vấn kèm QR", vá 2 lỗi thật của cơ chế token

### Bối cảnh: 2 lần Zalo từ chối trước đó và cách thoát ra

Trước đợt này, việc gửi hoá đơn qua Zalo bế tắc vì 2 lỗi kiểm duyệt:
- `CT_25` — mẫu "Yêu cầu thanh toán" (Payment Request) bắt buộc dùng **tài khoản ngân hàng cố định của doanh nghiệp sở hữu OA**. Nhưng BizTown là nền tảng cho NHIỀU chủ trọ, mỗi hoá đơn cần STK của đúng chủ trọ đó → không thể cố định 1 STK.
- `CTA_5` — thử chuyển sang gắn link cố định tới trang hoá đơn thì bị từ chối vì *"link CTA chứa thông tin hoá đơn cố định, không phù hợp gửi cho từng khách hàng khác nhau"*.

dungtv đã tự xin duyệt được 1 template khác và **đã được Zalo chấp thuận**: "BizTown Rent-Manager : Hóa đơn định kỳ 2" (ID `636461`, loại **"Mẫu phản hồi nhanh"**, 10 tham số, nút "Chi tiết"). Ghi chú kiểm duyệt ghi rõ: *"mẫu thông báo hóa đơn, không quảng cáo, không mã qr barcode"*.

**Hướng đi dungtv đề xuất (chốt dùng)**: tin ZNS chỉ thông báo số tiền (không QR, đúng điều kiện duyệt) → người thuê bấm "Chi tiết" → nút phản hồi nhanh đẩy 1 tin nhắn vào khung chat OA từ phía người thuê → lúc này hội thoại do NGƯỜI DÙNG khởi tạo nên OA được phép gửi **tin tư vấn tự do kèm ảnh** → gửi ảnh QR VietQR của đúng chủ trọ đó.

Vì sao hướng này thoát được cả 2 lỗi trên: QR không nằm trong template (né ghi chú "không mã qr barcode" và né `CT_25`), và không cần link động trong CTA (né `CTA_5`). Tài khoản ngân hàng động nằm ở tin tư vấn — loại tin không bị ràng buộc template.

### Đã làm — giai đoạn 1 (gửi được tin ZNS)

- `_shared/zns_invoice.ts` (mới): map `tb_invoice` sang đúng 10 tham số template. Đáng chú ý: `utility_lines` là mảng jsonb theo từng phòng × từng loại tiện ích nên phải **gộp theo loại** mới ra `so_kwh`/`tien_dien`/`so_khoi_nuoc`/`tien_nuoc`; `phi_khac` là tổng của 3 nguồn khác nhau (`service_fee_amount` + `recurring_fees` + `other_fees`). Tham số số tiền gửi **chữ số thuần** (Zalo tự định dạng lúc hiển thị).
- `send-notification`: thêm kênh `zalo` **tách hẳn** khỏi kênh `tenant` (SMS) — bật/tắt độc lập, không rủi ro làm hỏng luồng SMS đang chạy thật. Response trả cả `templateData` và `msg_id` vì đang giai đoạn test cần đối chiếu.
- Chưa gắn tự động vào luồng gửi hoá đơn (B-03/B-05) — cố ý, chờ test thật xong mới nối.

**Còn 1 điểm chưa verify**: tham số `so_ky` kiểu "Thời gian" của Zalo — template khai báo mẫu `09/2026` (tháng/năm) nhưng đoạn "Mẫu code ví dụ" Zalo tự sinh lại ghi `01/08/2020` (ngày/tháng/năm). Code hiện gửi theo `MM/yyyy` đúng như template khai báo; nếu Zalo báo lỗi định dạng thì đổi 1 chỗ duy nhất trong `periodLabel()`.

### Bug thật #1 — SĐT Tenant sai định dạng (có sẵn từ Đợt 41)

`sendZns()` gửi thẳng SĐT lấy từ DB kèm comment ghi *"dạng 84xxxxxxxxx — khớp sẵn convention của app"*. Comment này SAI và là loại sai nguy hiểm vì nghe rất thuyết phục: `tb_user.phone` (chủ nhà/quản lý, do `normalizePhoneForDb` sinh ra) đúng là lưu `84...`, nhưng `tb_tenant.phone` lưu `09...` vì đó là ô người dùng gõ tay ở form Tenant — mà người nhận ZNS chính là Tenant, không phải user. Đã thêm `toZaloPhone()` chuẩn hoá cả 3 dạng ngay trong `sendZns()` để nơi gọi không phải nhớ bảng nào dùng quy ước nào.

### Bug thật #2 — tranh chấp khi làm mới token (nghiêm trọng)

**Triệu chứng**: gửi thử tin ZNS đầu tiên thì Zalo trả `Invalid refresh token` (-14014).

**Truy nguyên**: đọc `tb_zalo_token` thấy `expires_at` = `updated_at` = đúng thời điểm nạp token (15/09 01:35) — tức token được nạp với hạn dùng bằng 0, nên ngay lần gọi đầu tiên hệ thống đã đi làm mới. `updated_at` chưa từng đổi ⇒ Zalo đã cấp cặp mới nhưng DB **không hề được ghi lại** ⇒ cặp cũ bị Zalo huỷ, cặp mới mất luôn.

**Vì sao đây là bug thật chứ không chỉ là sự cố nạp dữ liệu**: refresh token Zalo là loại **dùng đúng 1 lần**. Chức năng B-03 "tạo & gửi hàng loạt" gửi nhiều hoá đơn **song song** (`Promise.all`). Nếu đúng lúc đó token hết hạn, cả chục lời gọi sẽ cùng thấy "hết hạn" và cùng gọi Zalo với **cùng một refresh token**: 1 cái thành công, phần còn lại vừa thất bại vừa làm chết token. Tức là tính năng gửi hàng loạt qua Zalo sẽ hỏng ngay lần chạy thật đầu tiên ở quy mô nhiều hoá đơn — không phải rủi ro lý thuyết.

**Đã vá 3 lớp**:
1. **Khoá chống tranh chấp** (`20260916100000_zalo_token_refresh_lock.sql`): thêm cột `refresh_lock_until`, giành khoá bằng UPDATE **có điều kiện ngay trong câu lệnh** (`where id='default' and (refresh_lock_until is null or refresh_lock_until < now())`). Chạy song song thì Postgres chỉ cho đúng 1 câu lệnh cập nhật thành công → chỉ 1 tiến trình nhận được dòng trả về và được phép gọi Zalo; các tiến trình khác chờ tối đa 15s rồi đọc token mới. Khoá tự hết hiệu lực sau 30s nên tiến trình chết giữa chừng không làm kẹt vĩnh viễn.
2. **Ghi token chắc chắn**: sau khi Zalo đã cấp cặp mới thì mọi lỗi ghi DB đều là mất token vĩnh viễn — nên thử lại 3 lần, thất bại hết thì ném lỗi ghi rõ "phải xin cấp lại cặp token mới bằng tay" thay vì nuốt lỗi im lặng (đúng cách đã làm token chết lần này).
3. **Tự gia hạn định kỳ** (`20260916110000_zalo_token_weekly_cron.sql` + Edge Function `refresh-zalo-token`): refresh token sống ~3 tháng và chỉ được gia hạn khi có người dùng. Nếu 3 tháng không chủ trọ nào gửi Zalo thì token chết dù code không có lỗi gì. Bật `pg_cron`/`pg_net`, chạy 08:00 thứ Hai hàng tuần. Service role key để gọi Edge Function lưu trong **Supabase Vault** (`vault.decrypted_secrets`), không nhúng thẳng vào `cron.job` — bảng đó ai đọc được database cũng xem được.

**Verify thật** (không chỉ deploy rồi tin là chạy): chạy migration trên database thật, xác nhận `cron.job` có dòng `refresh-zalo-token-weekly`, `active=true`. Test cơ chế khoá bằng 2 lượt PATCH liên tiếp qua REST — lượt 1 trả 1 dòng (giành được), lượt 2 ngay sau trả 0 dòng (bị chặn đúng thiết kế). Nhân tiện ghi lại 1 cái bẫy khi tự viết script test: dấu `+` của múi giờ ISO (`+00:00`) nằm trong URL query bị Postgres hiểu thành dấu cách và báo `invalid input syntax for type timestamp` — code Deno dùng `toISOString()` (đuôi `Z`) nên không dính, nhưng script tay bằng Python thì phải tự đổi sang đuôi `Z`.

### Việc còn lại

- **Chờ dungtv cấp lại cặp token Zalo mới** (cặp cũ đã chết) → gửi tin ZNS test thật tới `0356123970`.
### Lấy được token OA đúng loại — và chạm trần ở quyền của OA

Sau khi vá xong cơ chế token, gửi thử vẫn thất bại. Truy nguyên ra một nhầm lẫn cơ bản đã kéo dài từ Đợt 41: **Zalo có 2 loại token khác nhau** và cặp token đang dùng là loại sai.

| | Token App | Token OA |
|---|---|---|
| Lấy bằng | App ID + App Secret là đủ | Phải qua bước OA **cấp quyền** cho app (OAuth) |
| Endpoint làm mới | `/v4/access_token` | `/v4/oa/access_token` |
| Gửi ZNS được không | **Không** | Có |

Triệu chứng của việc lấy nhầm loại rất dễ hiểu sai: gửi ZNS báo `-124 Access token invalid`, làm mới báo `-14014 Invalid refresh token` — nhìn như token hỏng/hết hạn, trong khi thực chất là sai loại. Đây cũng là lý do câu trả lời ở Đợt 41 (*"miền townsoftvina.com KHÔNG cần, chỉ dùng cho đăng nhập Zalo trên web"*) là **SAI**: luồng cấp quyền OA bắt buộc có `redirect_uri` thuộc domain đã xác thực.

**Đã dựng luồng lấy token tự động** thay cho việc copy/dán tay:
- Edge Function `zalo-oauth-callback` (mới, `auth: ["none"]` vì Zalo chuyển hướng trình duyệt tới, không kèm JWT): nhận `code` → đổi ra cặp token OA → lưu `tb_zalo_token` với `expires_at` đúng. Có 2 lớp chặn: `state` phải khớp secret `ZALO_OAUTH_STATE`, và `oa_id` Zalo trả về phải đúng OA của BizTown — nếu không, bất kỳ ai biết URL cũng có thể cấp quyền OA CỦA HỌ và ghi đè token của mình.
- Zalo bắt **xác thực quyền sở hữu** đường dẫn callback trước khi cho dùng, bằng cách đặt file `zalo_verifier<mã>.html` tại chính đường dẫn đó. Vì callback là Edge Function chứ không phải web tĩnh, hàm tự sinh nội dung file từ mã trong tên file — không ghi cứng 1 mã, để Zalo cấp lại mã khác thì không phải deploy lại. Đã verify thật bằng cách gọi vào đường dẫn và so khớp từng dòng với file Zalo cấp.
- Kết quả: dungtv bấm 1 link, chọn OA, bấm đồng ý → token OA tự lưu. Gọi `openapi.zalo.me/v2.0/oa/getoa` xác nhận token đúng OA "Townsoft Vina - BizTown", `is_verified=true`.

**Chạm trần thật sự — `-120 "OA does not have permission to use this feature"`**: token OA hợp lệ nhưng MỌI endpoint ZNS đều bị chặn, kể cả API chỉ để xem hạn mức (`business.openapi.zalo.me/message/quota`). Đối chiếu thêm: app đã được duyệt đủ cả 3 quyền ZNS API ("Gửi ZNS", "Gửi ZNS với hệ mã hóa RSA", "Khởi tạo Journey Token"). Vậy vướng không nằm ở app cũng không nằm ở token, mà ở **chính OA chưa được bật gửi ZNS qua API trực tiếp**. Dấu hiệu củng cố: template `636461` ghi rõ là "ID mẫu **ZBS**", và OA có liên kết tài khoản ZBS riêng (`biztown`, ZBS-311863) — tức ZNS của OA này đang đi theo nhánh ZBS, còn nhánh OpenAPI trực tiếp phải xin bật riêng. Đang chờ dungtv liên hệ Zalo/ZBS để bật.

### Chốt: KHÔNG gửi ZNS qua eSMS

Claude đề xuất đường vòng: gửi ZNS qua eSMS (đối tác ZNS chính thức, mà dự án đã có sẵn tài khoản đang chạy thật cho SMS) để khỏi phải chờ Zalo bật quyền. **dungtv bác bỏ**, lý do: **eSMS đắt hơn và không kiểm soát được chi phí** — đi qua đại lý thì giá do đại lý đặt chứ không theo bảng giá gốc của Zalo, và khó theo dõi chi tiêu.

Quyết định: ZNS đi thẳng API Zalo; gặp vướng thì xử lý ở phía Zalo/ZBS (xin bật quyền, xin duyệt) chứ không lấy eSMS làm lối thoát. eSMS **vẫn giữ nguyên cho SMS thường** — quyết định này chỉ áp dụng cho kênh ZNS.

- **Câu hỏi mấu chốt cần test mới trả lời được**: khi người thuê bấm "Chi tiết", webhook Zalo gửi về những gì? Zalo chỉ định danh người dùng bằng **UID**, còn BizTown gửi ZNS theo **số điện thoại** — nếu webhook không kèm `msg_id` hay mã tham chiếu nào thì không biết UID đó ứng với hoá đơn nào. Có 2 hướng dự phòng: (a) đối chiếu qua `msg_id` đã lưu lúc gửi (vì vậy `sendZns()` nay trả về `msgId`), hoặc (b) lần đầu OA gửi tin xin chia sẻ SĐT, người thuê bấm 1 lần rồi lưu ánh xạ UID ↔ SĐT cho các lần sau. Chưa code hướng nào — chờ dữ liệu thật từ webhook rồi mới quyết, tránh đoán sai rồi phải viết lại.

**Kết luận cho dungtv**: nguyên nhân chậm 100% là lỗi N+1 ở tầng code Flutter (không phải thiếu index database) — đã tìm và vá hết 3 chỗ tìm được trong toàn app, verify sống từng màn sau khi sửa đều nhanh (~1.5-2s) và dữ liệu vẫn đúng.

## 2026-09-15 (Đợt 46) — Luồng gửi tin Zalo OA cho Tenant: chốt tham số Mẫu 1 (đã duyệt, ID 636121), ghi lại vướng mắc + phương án đang cân nhắc cho Mẫu 2

Dream cung cấp thông tin Template ZBS Mẫu 1 ("Chào mừng hợp đồng") đã được Zalo duyệt (ID 636121, chụp màn hình chi tiết mẫu + bảng tham số từ account.zalo.cloud/Business Suite), yêu cầu viết tài liệu mô tả luồng gửi kèm khớp đúng tên tham số/kiểu dữ liệu đã duyệt với field thực tế trong database (không dùng lại tên tham số nháp cũ trong `zns-hoa-don-template.md`, vốn được soạn trước khi mẫu được duyệt nên lệch ở vài chỗ). Đồng thời Dream trình bày hiện trạng vướng mắc của Mẫu 2 (hoá đơn hàng tháng) — template ZBS cấm/không hỗ trợ QR động, ràng buộc quyền sở hữu tài sản đích của nút CTA, tin tư vấn bị khoá bởi cửa sổ tương tác 7 ngày trong khi chu kỳ hoá đơn là 1 tháng, các mẫu thử đều bị từ chối duyệt — và 4 phương án đang cân nhắc, **chưa chốt phương án nào**.

**Đã làm:** tạo `docs/ZALO-MESSAGING.md` (mới) — gộp 2 luồng:

- **Luồng A (Mẫu 1, đã duyệt):** ghi lại đúng nội dung/tham số đã duyệt (8 tham số, 1 nút CTA duy nhất — khác bản nháp cũ có 2 nút và tên tham số `ngay_thanh_toan`), map từng tham số với field DB thực tế theo schema Version 3 (`tb_tenant`, `tb_contract`, `tb_contract_version`, `tb_room`, `tb_house`). Phát hiện 2 gap thật cần chốt trước khi code: (1) `<ma_hop_dong>` không có field tương ứng — `tb_contract` chỉ có `id` (uuid), cần quyết định thêm cột mã hiển thị hay dùng tạm uuid rút gọn; (2) 1 hợp đồng có thể có nhiều phòng (`tb_contract_room` N-N) nhưng mẫu chỉ có 1 ô `<ten_phong>` — chưa có quy tắc ghép/chọn phòng nào hiển thị. Cũng phát hiện `sendZns()` (`_shared/zalo.ts`) khai báo `templateData: Record<string, string>` trong khi mẫu có 2 tham số kiểu `number` — cần verify lại đúng kiểu dữ liệu Zalo yêu cầu trước khi gọi thật. Ghi lại luôn: DB hiện **không có chỗ lưu UID/thời điểm tương tác OA của Tenant** — là điều kiện tiên quyết để tối ưu chi phí Mẫu 2 sau này (mục đích Dream nêu "quan tâm xong thì đổi SĐT→UID cho rẻ hơn"), cần bổ sung field mới (`tb_tenant.zalo_uid`, `zalo_followed_at`) — chưa quyết, cần Dream/dungtv chốt.
- **Luồng B (Mẫu 2, chưa chốt):** ghi lại nguyên văn 4 vướng mắc + 4 phương án Dream đề xuất, bổ sung đối chiếu với research trước đó (`zalo-feasibility-review.md` trong Project brainstorm của Dream, không nằm trong repo) cho từng phương án — đặc biệt lưu ý Phương án 1 (tách 2 bước, tin tư vấn kích hoạt bởi tương tác) có rủi ro kỹ thuật CHƯA XÁC NHẬN (bấm nút ZBS có mở lại cửa sổ 7 ngày hay không) ngoài rủi ro Dream đã nêu (Tenant không bấm thì không nhận QR). Đánh dấu rõ **CHƯA CODE luồng này** tới khi có quyết định.

**Việc cần làm tiếp** (xem chi tiết trong `docs/ZALO-MESSAGING.md` mục 1.7/2.4): chốt cách lấy `<ma_hop_dong>` và xử lý hợp đồng nhiều phòng cho Luồng A trước khi code; chốt 1 trong 4 phương án (hoặc phương án khác) cho Luồng B rồi mới code; sau khi chốt, cập nhật `BUSINESS-RULES.md` (`BR-NOTI-01` hiện ghi "SMS/Zalo kèm mã QR" — đã lỗi thời so với vướng mắc thật, cần rà lại theo phương án được chọn).

## 2026-09-15 (Đợt 47) — Luồng OTP xác thực tài khoản: chuyển từ eSMS sang ZBS (template đã duyệt, ID 636478) để giảm chi phí

Dream cung cấp Template ZBS "Mẫu OTP" đã được Zalo duyệt (ID 636478, chụp màn hình chi tiết mẫu + tham số), yêu cầu bổ sung thêm 1 luồng nữa (Luồng C) vào `docs/ZALO-MESSAGING.md`: đổi luồng gửi OTP khi đăng ký tài khoản/quên mật khẩu — hiện đang dùng eSMS (`send-otp-sms/index.ts`, Đợt 14) — sang ZBS, mục tiêu giảm chi phí, và lưu ý nội dung/tính năng liên quan đã phát triển trước đó cần rà lại cho khớp.

**Đã làm:** cập nhật `docs/ZALO-MESSAGING.md` (Version 2) — thêm mục 3 (Luồng C):

- Ghi lại đúng nội dung/tham số mẫu 636478 (chỉ 1 tham số `<otp>`, kiểu string — không có mismatch kiểu dữ liệu như Luồng A).
- Xác nhận Send SMS Hook của Supabase Auth không ràng buộc kênh gửi thật (chỉ cần đúng contract webhook) — đổi nhà cung cấp chỉ cần sửa phần thân `send-otp-sms/index.ts`, không cần đổi cấu hình hook trên Supabase Dashboard.
- Ghi lại lý do đổi hợp lý ngoài giá tiền: hiện đang dùng Brandname demo dùng chung "Baotrixemay" của eSMS (không nhắc gì tới BizTown, không dùng được cho user thật) — chuyển sang ZBS loại bỏ luôn phụ thuộc vào việc đăng ký/chờ duyệt Brandname CSKH thật của eSMS, một quy trình riêng chưa có mốc trong repo. Chi phí Brandname CSKH thật của eSMS chưa được ghi lại trong repo — cần Dream xác nhận số thật nếu muốn so sánh chính xác.
- Gắn cờ 1 điểm kỹ thuật dễ sai: định dạng số điện thoại khác nhau giữa eSMS (`toLocalVnPhone()` ra dạng `0xxxxxxxxx`) và Zalo (`sendZns()` cần dạng `84xxxxxxxxx`, chỉ cắt dấu `+` chứ không cắt `+84`) — nhắc rõ không copy nhầm hàm cũ.
- Liệt kê danh sách "nội dung đã phát triển cần rà lại" theo đúng yêu cầu Dream: copy UI S-02/S-04 có thể đang giả định cứng kênh "SMS"; `REQUIREMENTS.md` INT-02/INT-03 và `ARCHITECTURE.md` đang mô tả cụ thể eSMS; cảnh báo Brandname demo trong comment đầu file code sẽ không còn đúng nếu bỏ hẳn eSMS.
- Ghi rõ luồng này **không** phải trọng tâm tối ưu UID (khác Luồng A/B) — App user gửi OTP lần đầu chưa kịp follow OA, nên phần lớn vẫn đi qua kênh SĐT.
- Chưa sửa code thật (`send-otp-sms/index.ts` vẫn dùng eSMS) — chỉ tài liệu, đánh dấu rõ các việc cần làm trước khi bật thật ở mục 3.7.

**Chưa quyết, cần Dream/dungtv chốt:** giữ eSMS làm fallback khi Zalo lỗi hay bỏ hẳn.

## 2026-09-15 (Đợt 48) — Sửa `ZALO-MESSAGING.md` theo phản hồi Dream: bỏ so sánh với bản nháp cũ, làm rõ quy tắc OTP đã chốt

Dream phản hồi 2 điểm về `docs/ZALO-MESSAGING.md`: (1) không muốn tài liệu nhắc/so sánh với bản nháp cũ (`zns-hoa-don-template.md`) nữa — chỉ ghi nhận đúng bản template đã được phê duyệt; (2) không thấy tài liệu nêu rõ **quy tắc gửi OTP đã đổi từ eSMS sang ZBS** — mục 3 (Luồng C) viết ở Đợt 47 mô tả kỹ thuật nhưng không có phát biểu dứt khoát "đây là quyết định đã chốt".

**Phát hiện thêm khi rà lại để sửa:** file `docs/ZALO-MESSAGING.md` trên máy Dream lúc kiểm tra lại **đang ở đúng bản Version 1** (2 luồng, chưa có Luồng C) dù Đợt 47 đã ghi log là "đã cập nhật lên Version 2" và lệnh ghi file trả về thành công — tức bản Version 2 (thêm Luồng C) đã KHÔNG được giữ lại trên máy Dream vì lý do nào đó ngoài tầm kiểm soát của phiên làm việc này (khả năng cao: file đang mở sẵn trong 1 trình soạn thảo/IDE nào đó trên máy và bị ghi đè ngược lại bởi buffer cũ — **Dream nên kiểm tra xem `docs/ZALO-MESSAGING.md` có đang mở ở VS Code/editor nào không, đóng lại (không lưu) trước khi mở lại file để tránh bị ghi đè lần nữa**). Đã ghi lại toàn bộ nội dung Version 2 (cả Luồng A/B/C) lại từ đầu, không chỉ vá riêng Luồng C.

**Đã sửa trong `docs/ZALO-MESSAGING.md`:**
- Bỏ toàn bộ đoạn so sánh/nhắc tới bản nháp cũ `zns-hoa-don-template.md` (khối cảnh báo "Khác với bản nháp cũ" ở mục 1.3, các ghi chú "bản nháp cũ ghi..." trong bảng tham số mục 1.4) — chỉ còn nội dung/tham số của bản đã duyệt, không so sánh lịch sử.
- Mục 3 (Luồng C) nay mở đầu bằng câu chốt rõ ràng: "✅ QUY TẮC ĐÃ CHỐT: kênh gửi OTP xác thực tài khoản đổi từ eSMS sang Zalo ZBS (template 636478 đã duyệt)" — tách bạch với 1 chi tiết triển khai vẫn còn mở (có giữ eSMS làm fallback hay không), để không đọc nhầm cả luồng là "chưa chốt".

**Đã cập nhật thêm `docs/REQUIREMENTS.md`** — INT-03 (OTP) nay ghi rõ "ĐÃ CHỐT: đổi kênh gửi từ eSMS sang Zalo ZBS", trỏ tới `ZALO-MESSAGING.md` mục 3; tách rõ khỏi INT-02 (SMS Brandname qua eSMS — vẫn dùng cho thông báo/hoá đơn gửi Tenant qua `send-notification`, không liên quan OTP nữa).

## 2026-09-16 (Đợt 49) — Hạ độ ưu tiên "Nhắc thanh toán tự động" từ Must xuống Could cho phase này

Dream xác nhận (qua trao đổi ở Project brainstorm riêng, không phải phiên Claude Code trên repo): nhắc trễ hẹn (nhắc thanh toán trước/đúng/sau hạn) chỉ là **Could**, không phải **Must** trong phase hiện tại — đảo lại quyết định trước đó (BR-PAY-04/BR-NOTI-02/FR-BILL-09 từng ghi Must, kế thừa nguyên vẹn từ Version 2 mà chưa từng được đặt lại câu hỏi ở Version 3).

**Đã sửa:**
- `docs/BUSINESS-RULES.md` — `BR-PAY-04` (mục 2) và `BR-NOTI-02` (mục 5): cột Trạng thái đổi Must → Could, ghi rõ ngày hạ + tham chiếu Đợt này.
- `docs/REQUIREMENTS.md` — `FR-BILL-09` (mục 2.6): Priority đổi Must → Could. `FR-NOTI-02` (mục 2.9): tách rõ 2 phần trong cùng 1 dòng — phần "hoá đơn mới" vẫn **Must**, phần "nhắc thanh toán" hạ xuống **Could** (2 phần trước đó gộp chung 1 mức Must, nay không còn đúng nữa vì chỉ 1 trong 2 bị hạ).

**Chưa đổi (ngoài phạm vi yêu cầu lần này):** `BR-NOTI-04`/`FR-CTR-05` (nhắc gia hạn hợp đồng sắp hết hạn) vẫn giữ nguyên `Could` như cũ — không liên quan tới nhắc thanh toán hoá đơn. Chưa động tới code (tính năng nhắc thanh toán tự động hiện **chưa có implementation** nào trong `supabase/functions`/`src/lib` — đây thuần là điều chỉnh tài liệu kế hoạch, không phải rollback code).

**Việc cần làm tiếp:** vì hạ xuống Could, không cần ưu tiên dựng job nhắc hạn tự động (cron/scheduled function) trong phase này; nếu sau này nâng lại lên Must, cần quay lại chốt giá trị X/Y ngày nhắc cụ thể (vẫn đang để trống trong BR-PAY-04).

## 2026-09-16 (Đợt 50) — Đảo lại quyết định "OTP đổi sang Zalo ZBS" (Đợt 47/48): tạm hoãn, quay về eSMS cho tới khi chốt việc dùng OA

Dream yêu cầu (qua Project brainstorm riêng, không phải phiên Claude Code trên repo) đảo lại/ghi đè quyết định "✅ ĐÃ CHỐT: đổi kênh gửi OTP xác thực tài khoản từ eSMS sang Zalo ZBS" đã ghi ở Đợt 47/48 (2026-09-15). Lý do: ZBS xác nhận rẻ hơn eSMS về giá, nhưng Dream đang cân nhắc lại **có nên tiếp tục dùng Zalo OA cho toàn hệ thống hay không** — câu hỏi rộng hơn, chưa chốt. Ràng buộc rõ từ Dream: **không sửa bất kỳ nội dung code nào đã viết**; luồng OTP tạo tài khoản/đổi mật khẩu **tiếp tục ưu tiên gửi qua SMS (eSMS)** cho tới khi có quyết định về việc dùng OA.

**Xác nhận trước khi sửa tài liệu:** rà lại `supabase/functions/send-otp-sms/index.ts` — file này **chưa từng thực sự đổi sang Zalo**, toàn bộ logic vẫn chỉ gọi `sendViaEsms()` (không có nhánh `sendZns()`/import `_shared/zalo.ts` nào). Quyết định Đợt 47/48 chỉ dừng ở mức tài liệu, chưa từng được implement. Vì vậy việc đảo quyết định lần này **không cần và không có sửa code nào** — code hiện tại đã khớp sẵn với quyết định mới (tiếp tục dùng eSMS). Không đổi `supabase/functions/_shared/zalo.ts`, không đổi migration `tb_zalo_token`, không đổi secrets `ZALO_OA_ID`/`ZALO_APP_ID`/`ZALO_APP_SECRET` — các phần này vẫn giữ nguyên để dùng cho Luồng A (Mẫu 1 hoá đơn, đã duyệt) và làm sẵn cho tương lai nếu OA tiếp tục được dùng.

**Đã sửa (chỉ tài liệu):**
- `docs/ZALO-MESSAGING.md` — mục Trạng thái tài liệu nâng lên Version 3, ngày 2026-09-16; Luồng C (mục 3) đổi câu chốt "✅ QUY TẮC ĐÃ CHỐT (2026-09-15)" thành "⏸️ TẠM HOÃN (16/09/2026, Đợt 50)" kèm giải thích lý do (đang cân nhắc lại câu hỏi OA) và khẳng định rõ: cho tới khi có quyết định về OA, kênh gửi OTP tiếp tục ưu tiên eSMS, không đổi so với hiện tại. Nội dung kỹ thuật chi tiết của Luồng C (tham số template 636478, mapping, checklist code ở mục 3.7...) **được giữ nguyên làm tài liệu tham khảo**, không xoá — để tái sử dụng nếu sau này quyết định tiếp tục dùng OA. Mục 3.6 đổi thành bảng lịch sử trạng thái quyết định (Đợt 47/48 → chốt ZBS; Đợt 50 → tạm hoãn, quay lại eSMS).
- `docs/REQUIREMENTS.md` — `INT-03` (OTP): đổi từ "ĐÃ CHỐT: đổi kênh gửi từ eSMS sang Zalo ZBS" thành "Tạm hoãn quyết định đổi sang ZBS (Đợt 50) — đang cân nhắc lại việc dùng Zalo OA cho hệ thống; cho tới khi chốt, tiếp tục ưu tiên gửi SMS qua eSMS như hiện tại".
- `docs/DECISIONS.md` (file này) — thêm entry Đợt 50 này, không sửa/xoá nội dung Đợt 47/48 (giữ nguyên theo đúng tính chất "nhật ký", không ghi đè lịch sử).

**Chưa quyết, cần Dream/dungtv chốt tiếp:** có tiếp tục dùng Zalo OA cho hệ thống (Luồng A hoá đơn, Luồng B tin tư vấn, Luồng C OTP) hay không — quyết định này ảnh hưởng rộng hơn riêng luồng OTP, cần chốt trước khi quay lại bất kỳ luồng Zalo nào. Nếu sau này chốt tiếp tục dùng OA và muốn OTP dùng ZBS: nội dung kỹ thuật Đợt 47/48 (mục 3 `ZALO-MESSAGING.md`) đã có sẵn, chỉ cần đổi lại trạng thái và code `send-otp-sms/index.ts` theo checklist mục 3.7 đã ghi.

## 2026-09-16 (Đợt 51) — Chốt: bỏ hẳn Zalo OA cho Phase 1, chuyển hoá đơn hàng tháng gửi Tenant sang eSMS kèm link ảnh chi tiết + QR

Dream chốt (qua Project brainstorm riêng, không phải phiên Claude Code trên repo), trả lời luôn câu hỏi còn để mở ở Đợt 50: **cơ chế vận hành Zalo OA phức tạp hơn mức cần thiết cho Phase 1** — đăng ký + xác thực doanh nghiệp, tạo và chờ duyệt từng mẫu ZNS/ZBS (2-3 ngày làm việc/mẫu), quản lý cửa sổ tương tác 7 ngày cho tin tư vấn, chính sách cấm QR trong khối hình ảnh của mẫu ZNS/ZBS (đã ghi nhận ở `ZALO-MESSAGING.md` mục 2.1) — while Phase 1 chỉ cần 1 kênh gửi thông tin hoá đơn đơn giản, đáng tin cậy. Quyết định:

1. **Bỏ hẳn Zalo OA cho Phase 1**, không dùng cho bất kỳ luồng nào (Luồng A chào mừng hợp đồng, Luồng B hoá đơn hàng tháng, Luồng C OTP). Luồng C đã tạm hoãn từ Đợt 50 vì lý do khác (đang cân nhắc OA) — nay chính thức khớp với lý do rộng hơn này, không còn là "tạm" nữa.
2. **Hoá đơn hàng tháng gửi Tenant chuyển hẳn sang kênh SMS qua eSMS** (kênh đã tích hợp sẵn cho `send-notification`, xem `REQUIREMENTS.md` INT-02) — không còn ghi kênh nước đôi "SMS/Zalo" như trước.
3. **Nội dung SMS gồm 2 phần:** (a) thông tin chính ngắn gọn ngay trong text (tên nhà/phòng, kỳ, tổng tiền, hạn thanh toán); (b) 1 **link ngắn** dẫn tới 1 **ảnh** do hệ thống tự tạo riêng cho từng hoá đơn, ảnh gồm bảng chi phí chi tiết (tiền phòng/điện/nước/phí khác/tổng cộng/hạn) **và mã QR VietQR** để chuyển khoản. Cách này giữ SMS gọn trong 1 đoạn tính phí (viết không dấu, dưới 160 ký tự GSM-7) trong khi vẫn hiển thị đầy đủ chi tiết + QR qua ảnh — không tốn thêm ký tự SMS nào cho phần chi tiết.
4. **Toàn bộ nội dung liên quan Zalo OA hiện có trong docs tạm ngưng sử dụng cho Phase 1** — không xoá, giữ nguyên làm tài liệu tham khảo để tái sử dụng nếu sau này đổi hướng dùng lại OA (Phase 2 trở đi).

**Đã sửa:**
- `docs/BUSINESS-RULES.md` — `BR-NOTI-01`/`BR-NOTI-02`/`BR-NOTI-04`: đổi kênh "SMS/Zalo" → "SMS (eSMS)"; `BR-NOTI-01` ghi rõ "kèm link ảnh chi tiết + mã QR" thay vì "kèm mã QR" (câu cũ không còn đúng, hoá đơn Phase 1 không gửi QR trực tiếp trong tin Zalo nữa).
- `docs/REQUIREMENTS.md` — `FR-NOTI-02`: đổi kênh sang "SMS (eSMS) kèm link ảnh chi tiết"; `INT-01` (Zalo ZNS/OA): đổi trạng thái sang "⏸️ TẠM NGƯNG cho Phase 1 (Đợt 51)", trỏ về entry này; `INT-03` (OTP): bổ sung ghi chú đây nay là quyết định chính thức cho Phase 1 (không chỉ "chờ chốt" như Đợt 50 đã ghi).
- `docs/ZALO-MESSAGING.md` — thêm banner ngay đầu tài liệu: toàn bộ nội dung (Luồng A/B/C) tạm ngưng sử dụng cho Phase 1 kể từ Đợt 51, giữ nguyên làm tham khảo, không xoá.
- Thêm `docs/SMS-HOA-DON.md` (**mới**) — mẫu nội dung SMS đã tối ưu chi phí (so sánh có dấu/không dấu, số đoạn tính phí), thiết kế ảnh chi tiết kèm QR (bố cục, dữ liệu ví dụ), và bảng ánh xạ đầy đủ field (`tb_invoice`, `tb_house`, `tb_room`) — nội dung khớp với mockup ảnh đã gửi Dream xem qua Claude/Cowork.

**Chưa làm (ngoài phạm vi đợt này — thuần tài liệu/thiết kế):** code thật cho luồng gửi hoá đơn qua eSMS kèm link ảnh (Edge Function sinh ảnh theo từng hoá đơn, endpoint/route phục vụ link ngắn, sửa `send-notification` bỏ nhánh Zalo `// TODO`, xoá bớt phụ thuộc Zalo nếu quyết định dứt khoát hơn nữa về sau). Hạ tầng Zalo hiện có (`_shared/zalo.ts`, `tb_zalo_token`, 3 secret) **không xoá** — giữ nguyên, không dùng tới trong Phase 1.

## 2026-09-16 (Đợt 52) — Dream tự sửa trực tiếp trong Figma: gộp SMS xác nhận hợp đồng mới + hoá đơn vào cùng 1 luồng hội thoại, đổi caption "QR + CTK:" → "Chi tiet:"

Dream tự sửa trực tiếp trong file Figma thiết kế (`AElzfTBuL8YyA8OJ85f7aX`, page "MVP Wireframes (EN) — Version 3"), sau đợt Claude dựng thêm 2 mockup SMS OTP + xác nhận hợp đồng mới theo yêu cầu trước đó (thêm lên trên mockup hoá đơn). Dream yêu cầu Claude so sánh lại bản Figma mới nhất với bản đã dựng rồi phản ánh đúng thay đổi vào docs — cùng tiền lệ đã áp dụng cho FigJam ở đợt 2026-09-08 (đợt 2): 1 chỉnh sửa trực tiếp trong công cụ thiết kế của Dream được coi là nguồn quyết định chính thức, cần đồng bộ ngược lại vào tài liệu, không chỉ ghi nhận trong hội thoại.

**Thay đổi Dream đã tự làm trong Figma** (xác nhận bằng cách đọc lại toàn bộ node liên quan qua Figma MCP):

1. **Gộp 2 mockup rời (SMS OTP và SMS xác nhận hợp đồng mới, Claude dựng tách biệt ở đợt trước) thành 1 khung hội thoại SMS duy nhất** ("MOCK-SMS — Minh hoạ tin nhắn SMS gửi hoá đơn"), chứa 2 tin nhắn nối tiếp nhau theo thời gian (tin xác nhận hợp đồng lúc 15/9, tin hoá đơn lúc hôm nay) — mô phỏng đúng 1 luồng SMS thật Tenant sẽ nhận được từ cùng 1 đầu số theo thời gian. **Mockup SMS OTP bị bỏ khỏi khung này** — không phải sai sót: OTP gửi cho người dùng App (Landlord/Manager) lúc đăng ký/quên mật khẩu, khác đối tượng nhận với 2 tin còn lại (gửi Tenant, không có tài khoản), không thuộc cùng 1 luồng hội thoại. Quyết định OTP không đổi (vẫn theo Đợt 50: eSMS, không liên quan Zalo OA).
2. **Việc gộp thành 1 luồng hội thoại xác nhận luôn kênh gửi cho tin xác nhận hợp đồng mới: SMS qua eSMS — cùng kênh, cùng thread với hoá đơn hàng tháng.** Đây là điểm còn để ngỏ ở Đợt 51 (mục 4 entry đó ghi "Tin chào mừng hợp đồng mới (Luồng A): chưa có kênh thay thế nào được chốt — tạm thời không gửi loại tin này") — nay được Dream chốt qua chính bản thiết kế, không cần chờ quyết định riêng nữa.
3. **Đổi caption link trong SMS hoá đơn: "QR + CTK:" → "Chi tiet:"** — không đổi phần còn lại của nội dung, không đổi độ dài (vẫn 97 ký tự, 1 đoạn GSM-7).
4. Nội dung SMS xác nhận hợp đồng mới giữ nguyên như Dream đã viết ở đợt Figma trước: `"BizTown: HD thue phong 203 - Minh Tam da tao. Bat dau 15/09/2026, tien thue 2.500.000d/thang, han TT ngay 25 hang thang."` (114 ký tự, 1 đoạn GSM-7, không dấu — cùng nguyên tắc tối ưu chi phí như SMS hoá đơn ở Đợt 51).

**Đã sửa (docs):**
- `docs/SMS-HOA-DON.md` — mục 2 đổi tên thành "Mẫu nội dung SMS gửi Tenant", tách **2.1** (SMS xác nhận hợp đồng mới — nội dung mới, lần đầu ghi thành mẫu tham số hoá chính thức trong docs) và **2.2** (SMS hoá đơn hàng tháng — đổi caption "QR + CTK:"→"Chi tiet:"); mục 4 bổ sung 3 field mapping mới cho tin xác nhận hợp đồng mới (`tb_contract.startDate`/`tb_contract_version.startDate`, `tb_contract_version.rentFee`, `tb_contract_version.paymentDueDayOfMonth`).
- `docs/ZALO-MESSAGING.md` — banner đầu tài liệu: bullet "Tin chào mừng hợp đồng mới (Luồng A)" đổi từ "chưa có kênh thay thế nào được chốt — tạm thời không gửi loại tin này" thành đã chốt dùng SMS qua eSMS, cùng thread với hoá đơn — trỏ về `docs/SMS-HOA-DON.md` mục 2.1 và entry này.

**Chưa làm (ngoài phạm vi đợt này):** không sửa thêm gì trong Figma (Dream chỉ yêu cầu đồng bộ docs theo bản Figma hiện có). 1 khối chú thích kỹ thuật cũ (đếm ký tự SMS hoá đơn, dựng ở đợt trước) bị kéo lệch ra ngoài khung auto-layout trong lúc Dream sửa (không còn nằm trong frame "MOCK-SMS", đứng riêng lẻ trên canvas) — chưa động tới, để nguyên đúng như Dream để lại, sẽ hỏi lại nếu cần dọn dẹp. Không thêm rule BR/FR riêng nào cho tin xác nhận hợp đồng mới ở đợt này — rà `docs/BUSINESS-RULES.md`/`docs/REQUIREMENTS.md` xác nhận cả 2 file hiện chưa có rule nào cho tính năng này (có thể bổ sung ở đợt sau nếu cần, chưa bắt buộc vì nội dung/kênh đã đủ rõ trong `SMS-HOA-DON.md`). Không sửa code.

## 2026-09-16 (Đợt 53) — Quy tắc màu Stepper đăng ký do dungtv chốt; frame Figma `386:2282` vẽ SAI, cần Dream sửa lại

**Quy tắc chính thức (dungtv chốt trực tiếp):**

> Chấm CAM = bước người dùng đang đứng. Làm xong bước nào thì **chấm bước đó VÀ vạch ngay sau nó** chuyển XANH. Bước chưa tới để XÁM.

Hệ quả: **vạch chỉ có hai màu xám → xanh, không bao giờ cam.** Cam là màu dành riêng cho chấm đang làm. Đây đúng là hành vi code đã làm từ đầu (`shared/signup_stepper.dart`, dựng 09/09/2026).

**Frame `386:2282` (S-04 Forgot password → Verify your phone) trên Figma vẽ vạch bước 1 màu cam `#EF9F27` là SAI so với quy tắc trên.** Cần Dream sửa lại frame đó cho khớp 3 frame còn lại (`173:139` component, `220:2214`, `347:2941`, `388:2375` — tất cả đều vẽ xám). **Không sửa code theo frame sai này.**

**Ghi lại lần đi sai để đợt sau không lặp:** dungtv chụp màn Đăng ký, khoanh đỏ vạch giữa chấm 1 và chấm 2, ghi *"đổi màu chỗ này (thiết kế đã sửa)"*. Claude đối chiếu Figma, phát hiện 2 frame nội dung y hệt nhau nhưng khác màu vạch, rồi **suy luận từ node id** (`386:xxx` > `220:xxx`, mà Figma cấp id tăng dần theo thời gian → frame đó dựng sau → hẳn là bản đã sửa), kết luận vạch phải cam và sửa code theo. dungtv bác bỏ: *"cái này dễ vậy mà bạn hiểu quá phức tạp"*, rồi nêu quy tắc hai dòng ở trên. Code đã được trả lại nguyên trạng.

**Bài học áp dụng cho mọi đợt sau:** thứ tự node id, thời điểm tạo frame và các suy luận tương tự **không phải bằng chứng về ý đồ thiết kế**. Khi hai nguồn thiết kế mâu thuẫn nhau, dừng lại hỏi dungtv quy tắc hành vi, đừng tự chọn bên rồi code theo. Figma cũng có thể sai — frame nào nghịch với quy tắc đã chốt thì báo lại như một lỗi thiết kế để Dream sửa, không bê vào app.

**Trạng thái code:** `src/lib/shared/signup_stepper.dart` giữ nguyên logic gốc (vạch xanh khi `index < current`, còn lại xám). Quy tắc màu và cảnh báo về frame `386:2282` đã ghi thẳng vào doc comment của widget để đợt sau không sửa nhầm lần nữa.

## 2026-09-16 (Đợt 54) — `ownedHouseIdsProvider` bám theo nhịp làm mới của `housesProvider`; thống nhất luật mật khẩu toàn app

**1. Quyền sở hữu nhà bị "đóng băng" từ lần đọc đầu tiên.**

`ownedHouseIdsProvider` (`core/providers.dart`) là `FutureProvider` thường và **không được `ref.invalidate` ở bất kỳ đâu trong toàn bộ app** — rà toàn bộ 60 chỗ gọi `invalidate(` không có chỗ nào chạm tới nó. Nghĩa là kết quả của lần đọc đầu tiên được giữ nguyên cho tới khi tắt hẳn app. Tài khoản mới tạo nhà xong, quay lại P-03 "Tài khoản nhận tiền" và P-06 "Tài khoản Quản lý" vẫn báo "Bạn chưa sở hữu nhà nào" (dungtv báo, kèm ảnh chụp cả 2 màn).

**Cách sửa đã chọn: cho provider này phụ thuộc `housesProvider`** (`await ref.watch(housesProvider.future)`), cộng thêm `authStateProvider` để đổi tài khoản không dùng nhầm quyền người cũ.

Cân nhắc 2 phương án: (a) thêm `ref.invalidate(ownedHouseIdsProvider)` vào các màn tạo/xoá nhà; (b) khai báo phụ thuộc. Chọn (b) vì (a) đòi mọi màn viết sau này phải **nhớ** invalidate thêm — mà chính lỗi này sinh ra từ việc quên. Với (b), mọi chỗ đang gọi `ref.invalidate(housesProvider)` (tạo nhà, xoá nhà, kéo xuống làm mới ở Home/Bills, lưu tài khoản ở P-03) tự động kéo theo. Lưu ý đây **không phải** phụ thuộc dữ liệu — quyền sở hữu nằm ở bảng `tb_user_house_access`, không nằm ở `tb_house` — mà là phụ thuộc **nhịp làm mới**, đã ghi rõ trong comment để đợt sau không tưởng thừa rồi gỡ đi.

**2. Lỗi vòng đời widget ở P-03 bị che khuất bởi lỗi trên.**

Vá xong mục 1 thì P-03 crash đỏ màn ngay: `setState() or markNeedsBuild() called during build`. `payout_bank_account_screen.dart` gọi `_selectHouse(...)` (có `setState`) ngay **trong** `build` để chọn sẵn nhà đầu tiên. Lỗi nằm im từ trước vì nhánh đó chưa bao giờ chạy — màn luôn rơi vào nhánh "Bạn chưa sở hữu nhà nào". Bản release **không** đỏ màn vì assert bị tắt, nên dungtv test TestFlight không thấy, nhưng vẫn là sai vòng đời. Tách `_fillForm` (chỉ gán) khỏi `_selectHouse` (`setState` + gán); trong `build` gọi `_fillForm`.

**3. Hai luật mật khẩu khác nhau trong cùng một app.**

P-04 Đổi mật khẩu bắt ≥8 ký tự + ≥1 số + ≥1 chữ hoa, có checklist sống. S-02 Đăng ký và S-04 Quên mật khẩu chỉ kiểm tra `length < 6`. Người dùng đăng ký được bằng `abc123` rồi sau đó **không đổi nổi** sang mật khẩu cùng độ mạnh. dungtv yêu cầu đồng bộ.

**Lấy luật CHẶT hơn (của P-04) làm chuẩn chung**, không hạ P-04 xuống — hạ xuống là làm yếu mật khẩu của toàn bộ tài khoản. Gom vào `core/password_validation.dart` + widget `shared/password_requirements.dart`, cả 3 màn dùng chung. Thêm section i18n `password.*` (3 file en/vi/ko, đã đối chiếu khớp 672 key), xoá 4 key `changePassword.req*`/`requirementsNotMet` và `signup.passwordTooShort` nay không còn ai dùng.

**Lệch so với Figma, cần Dream xác nhận:** frame S-02 Set Password (`347:2941`) **không có** khối checklist — thiết kế chỉ có dòng lỗi đỏ "Passwords do not match". Checklist được thêm vào theo yêu cầu đồng bộ của dungtv, vì nếu chỉ siết luật mà không hiện điều kiện thì người dùng bị chặn mà không biết vì sao. Nếu Dream muốn giữ đúng thiết kế cũ thì gỡ widget đi là xong, luật vẫn giữ nguyên.

## 2026-09-16 (Đợt 55) — Gỡ checklist mật khẩu khỏi S-02/S-04 theo đúng rule bám sát Figma; mọi provider dữ liệu phải phụ thuộc người đang đăng nhập

**1. Checklist mật khẩu chỉ giữ ở P-04 — đúng như Figma.**

Đợt 54 thêm khối checklist 3 điều kiện vào S-02 Đăng ký và S-04 Quên mật khẩu rồi hỏi dungtv có giữ không, vì Figma 2 màn đó không vẽ khối này. dungtv trả lời: *"làm theo đúng rule cái này ko cần dream quyết"* — rule dự án là bám sát Figma, câu hỏi này rule đã trả lời sẵn, không cần hỏi thiết kế. **Đã gỡ checklist khỏi S-02/S-04**, chỉ P-04 giữ (Figma `220:4985` có vẽ). Luật mật khẩu vẫn dùng chung cả 3 màn, không đổi.

Kéo theo một chi tiết bắt buộc: câu lỗi của S-02/S-04 **không được** dùng `password.requirementsNotMet` ("...các điều kiện **ở trên**") như P-04, vì 2 màn này không còn khối nào "ở trên" để người dùng nhìn. Thêm `password.requirementsSummary` — câu tự nêu đủ 3 điều kiện: *"Mật khẩu phải có ít nhất 8 ký tự, 1 chữ số và 1 chữ hoa."*

**Bài học về quy trình:** khi Figma đơn giản là KHÔNG có một thành phần nào đó, đấy không phải mâu thuẫn thiết kế — rule bám sát Figma đã quyết sẵn, cứ áp dụng. Chỉ hỏi khi hai nguồn thiết kế **chọi nhau** (như vụ Stepper ở Đợt 53).

**2. Đăng xuất không dọn dữ liệu đã tải — dữ liệu người trước lọt sang người sau.**

`signOut()` chỉ xoá session, **không** dọn provider nào. Mà `FutureProvider` thường giữ kết quả đã tải suốt vòng đời app (`ProviderScope` gốc tạo 1 lần trong `main.dart`, không bao giờ dựng lại). Hệ quả: người tiếp theo đăng nhập trên cùng máy **nhìn thấy danh sách nhà/người thuê/hợp đồng/hoá đơn của người trước** cho tới khi màn đó tình cờ được làm mới.

**Cách sửa:** thêm `currentUserIdProvider` (`Provider<String?>`), và cho **8 provider gốc** đọc dữ liệu theo tài khoản `ref.watch` nó: `housesProvider`, `roomStatusesByHouseProvider`, `tenantsProvider`, `contractsProvider`, `invoicesProvider`, `managerAccountsProvider`, `activeManagerByHouseProvider`, `notificationsProvider`. Các provider tổng hợp (`tenantListProvider`, `contractListProvider`, `billsHouseGroupsProvider`) tự hưởng vì đều dựng trên nhóm này.

**Vì sao bọc qua `currentUserIdProvider` chứ không watch thẳng `authStateProvider`:** stream đó bắn sự kiện cả khi chỉ **làm mới token** (khoảng 1 tiếng/lần). Watch thẳng thì cứ mỗi lần làm mới token là tải lại toàn bộ danh sách một cách vô ích. `Provider` chỉ báo cho bên phụ thuộc khi **giá trị** đổi, nên bọc qua một `Provider<String?>` thì chỉ **đổi người** mới kích hoạt tải lại. 4 provider trước đây watch thẳng `authStateProvider` (`currentUserNameProvider`, `currentUserProfileProvider`, `isMainManagerProvider`, `ownedHouseIdsProvider`) cũng đã chuyển sang, vừa sửa đúng vấn đề vừa bớt tải thừa.

**Không** chọn phương án dựng lại `ProviderScope` theo user id: gọn hơn thật, nhưng nó xoá sạch cả state không liên quan tài khoản (ngôn ngữ đang chọn) và làm dựng lại toàn bộ cây widget — quá tay so với vấn đề.

**Đã kiểm chứng thật** (`emulator-5554`): đăng xuất rồi đăng nhập lại, chụp liên tục khung hình. Ngay khi Home hiện ra, header đọc **"0 nhà · 0/0 phòng đã thuê"** kèm vòng xoay tải, khung sau mới hiện đủ 6 nhà — tức dữ liệu cũ đã bị bỏ đúng lúc đổi phiên, không bê sang.

**Chưa dựng lại được cảnh lỗi gốc** (người B thấy dữ liệu người A): cần tài khoản thứ hai, mà kho chỉ có 1 tài khoản test. Hai cách rút ngắn đều bị trình phân loại an toàn của Claude Code chặn đúng mực và **không lách**: đọc token OTP trong schema `auth` của production (*Production Reads*), và sửa dữ liệu production để tạo chênh lệch (*Modify Shared Resources*).

## 2026-09-17 (Đợt 56) — Push iOS: phải tự gọi `registerForRemoteNotifications()` trong AppDelegate, plugin không còn tự gọi

**Triệu chứng**: Android nhận push ngon từ 16/09, còn iOS **không bao giờ** có dòng nào trong `tb_device_token` — dù quyền thông báo đã bật, dù bản TestFlight lẫn bản cài trực tiếp, dù đã vá chuyện chờ APNs token.

**Nguyên nhân gốc**: app **chưa bao giờ gọi `registerForRemoteNotifications()`**. Apple không từ chối — không ai hỏi Apple cả.

Plugin `firebase_messaging` gọi hàm này trong hook `didFinishLaunchingWithOptions` của chính nó. Nhưng Flutter 3.47 dùng **mẫu AppDelegate mới**: plugin được đăng ký trong `didInitializeImplicitFlutterEngine`, **chạy SAU** `didFinishLaunchingWithOptions`. Hook của plugin không bao giờ tới lượt, lời gọi đăng ký APNs biến mất — **không lỗi, không log, không crash**. Android không dính vì Android không có bước đăng ký với Apple.

**Sửa**: gọi thẳng `application.registerForRemoteNotifications()` trong `didFinishLaunchingWithOptions` của `ios/Runner/AppDelegate.swift`. Đúng chuẩn Apple và **không cần quyền thông báo trước** — đăng ký nhận remote notification và xin quyền hiện banner là hai việc tách rời, Apple vẫn cấp device token khi chưa bấm Allow.

**Cách khoanh ra được** (đáng ghi lại vì lỗi thuộc loại im lặng tuyệt đối):
1. Thêm `PushStatus` + `diagnose()` hiện trạng thái ở cuối tab Hồ sơ — biết được chết ở bước nào thay vì đoán. Đọc ra "chưa lấy được mã APNs của Apple" ⇒ Firebase OK, quyền OK.
2. Override **cả hai** callback APNs (`didRegisterForRemoteNotificationsWithDeviceToken` và `didFailToRegisterForRemoteNotificationsWithError`) trong AppDelegate, ghi kết quả vào `UserDefaults` khoá `flutter.push.apnsNativeStatus` cho Dart đọc. **Cả hai đều im** ⇒ chưa từng gọi đăng ký. Đây mới là bước chốt: nếu Apple từ chối thì phải có dòng lỗi.

**Hạ tầng test rút ngắn được**: iPhone dungtv paired sẵn và cùng mạng nội bộ ⇒ `xcrun devicectl` cài + chạy app **qua mạng, không cáp, không TestFlight**. Nhưng phải dựng bản **ad-hoc** (`flutter build ipa --export-method ad-hoc`) chứ không phải bản Development: ad-hoc mới ra `aps-environment = production` khớp cấu hình APNs của dự án; bản Development ra `development` (sandbox) nên kết quả test vô nghĩa. Vòng lặp từ ~30 phút xuống ~2 phút.

**Đã verify thật**: `tb_device_token` có đủ 2 dòng `ios` + `android` của `84356123970`; gọi `send-notification` trả `{"recipientCount":2,"sent":2}`.

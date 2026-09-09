# CURRENT_STATUS.md — Trạng thái hiện tại

## Giai đoạn

✅ **Cập nhật 2026-09-09 (đợt 4):** Xử lý 3 phát hiện mới từ `PHASE1GAPANALYSISV3.md` (xem [DECISIONS.md](DECISIONS.md)): (A) **mất SIM + quên mật khẩu cùng lúc** → chốt Phase 1 không xử lý (sơ suất người dùng), Phase 2 thêm khôi phục qua OTP email (`email` khi đó bắt buộc) — nhân tiện bổ sung cột `tb_user.email` (optional) đang thiếu trong `DATABASE.md`; (B) **thêm ràng buộc Tenant phải cùng nhà với hợp đồng** khi tạo ở T-04 — hỗ trợ chọn Nhà/phòng trước (lọc Tenant Pool theo nhà) hoặc Tenant trước (lọc Nhà/phòng theo Tenant), thêm `BR-CTR-13`/`FR-CTR-11`; (C) **ngôn ngữ SMS/Zalo gửi Tenant cố định cố định tiếng Anh và tiếng Việt ở Phase 1, tiếng việt bên trên tiếng anh bên dưới** ở Phase 1, độc lập với ngôn ngữ UI tài khoản, thêm `BR-NOTI-07`. Đã cập nhật `DATABASE.md`, `BUSINESS-RULES.md`, `REQUIREMENTS.md`, `SCREEN-SPEC.md`, `USER-FLOWS.md`, `DESIGN-SYSTEMS.md`.

✅ **Cập nhật 2026-09-09 (đợt 2-3):** Xử lý 7 điểm phát hiện từ đợt rà soát gap analysis Version 3 (xem `Claude outputs/PHASE1-GAP-ANALYSIS-VERIFICATION.md` + [DECISIONS.md](DECISIONS.md)): (1) `tb_tenant` thêm `houseId` bắt buộc; (2) thêm `BR-METER-14` xử lý sửa chỉ số MOVE_OUT sau khi đã thanh lý; (3) phí dịch vụ/phí định kỳ không chia theo ngày khi đổi khách giữa tháng, tính trọn cho hợp đồng đang Active lúc tạo hoá đơn; (4) làm rõ phòng `FLAT` vẫn ghi chỉ số đầy đủ (chỉ không dùng tính tiền) — có chủ đích; (5) **bỏ hẳn tính năng đổi số điện thoại** (SĐT chỉ xem, không sửa — `BR-ROLE-09`); (6) giữ nguyên nhóm nhà theo `ownerFullName` (chấp nhận rủi ro gõ sai); (7) **hỗ trợ 3 ngôn ngữ ngay từ Phase 1 — English/Tiếng Việt/한국어** (ngôn ngữ khác để Phase 2), chọn ngay tại **P-01** dạng inline picker — **không thêm màn riêng** (sửa lại cùng ngày, đợt 3: ban đầu định thêm màn P-08 rồi bỏ, xem [DECISIONS.md](DECISIONS.md)), tổng vẫn 32 màn. Đã cập nhật `DATABASE.md`, `BUSINESS-RULES.md`, `REQUIREMENTS.md`, `PRODUCT-OVERVIEW.md`, `SCREEN-SPEC.md`, `USER-FLOWS.md`, `DESIGN-SYSTEMS.md`.

✅ **Cập nhật 2026-09-08:** Chốt xong **Version 3** — thay đổi 3 thứ cốt lõi so với Version 2: cấu trúc app 5 menu → 4 tab, thêm nghiệp vụ ghi chỉ số điện/nước (3 loại, bắt buộc tại flow Hợp đồng), hợp đồng nhiều phòng + tự động hoá hoá đơn sâu hơn (chu kỳ tiền nhà, phí dịch vụ/m², mã QR VietQR). Vai trò Chủ nhà/Quản lý đổi sang gắn theo **từng Nhà/Dãy trọ** thay vì gắn vào tài khoản, và tên bảng đổi lại dùng tiền tố `tb_`. **FigJam board `PAuYWdSon7WcPKdRQStoPR` đã cập nhật đầy đủ theo Version 3** (khu vực "Version 3 — CURRENT"). **Toàn bộ `docs/*.md` đã được viết lại theo Version 3** cùng đợt này — xem [DECISIONS.md](DECISIONS.md).

⚠️ Nguồn của đợt cập nhật này: bản chốt "Chốt thay đổi version 3" (Dream, 07/09), chỉ đạo của Mr. Han về nghiệp vụ ghi chỉ số (08/09), kịch bản thật `시뮬레이션 케이스 (Mr.Han).md` dùng kiểm chứng thiết kế, và FigJam board Phase 1 Scope Map.

⚠️ **Tác động tới phần đã build trước đó (quan trọng cho dev):**
- Migration `supabase/migrations/20260903121605_initial_schema.sql` (11 bảng, đã áp lên Supabase dev thật) được viết theo schema **Version 1** — đã lạc hậu từ đợt Version 2, và nay **càng lạc hậu hơn nữa** với Version 3 (khác cả tên bảng lẫn cấu trúc: không tiền tố → tiền tố `tb_`, 1 hợp đồng 1 phòng → nhiều phòng, không có bảng chỉ số → 2 bảng chỉ số mới...). Cần viết migration mới từ đầu.
- Edge Function `generate-invoice` cần viết lại hoàn toàn theo mô hình đọc lại chỉ số đã ghi (thay vì nhận chỉ số nhập tay), hỗ trợ tạo hàng loạt, và sinh mã QR.
- Edge Function `create-manager-user` (tạo tài khoản Manager qua Admin API) **cần xoá hẳn** — không còn phù hợp với mô hình vai trò-theo-từng-nhà.
- Figma wireframe MVP (link tại [DESIGN.md](DESIGN.md)) **đã được build lại theo 32 màn/4 tab Version 3** (08/09/2026) — không còn là bản 22 màn/Version 2 cũ, prototype đã nối lại đầy đủ. Có thể dùng trực tiếp làm nguồn thiết kế khi bắt đầu code UI.

## Đã xong

- [x] Cấu trúc thư mục repo (src/, supabase/, tests/, design/, docs/, changelog/)
- [x] Chốt stack: Flutter (frontend) + Supabase-only (backend, không dùng Vercel)
- [x] Cài Flutter SDK, Supabase CLI, commit + push GitHub (org `townsoft-dev`, repo `biztown-rent`)
- [x] Tạo project Supabase (`rentease`), link CLI, Figma MCP kết nối cho Claude Code
- [x] Chốt kênh thông báo, Auth, state management (Riverpod) — xem [DECISIONS.md](DECISIONS.md)
- [x] `flutter create .` + cấu trúc `lib/` cơ bản (chưa có UI thật theo Version 3)
- [x] Migration schema đầu tiên (11 bảng, theo **Version 1**) đã áp lên Supabase dev — **đã lạc hậu, cần viết lại theo Version 3**
- [x] Khung 3 Edge Functions Version 1 (`generate-invoice`, `send-notification`, `send-otp-sms`) — **cần viết lại đáng kể theo Version 3**, riêng `create-manager-user` (nếu đã có khung) cần xoá hẳn
- [x] Figma wireframe **Version 2** (22 màn hình, 5 menu) — build xong nhưng **đã superseded**, cần build lại 32 màn/4 tab theo Version 3
- [x] **Chốt toàn bộ nội dung Version 3** (07-08/09/2026): cấu trúc 4 tab, nghiệp vụ ghi chỉ số, hợp đồng nhiều phòng, tự động hoá hoá đơn, vai trò theo từng nhà, tiền tố bảng `tb_`
- [x] **FigJam board cập nhật đầy đủ theo Version 3** (khu vực "Version 3 — CURRENT")
- [x] **Toàn bộ `docs/*.md` viết lại theo Version 3** (2026-09-08)
- [x] **Đồng bộ docs theo 3 chỉnh sửa trực tiếp trong FigJam cùng ngày** (đợt 2): bỏ `unitPrice`/`totalAmount` khỏi 2 bảng chỉ số, gộp 3 màn ghi/xem/sửa chỉ số thành 1 màn H-06 (còn 32 màn), làm rõ quan hệ mặc định `recurringFees` house→room — xem [DECISIONS.md](DECISIONS.md)
- [x] **Build lại Figma wireframe theo 32 màn/4 tab Version 3 + nối lại prototype** (đợt 3, cùng ngày): tổ chức lại Home tab đúng 6 màn H-01→H-06 theo SCREEN-SPEC.md (gộp ghi/xem/sửa chỉ số vào H-06, xoá màn trùng lặp "House Detail (Readings)"), bỏ hiển thị mã đồng hồ theo phòng (đúng BR-READ-01), thêm field `recurringFees` mặc định ở House/Room, rà soát và sửa toàn bộ trích dẫn `BR-xxx` cho khớp BUSINESS-RULES.md — xem [DECISIONS.md](DECISIONS.md)

## Còn thiếu để dev thật được (máy local)

- [ ] Android Studio (Android SDK) — cần khi build/test trên Android
- [ ] Xcode đầy đủ + CocoaPods — cần khi build/test trên iOS
- [ ] Tài khoản Apple Developer (cần khi publish lên App Store)
- [ ] Rotate lại Secret key + Access Token (cả 2 đã bị dán vào chat, coi như lộ)

## Đang làm / Tiếp theo

- [ ] **Bổ sung 1 dòng "Ngôn ngữ / Language" vào màn Figma P-01** (inline picker, 3 lựa chọn English/Tiếng Việt/한국어 — mới 09/09/2026, xem [SCREEN-SPEC.md](SCREEN-SPEC.md)) — không cần màn riêng, số màn Figma giữ nguyên 32
- [ ] **Viết migration DB mới từ đầu** theo schema Version 3 ([DATABASE.md](DATABASE.md)) — 12 bảng tiền tố `tb_`, gồm `tb_electricity_reading`/`tb_water_reading` (mới), `tb_contract_room` (mới), gộp `tb_user` (bỏ 2 bảng account cũ), gộp field owner vào `tb_house`, gộp settlement vào `tb_contract`, `tb_tenant` có thêm `houseId` bắt buộc (mới 09/09/2026)
- [ ] Viết lại Edge Function `generate-invoice` (đọc lại chỉ số, hỗ trợ tạo hàng loạt, chu kỳ tiền nhà, phí dịch vụ/m², prorate) + `generate-payment-qr` (mới) + rà soát `send-notification` (thêm nhánh nhắc ghi chỉ số định kỳ) — xem [API.md](API.md)
- [ ] Xoá Edge Function `create-manager-user` (nếu đã có khung) — không còn dùng Supabase Admin API cho việc mời quản lý
- [ ] Chọn nhà cung cấp SMS Việt Nam (eSMS/Speedsms) + đăng ký Zalo ZNS/OA
- [ ] Chọn thư viện/API sinh mã QR chuẩn VietQR/NAPAS-247
- [ ] Tạo project Firebase (miễn phí, chỉ dùng cho FCM push) khi tới lúc code `send-notification` thật
- [ ] Setup Scheduled Trigger (pg_cron) cho job nhắc thanh toán quá hạn + nhắc ghi chỉ số định kỳ
- [ ] Bắt đầu code UI theo thứ tự 4 tab chính trong [USER-FLOWS.md](USER-FLOWS.md), dựa theo Figma Version 3 (đã build xong wireframe + prototype)

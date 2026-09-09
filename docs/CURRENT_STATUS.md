# CURRENT_STATUS.md — Trạng thái hiện tại

## Giai đoạn

✅ **Cập nhật 2026-09-09 (Đồng bộ thiết kế mới nhất lên repo):** File Figma chính thức nay đã phản ánh đúng bản mới nhất — kết hợp phần Dream tự sửa trực tiếp trên Figma (thêm/xoá, căn chỉnh vị trí) + phần Claude/Cowork sửa cùng ngày (dòng Ngôn ngữ P-01, prototype 32 màn, tab House detail/Rooms + nút Edit ở H-03/H-04, dropdown lọc nhà T-02) — xem [DESIGN.md](DESIGN.md) + `changelog/2026-09-09.md` mục 13:45.

✅ **Cập nhật 2026-09-09 (Figma T-02 filter):** Đổi bộ lọc nhà ở **T-02 — Tenant & Contract (Contracts)** từ 4 Chip riêng lẻ ("All houses"/"Binh An"/"Phu Nhuan"/"Tan Binh") thành **1 dropdown duy nhất** ("All houses" + icon `expand_more`) — đúng như `SCREEN-SPEC.md` đã ghi ("Filter theo tên nhà (dropdown)") — xem `changelog/2026-09-09.md` mục 13:35. ⚠️ Phát hiện phụ chưa xử lý: **B-01 — Bills List** đang có đúng pattern 4-chip y hệt, chưa đổi — chờ Dream xác nhận nếu muốn đồng bộ.

✅ **Cập nhật 2026-09-09 (Figma H-03/H-04):** Bổ sung nội dung còn thiếu theo phản hồi của Dream — xem `changelog/2026-09-09.md` mục 13:10. (1) **H-04 Room Detail**: nối nút Edit (⋮, đã có sẵn nhưng chưa nối) → H-05; thêm nút "View reading history" → H-06; sửa lỗi nút "Create contract" hiện sai khi phòng đang Occupied. (2) **H-03 tách 2 tab** qua Segmented control: Tab 1 "House detail" (frame mới — thông tin nhà + chủ nhà + giá mặc định, Edit → H-02) và Tab 2 "Rooms" (danh sách phòng cũ, cũng nối Edit → H-02); tổng màn vẫn 32 (theo tiền lệ H-06). 3 house card ở H-01 nay vào thẳng tab "House detail" trước. ⚠️ **Cần Dream xác nhận**: có muốn đổi lại mặc định về tab "Rooms" như hành vi cũ không.

✅ **Cập nhật 2026-09-09 (Figma prototype):** Rà soát có hệ thống prototype (click → chuyển màn) trên toàn bộ 32 màn qua Figma MCP — xem `changelog/2026-09-09.md` mục 12:15. Xác nhận nút back, 6 dòng menu P-01, FAB, các Button điều hướng chính đều đã nối đầy đủ từ đợt 08/09. Bổ sung: (1) tương tác click cho **Chip** (bộ lọc + 3 chip Ngôn ngữ P-01) và **Segmented control** — nối 1 lần ở component gốc (áp dụng tự động cho mọi instance); (2) 2 liên kết còn thiếu thật sự: T-06 "+ Quick add tenant" → T-04 Tenant Create/Edit, B-04 "Delete draft" → B-01 Bills List.

✅ **Đã xử lý 2026-09-09 (Đợt 6):** Phát hiện phụ "nhãn số màn T-0x lệch Figma" ở mục ngay trên đã xử lý xong — đọc trực tiếp Figma qua MCP, viết lại toàn bộ `SCREEN-SPEC.md` mục 1.4 + 2.3 (Tenant & Contract) khớp đúng theo Figma thật, sửa tham chiếu chéo ở `REQUIREMENTS.md`/`BUSINESS-RULES.md`/`DESIGN-SYSTEMS.md` — xem [DECISIONS.md](DECISIONS.md) 2026-09-09 (Đợt 6) cho bảng mapping số cũ→mới đầy đủ. Phát hiện thêm 1 màn Figma có nhưng docs cũ chưa mô tả (**T-03 Tenant Detail View**, đã viết spec mới) và xác nhận Renew/Amend **gộp chung 1 màn** trên Figma (khác mô tả cũ).

✅ **Đã xử lý 2026-09-09 (Đợt 7):** Khoảng trống "Amend đổi danh sách phòng" ở mục ngay trên đã chốt xong — **bỏ hẳn khỏi Phase 1** (dời Phase 2), không cần hỏi lại Dream vì đã đủ căn cứ kỹ thuật (tránh phải thêm versioning cho `tb_contract_room`) + nghiệp vụ (đổi phòng = kết thúc hợp đồng cũ + tạo hợp đồng mới). Cập nhật `BUSINESS-RULES.md`, `REQUIREMENTS.md`, `PRODUCT-OVERVIEW.md`, `USER-FLOWS.md`, `SCREEN-SPEC.md` — xem [DECISIONS.md](DECISIONS.md) 2026-09-09 (Đợt 7).

✅ **Cập nhật 2026-09-09 (đợt 5):** Sửa lại 1 phần quyết định đợt 4 + bổ sung thiếu sót (xem [DECISIONS.md](DECISIONS.md)): (1) **ngôn ngữ SMS/Zalo gửi Tenant đổi từ tiếng Anh → tiếng Việt** (bỏ phương án song ngữ Anh+Việt Dream thử trước đó vì làm tăng độ dài tin nhắn, đội chi phí gửi tin), cập nhật `BR-NOTI-07`, `FR-NOTI-02`, `DESIGN-SYSTEMS.md` mục 0; (2) bổ sung tham chiếu `BR-CTR-13` còn thiếu trong `DATABASE.md` (mô tả field `tenantId` của `tb_contract`); (3) **cập nhật `CHANGELOG.md`** (file gốc, khác `changelog/*.md`) cho toàn bộ đợt 2-5 trong ngày — đóng phát hiện D còn tồn đọng từ gap analysis.

✅ **Cập nhật 2026-09-09 (đợt 4):** Xử lý 3 phát hiện mới từ `PHASE1GAPANALYSISV3.md` (xem [DECISIONS.md](DECISIONS.md)): (A) **mất SIM + quên mật khẩu cùng lúc** → chốt Phase 1 không xử lý (sơ suất người dùng), Phase 2 thêm khôi phục qua OTP email (`email` khi đó bắt buộc) — nhân tiện bổ sung cột `tb_user.email` (optional) đang thiếu trong `DATABASE.md`; (B) **thêm ràng buộc Tenant phải cùng nhà với hợp đồng** khi tạo ở T-04 — hỗ trợ chọn Nhà/phòng trước (lọc Tenant Pool theo nhà) hoặc Tenant trước (lọc Nhà/phòng theo Tenant), thêm `BR-CTR-13`/`FR-CTR-11`; (C) **ngôn ngữ SMS/Zalo gửi Tenant cố định tiếng Anh** ở Phase 1 (sửa lại thành tiếng Việt ở đợt 5 — xem trên), độc lập với ngôn ngữ UI tài khoản, thêm `BR-NOTI-07`. Đã cập nhật `DATABASE.md`, `BUSINESS-RULES.md`, `REQUIREMENTS.md`, `SCREEN-SPEC.md`, `USER-FLOWS.md`, `DESIGN-SYSTEMS.md`.

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
- [x] **Bổ sung dòng "Ngôn ngữ / Language" vào màn Figma P-01** (09/09/2026, qua Claude/Cowork): icon `language` + nhãn + 3 chip **EN/VI/KO** (EN mặc định), đặt trong section "Other" giữa "Notification center" và "Log out", dùng đúng component Chip + token màu/bo góc sẵn có trong Design System V3; tăng khung màn P-01 829→883px để không cắt Banner phía dưới — không mở màn riêng, số màn Figma vẫn giữ nguyên 32. FigJam board (shape "Menu: Language Setting P-08") do Dream tự sửa lại, không thuộc phần việc này.
- [x] **Bổ sung nội dung H-03 (tách tab House detail/Rooms) + sửa H-04 (nút Edit phòng)** (09/09/2026, qua Claude/Cowork) — xem `changelog/2026-09-09.md` mục 13:10: H-04 nối Edit (⋮)→H-05, thêm "View reading history"→H-06, sửa lỗi hiện sai nút "Create contract"; H-03 tách 2 tab qua Segmented control (House detail + Rooms), Edit (⋮) cả 2 tab →H-02, H-01 nay vào thẳng tab House detail trước — tổng màn vẫn 32. Chờ Dream xác nhận tab mặc định từ H-01.

## Còn thiếu để dev thật được (máy local)

- [ ] Android Studio (Android SDK) — cần khi build/test trên Android
- [ ] Xcode đầy đủ + CocoaPods — cần khi build/test trên iOS
- [ ] Tài khoản Apple Developer (cần khi publish lên App Store)
- [ ] Rotate lại Secret key + Access Token (cả 2 đã bị dán vào chat, coi như lộ)

## Đang làm / Tiếp theo

- [ ] **Viết migration DB mới từ đầu** theo schema Version 3 ([DATABASE.md](DATABASE.md)) — 12 bảng tiền tố `tb_`, gồm `tb_electricity_reading`/`tb_water_reading` (mới), `tb_contract_room` (mới), gộp `tb_user` (bỏ 2 bảng account cũ), gộp field owner vào `tb_house`, gộp settlement vào `tb_contract`, `tb_tenant` có thêm `houseId` bắt buộc (mới 09/09/2026)
- [ ] Viết lại Edge Function `generate-invoice` (đọc lại chỉ số, hỗ trợ tạo hàng loạt, chu kỳ tiền nhà, phí dịch vụ/m², prorate) + `generate-payment-qr` (mới) + rà soát `send-notification` (thêm nhánh nhắc ghi chỉ số định kỳ) — xem [API.md](API.md)
- [ ] Xoá Edge Function `create-manager-user` (nếu đã có khung) — không còn dùng Supabase Admin API cho việc mời quản lý
- [ ] Chọn nhà cung cấp SMS Việt Nam (eSMS/Speedsms) + đăng ký Zalo ZNS/OA
- [ ] Chọn thư viện/API sinh mã QR chuẩn VietQR/NAPAS-247
- [ ] Tạo project Firebase (miễn phí, chỉ dùng cho FCM push) khi tới lúc code `send-notification` thật
- [ ] Setup Scheduled Trigger (pg_cron) cho job nhắc thanh toán quá hạn + nhắc ghi chỉ số định kỳ
- [ ] Bắt đầu code UI theo thứ tự 4 tab chính trong [USER-FLOWS.md](USER-FLOWS.md), dựa theo Figma Version 3 (đã build xong wireframe + prototype)

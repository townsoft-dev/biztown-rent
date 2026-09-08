# CURRENT_STATUS.md — Trạng thái hiện tại

## Giai đoạn

✅ **Cập nhật 2026-09-08:** Chốt xong **Version 3** — thay đổi 3 thứ cốt lõi so với Version 2: cấu trúc app 5 menu → 4 tab, thêm nghiệp vụ ghi chỉ số điện/nước (3 loại, bắt buộc tại flow Hợp đồng), hợp đồng nhiều phòng + tự động hoá hoá đơn sâu hơn (chu kỳ tiền nhà, phí dịch vụ/m², mã QR VietQR). Vai trò Chủ nhà/Quản lý đổi sang gắn theo **từng Nhà/Dãy trọ** thay vì gắn vào tài khoản, và tên bảng đổi lại dùng tiền tố `tb_`. **FigJam board `PAuYWdSon7WcPKdRQStoPR` đã cập nhật đầy đủ theo Version 3** (khu vực "Version 3 — CURRENT"). **Toàn bộ `docs/*.md` đã được viết lại theo Version 3** cùng đợt này — xem [DECISIONS.md](DECISIONS.md).

⚠️ Nguồn của đợt cập nhật này: bản chốt "Chốt thay đổi version 3" (Dream, 07/09), chỉ đạo của Mr. Han về nghiệp vụ ghi chỉ số (08/09), kịch bản thật `시뮬레이션 케이스 (Mr.Han).md` dùng kiểm chứng thiết kế, và FigJam board Phase 1 Scope Map.

⚠️ **Tác động tới phần đã build trước đó (quan trọng cho dev):**
- Migration `supabase/migrations/20260903121605_initial_schema.sql` (11 bảng, đã áp lên Supabase dev thật) được viết theo schema **Version 1** — đã lạc hậu từ đợt Version 2, và nay **càng lạc hậu hơn nữa** với Version 3 (khác cả tên bảng lẫn cấu trúc: không tiền tố → tiền tố `tb_`, 1 hợp đồng 1 phòng → nhiều phòng, không có bảng chỉ số → 2 bảng chỉ số mới...). Cần viết migration mới từ đầu.
- Edge Function `generate-invoice` cần viết lại hoàn toàn theo mô hình đọc lại chỉ số đã ghi (thay vì nhận chỉ số nhập tay), hỗ trợ tạo hàng loạt, và sinh mã QR.
- Edge Function `create-manager-user` (tạo tài khoản Manager qua Admin API) **cần xoá hẳn** — không còn phù hợp với mô hình vai trò-theo-từng-nhà.
- Figma wireframe MVP hiện tại (link tại [DESIGN.md](DESIGN.md)) vẫn là **22 màn hình theo Version 2** — cần build lại theo 32 màn/4 tab của [SCREEN-SPEC.md](SCREEN-SPEC.md) trước khi code UI theo Version 3.

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

## Còn thiếu để dev thật được (máy local)

- [ ] Android Studio (Android SDK) — cần khi build/test trên Android
- [ ] Xcode đầy đủ + CocoaPods — cần khi build/test trên iOS
- [ ] Tài khoản Apple Developer (cần khi publish lên App Store)
- [ ] Rotate lại Secret key + Access Token (cả 2 đã bị dán vào chat, coi như lộ)

## Đang làm / Tiếp theo

- [ ] **Viết migration DB mới từ đầu** theo schema Version 3 ([DATABASE.md](DATABASE.md)) — 12 bảng tiền tố `tb_`, gồm `tb_electricity_reading`/`tb_water_reading` (mới), `tb_contract_room` (mới), gộp `tb_user` (bỏ 2 bảng account cũ), gộp field owner vào `tb_house`, gộp settlement vào `tb_contract`
- [ ] Viết lại Edge Function `generate-invoice` (đọc lại chỉ số, hỗ trợ tạo hàng loạt, chu kỳ tiền nhà, phí dịch vụ/m², prorate) + `generate-payment-qr` (mới) + rà soát `send-notification` (thêm nhánh nhắc ghi chỉ số định kỳ) — xem [API.md](API.md)
- [ ] Xoá Edge Function `create-manager-user` (nếu đã có khung) — không còn dùng Supabase Admin API cho việc mời quản lý
- [ ] Chọn nhà cung cấp SMS Việt Nam (eSMS/Speedsms) + đăng ký Zalo ZNS/OA
- [ ] Chọn thư viện/API sinh mã QR chuẩn VietQR/NAPAS-247
- [ ] Tạo project Firebase (miễn phí, chỉ dùng cho FCM push) khi tới lúc code `send-notification` thật
- [ ] Setup Scheduled Trigger (pg_cron) cho job nhắc thanh toán quá hạn + nhắc ghi chỉ số định kỳ
- [ ] Bắt đầu code UI theo thứ tự 4 tab chính trong [USER-FLOWS.md](USER-FLOWS.md), dựa theo Figma Version 3 sau khi build xong

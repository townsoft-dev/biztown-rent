# Screen Spec — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 3 — **viết lại toàn bộ theo cấu trúc 4 tab** (2026-09-08)
> **Thay đổi lớn:** Đổi cấu trúc từ **5 menu → 4 tab** (bottom nav): Home, Tenant & Contract, Bills, Profile. Tổng số màn hình tăng từ **22 → 32** (+10): thêm nghiệp vụ ghi chỉ số điện/nước (1 màn gộp), tách View/Create-Edit của Phòng, tách Renew/Amend hợp đồng, thêm Invoice Schedule Preview, thêm tạo hoá đơn hàng loạt + Send Invoice sheet, thêm màn gốc tab Profile + Payout bank account + Change password. Xem [DECISIONS.md](DECISIONS.md) 2026-09-08 và [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.
> **Cập nhật 09/08 (sửa trực tiếp trong FigJam):** gộp 3 màn ghi/xem/sửa chỉ số (H-06 Reading Entry, H-07 Reading History, H-08 Reading Correction) thành **1 màn duy nhất H-06 — Record Monthly Reading (PERIODIC)**: liệt kê theo phòng (entry), tap vào 1 phòng ra detail view (lịch sử theo `previousReadingId`), sửa được ngay tại đó khi `isLocked=false`. Tổng màn hình Home giảm từ 8 → 6, tổng toàn app từ 34 → 32.

---

## 1. Screen Inventory (Phase 1 — Version 3)

### 1.1 Chung (Shared) — 4 màn

| # | Màn hình | Ghi chú |
|---|---|---|
| S-00 | Splash | |
| S-01 | Đăng nhập (SĐT + Mật khẩu / OTP) | Dùng chung cho **mọi người** — không còn bước chọn vai trò |
| S-02 | Đăng ký (SĐT & OTP) | Dùng chung cho **mọi người** — bỏ hẳn khái niệm "chỉ Landlord tự đăng ký" của Version 2 |
| S-03 | Trung tâm thông báo | |

### 1.2 Bottom Navigation — 4 tab chính

| Tab | Icon gợi ý | Màn hình con |
|---|---|---|
| 1. Home | nhà/lưới phòng | H-01 → H-06 |
| 2. Tenant & Contract | người + hợp đồng (segmented control) | T-01 → T-10 |
| 3. Bills (core) | hoá đơn | B-01 → B-05 |
| 4. Profile | hồ sơ | P-01 → P-07 |

### 1.3 Home (H) — 6 màn

| # | Màn hình | Ghi chú |
|---|---|---|
| H-01 | Home (House List) | Danh sách Nhà/Dãy trọ, nhóm theo chủ sở hữu hiển thị nếu có nhiều nhà chung 1 chủ |
| H-02 | House Registration (Create/Edit) | Gồm cả thông tin chủ sở hữu hiển thị + tài khoản ngân hàng nhận tiền + đơn giá phí dịch vụ/m² mặc định + phí định kỳ mặc định (`recurringFees`, autofill cho phòng mới) |
| H-03 | Room List (theo 1 House) | Filter theo trạng thái |
| H-04 | Room Detail (View) | **Tách riêng khỏi Create/Edit** (khác Version 2) |
| H-05 | Room Create/Edit | |
| H-06 | Record Monthly Reading (PERIODIC) | **Gộp 3 màn cũ (Reading Entry + Reading History + Reading Correction) thành 1** (09/08, sửa trực tiếp trong FigJam) — liệt kê theo phòng, nhập chỉ số mới; tap vào 1 phòng ra detail view (lịch sử `previousReadingId`); sửa ngay tại đó khi `isLocked=false`. Chỉ ghi `PERIODIC` — `MOVE_IN`/`MOVE_OUT` vẫn nằm trong flow Hợp đồng (T-04/T-05), không gộp vào đây |

### 1.4 Tenant & Contract (T) — 10 màn

| # | Màn hình | Ghi chú |
|---|---|---|
| T-01 | Tenant Pool List | |
| T-02 | Tenant Profile (Create/Edit) | Có thể mở shortcut từ T-04 |
| T-03 | Contract List | Filter theo nhà, sắp hết hạn |
| T-04 | Create Contract | Chọn 1..N phòng cùng 1 nhà; chặn nếu thiếu chỉ số nhận phòng |
| T-05 | Contract Detail | Điểm vào Renew/Amend/Kết thúc/Version History/Invoice Schedule |
| T-06 | Renew Contract | **Tách riêng khỏi T-05** (khác Version 2) |
| T-07 | Amend Contract | **Tách riêng khỏi T-05**, gồm cả đổi danh sách phòng |
| T-08 | Version History | Danh sách `tb_contract_version` theo thời gian |
| T-09 | Invoice Schedule Preview | Bản xem trước các kỳ hoá đơn sắp tới của hợp đồng (chip "Scheduled") — mới |
| T-10 | End Contract (Settlement) | Chặn nếu thiếu chỉ số trả phòng; đối soát cọc & công nợ |

### 1.5 Bills (B) — 5 màn (core)

| # | Màn hình | Ghi chú |
|---|---|---|
| B-01 | Invoice List | Nhóm theo Nhà → theo Hợp đồng; chip "Scheduled" cho kỳ tương lai |
| B-02 | Create Invoice — Batch | Chọn 1 nhà + 1 kỳ → tạo hàng loạt — mới |
| B-03 | Create Invoice — Single | Tạo cho 1 hợp đồng cụ thể |
| B-04 | Send Invoice Sheet | Bottom sheet: xem QR, chọn kênh gửi — dùng chung B-02/B-03 — mới |
| B-05 | Invoice Detail | Xem chi tiết, đánh dấu Collected |

### 1.6 Profile (P) — 7 màn

| # | Màn hình | Ghi chú |
|---|---|---|
| P-01 | Profile (màn gốc tab) | Danh mục điều hướng tới P-02 → P-07 — mới |
| P-02 | Personal Profile (Detail/Edit) | Họ tên, SĐT, CCCD... dùng chung mọi tài khoản |
| P-03 | Payout Bank Account | Theo TỪNG Nhà/Dãy trọ, không phải theo cá nhân — mới |
| P-04 | Change Password | Tách riêng khỏi luồng quên mật khẩu — mới |
| P-05 | House Access List ("Người quản lý nhà") | Đổi tên từ "Danh sách Manager của tôi" (Version 2) |
| P-06 | House Access Detail (Invite/Edit theo House) | Mời bằng SĐT — không tạo tài khoản, không đặt mật khẩu |
| P-07 | Xác nhận Đăng xuất | Dialog |

**Tổng: 4 (Shared) + 6 (Home) + 10 (Tenant & Contract) + 5 (Bills) + 7 (Profile) = 32 màn hình.**



---

## 2. Đặc tả chi tiết

> Template: **Mục đích → Thành phần chính → Trạng thái (states) → Hành động & điều hướng → Dữ liệu hiển thị → Edge cases**

## 2.1 Shared (S-00 → S-03)

### S-00 — Splash
- **Mục đích:** Màn hình mở app, kiểm tra session hiện có.
- **Thành phần chính:** Logo BizTown Rent-Manager (nền navy), tagline.
- **Trạng thái:** Đang kiểm tra session (hiển thị greeting).
- **Hành động & điều hướng:** Không có session/hết hạn → S-01. Có session hợp lệ → H-01 (Home).
- **Edge cases:** Mạng chậm → timeout hợp lý (10s), không treo màn hình.

### S-01 — Đăng nhập
- **Mục đích:** Xác thực **bất kỳ tài khoản nào** bằng SĐT + Mật khẩu (hoặc OTP) — 1 màn duy nhất cho mọi người, không còn khái niệm "loại tài khoản".
- **Thành phần chính:** Input SĐT, input Mật khẩu, nút "Đăng nhập", link "Quên mật khẩu", link "Chưa có tài khoản? Đăng ký" → S-02.
- **Trạng thái:** Nhập liệu / Lỗi (sai SĐT/mật khẩu).
- **Hành động & điều hướng:** Đăng nhập thành công → H-01 (Home, liệt kê mọi nhà đang có quyền).
- **Dữ liệu hiển thị:** Không.
- **Edge cases:** Sai mật khẩu nhiều lần → rate-limit (khoá tạm 10 phút sau 5 lần sai).

### S-02 — Đăng ký (SĐT & OTP)
- **Mục đích:** Tạo tài khoản mới — dùng chung cho mọi người, không phân biệt sẽ là chủ nhà hay quản lý.
- **Thành phần chính:** Input SĐT + nút gửi OTP; 6 ô nhập OTP + đếm ngược 2 phút + gửi lại; bước tạo mật khẩu (2 field) sau khi OTP đúng.
- **Trạng thái:** Nhập SĐT → Đang gửi OTP → Nhập OTP → (sai/hết hạn) → Tạo mật khẩu → Hoàn tất.
- **Hành động & điều hướng:** Hoàn tất → H-01. Nếu tài khoản đã có sẵn dòng quyền được mời trước đó (do một chủ nhà khác mời bằng SĐT này) → Home hiện sẵn nhà đó, kèm thông báo.
- **Dữ liệu hiển thị:** Không.
- **Edge cases:** SĐT đã tồn tại → gợi ý chuyển sang S-01.

### S-03 — Trung tâm thông báo
- **Mục đích:** Tập trung thông báo (FR-NOTI-01→04).
- **Thành phần chính:** List thông báo (icon theo loại, tiêu đề, tóm tắt, thời gian tương đối, chấm chưa đọc), tab "Tất cả"/"Chưa đọc".
- **Trạng thái:** Có thông báo / Rỗng.
- **Hành động & điều hướng:** Tap → đánh dấu đã đọc + điều hướng: hoá đơn mới/nhắc thanh toán → B-05; hợp đồng sắp hết hạn → T-05; **đến hạn ghi chỉ số định kỳ** (BR-NOTI-05) → H-06 (Reading Entry) đúng nhà liên quan; được mời làm quản lý → P-05.
- **Dữ liệu hiển thị:** Theo BR-NOTI-01→06.
- **Edge cases:** Thông báo trỏ tới thực thể đã xoá → hiện "Không tìm thấy dữ liệu".

---

## 2.2 Home (H-01 → H-06)

### H-01 — Home (House List)
- **Mục đích:** Điểm vào chính (tab 1) — liệt kê Nhà/Dãy trọ đang có quyền truy cập.
- **Thành phần chính:** Header (lời chào + chuông → S-03), list card mỗi Nhà/Dãy trọ (ảnh, tên, địa chỉ rút gọn, tỉ lệ "x/y phòng trống"), **nhóm các nhà có chung chủ sở hữu thành 1 cụm** (đường kẻ nhạt màu, tên chủ phía trên cụm), nút nổi "+", Bottom Navigation.
- **Trạng thái:** Có dữ liệu / Rỗng (CTA "Thêm Nhà/Dãy trọ đầu tiên" → H-02, hoặc "Chưa được ai cấp quyền, chờ được mời").
- **Hành động & điều hướng:** Tap card → H-03. Tap "+" → H-02.
- **Dữ liệu hiển thị:** Mọi `tb_house` có dòng `tb_user_house_access` (bất kỳ role) khớp tài khoản đang đăng nhập.
- **Edge cases:** Nhiều Nhà/Dãy trọ thuộc nhiều chủ khác nhau (Persona C — quản lý hộ nhiều chủ trọ) → cần search/sort nếu danh sách dài.

### H-02 — House Registration (Create/Edit)
- **Mục đích:** Tạo/sửa 1 Nhà/Dãy trọ, gồm cả thông tin chủ sở hữu hiển thị và tài khoản nhận tiền.
- **Thành phần chính:** Ảnh (nhiều ảnh), Tên (bắt buộc), Địa chỉ (bắt buộc), Loại nhà (Dãy trọ/Căn hộ, bắt buộc), Mô tả (optional), **Tên chủ sở hữu hiển thị** (bắt buộc — có thể khác tài khoản đang tạo, VD tên vợ/con), CCCD chủ sở hữu (optional), Mã số thuế (optional), **Tài khoản ngân hàng nhận tiền** (tên NH, số TK, mã BIN — bắt buộc để sinh QR sau này, có thể bỏ qua lúc tạo và bổ sung sau ở P-03), **Đơn giá phí dịch vụ/m² mặc định** (optional, chỉ để tự động điền khi tạo hợp đồng), nút Lưu/Huỷ.
- **Trạng thái:** Tạo mới / Chỉnh sửa / Lỗi validate. Chỉ `role=owner` của nhà này được sửa (khi Edit).
- **Hành động & điều hướng:** Lưu → H-01. Nếu tạo mới → tự sinh dòng quyền `role=owner` cho người tạo.
- **Dữ liệu hiển thị:** Thông tin nhà (nếu sửa).
- **Edge cases:** Trùng tên trong cùng phạm vi → cảnh báo, không chặn. Xoá nhà đang có phòng còn hợp đồng Active → chặn.

### H-03 — Room List (theo 1 House)
- **Mục đích:** Xem toàn bộ phòng trong 1 Nhà/Dãy trọ.
- **Thành phần chính:** Header tên nhà, chip filter (Tất cả/Empty/Occupied/UnderRepair), list card phòng (ảnh, số phòng, diện tích, giá tham khảo, badge trạng thái), nút nổi "+", nút "Ghi chỉ số kỳ này" → H-06.
- **Trạng thái:** Theo filter / Rỗng.
- **Hành động & điều hướng:** Tap card → H-04. Tap "+" → H-05 (gắn sẵn house).
- **Dữ liệu hiển thị:** Phòng thuộc nhà đã chọn.
- **Edge cases:** Chưa có phòng nào → empty state + CTA.

### H-04 — Room Detail (View)
- **Mục đích:** Xem chi tiết 1 phòng, điểm vào Contract (nếu Empty) hoặc xem hợp đồng hiện tại (nếu Occupied), và xem lịch sử chỉ số.
- **Thành phần chính:** Ảnh, số phòng, diện tích, giá tham khảo, tiện ích, phí định kỳ mặc định, badge trạng thái, nút "Sửa" → H-05, nút "Xem lịch sử chỉ số" → H-06 (mở thẳng detail view của phòng này), nút "Tạo hợp đồng" (chỉ hiện khi Empty) → T-04, hoặc thẻ tóm tắt hợp đồng hiện tại (khi Occupied) → T-05.
- **Trạng thái:** Empty / Occupied / UnderRepair.
- **Hành động & điều hướng:** Tap "Sửa" → H-05. Tap hợp đồng hiện tại → T-05.
- **Dữ liệu hiển thị:** Thông tin phòng + trạng thái.
- **Edge cases:** Xoá phòng đang có hợp đồng Active → chặn (nút xoá không hiện, chỉ hiện ở H-05 khi Empty).

### H-05 — Room Create/Edit
- **Mục đích:** Tạo/sửa 1 Phòng. **Tách riêng khỏi màn View** (khác Version 2, nơi gộp chung 1 màn theo trạng thái).
- **Thành phần chính:** Ảnh (nhiều ảnh, tối thiểu 1), Số phòng (bắt buộc), **Diện tích m² (bắt buộc)**, Giá tham khảo/tháng (bắt buộc), Tiện ích (danh sách), Phí định kỳ mặc định (tên + số tiền, optional), Trạng thái (UnderRepair set tay, Empty/Occupied do hệ thống set), nút Lưu/Huỷ, nút "Xoá" (chỉ hiện khi Empty và chưa từng có hợp đồng, hoặc Empty không có hợp đồng Active).
- **Trạng thái:** Tạo mới / Chỉnh sửa / Lỗi validate (thiếu diện tích → chặn lưu).
- **Hành động & điều hướng:** Lưu → H-03 hoặc H-04 (nếu sửa từ đó).
- **Dữ liệu hiển thị:** Thông tin phòng (nếu sửa).
- **Edge cases:** Trùng số phòng trong cùng nhà → cảnh báo, không chặn. Sửa diện tích của phòng đang có hợp đồng Active → cảnh báo "không ảnh hưởng tới hợp đồng hiện tại" (vì `contractAreaSqm` đã chốt cứng — BR-VER-06).

### H-06 — Record Monthly Reading (PERIODIC)
> **Gộp 3 màn cũ của bản draft trước (09/08, sửa trực tiếp trong FigJam):** Reading Entry + Reading History + Reading Correction nay là **1 màn duy nhất**, đúng theo ghi chú trên node FigJam: *"reading, detail view, edit chỉ sửa được khi isLocked = false"*. Màn này **chỉ xử lý `PERIODIC`** — `MOVE_IN`/`MOVE_OUT` vẫn là bước bắt buộc riêng trong flow Hợp đồng (T-04 khi nhận phòng, T-05/T-09 khi trả phòng), **không** gộp vào đây.
- **Mục đích:** Ghi chỉ số điện/nước **định kỳ hàng tháng** cho MỌI phòng của 1 nhà (kể cả phòng trống), xem chi tiết lịch sử theo từng phòng, và sửa tại chỗ khi chưa lên hoá đơn — cả 3 việc trong cùng 1 màn hình.
- **Thành phần chính:**
  - **View liệt kê (entry):** Header tên nhà + kỳ (tháng/năm), list mọi phòng của nhà (số phòng, chỉ số cũ hiển thị sẵn để đối chiếu, input chỉ số điện mới, input chỉ số nước mới — bỏ qua phòng cấu hình `NOT_BILLED`), tuỳ chọn chụp ảnh công tơ từng phòng (optional), nút "Lưu tất cả".
  - **View chi tiết (detail, tap vào 1 phòng):** Timeline lịch sử chỉ số của phòng đó theo thời gian, mỗi dòng: loại (badge PERIODIC/MOVE_IN/MOVE_OUT), ngày ghi, chỉ số cũ→mới, lượng dùng, người ghi, cờ đã lên hoá đơn (khoá, `isLocked`).
  - **Edit tại chỗ (chỉ khi `isLocked=false`):** input chỉ số mới đè lên dòng đang xem, ảnh công tơ (nếu có), ghi chú lý do sửa (optional), nút Lưu/Huỷ ngay trong cùng view chi tiết — không chuyển màn.
- **Trạng thái:** Nhập liệu / Đã lưu một phần (cho phép lưu dở, quay lại sau) / Hoàn tất / Xem chi tiết / Sửa (khi `isLocked=false`) / Chỉ xem, không sửa được (khi `isLocked=true`).
- **Hành động & điều hướng:** Lưu (view liệt kê) → tạo bản ghi `tb_electricity_reading`/`tb_water_reading` (`readingType=PERIODIC`) cho từng phòng đã nhập, nối `previousReadingId` theo đúng phòng → quay lại H-03. Tap 1 phòng → view chi tiết cùng màn. Lưu (edit tại chỗ, chỉ khi chưa khoá) → cập nhật `usageAmount`, quay lại view chi tiết của phòng đó.
- **Dữ liệu hiển thị:** Chỉ số cũ gần nhất của từng phòng (bất kể loại — PERIODIC/MOVE_IN/MOVE_OUT); ở view chi tiết là toàn bộ bản ghi của phòng, nối theo `previousReadingId` (nguồn sự thật, không phải `previousReading` snapshot).
- **Edge cases:** Chỉ số mới < chỉ số cũ → chặn ngay tại dòng đó, không chặn lưu các phòng khác. Đã có bản ghi `PERIODIC` của kỳ này cho 1 phòng → phòng đó hiện read-only ở view liệt kê, mở view chi tiết nếu cần xem/sửa. Bản ghi đã khoá (`isLocked=true`) → view chi tiết chỉ hiện chỉ đọc, không có nút Sửa; hiện thông báo "Chỉ số đã lên hoá đơn, không thể sửa trực tiếp — điều chỉnh qua hoá đơn kế tiếp (BR-METER-13)". Phát hiện đứt chuỗi `previousReadingId` (dữ liệu lỗi) → cảnh báo kỹ thuật, không chặn xem.

---

## 2.3 Tenant & Contract (T-01 → T-10)

### T-01 — Tenant Pool List
- **Mục đích:** Quản lý "kho" hồ sơ Tenant dùng chung theo Nhà/Dãy trọ.
- **Thành phần chính:** Ô tìm kiếm (tên/SĐT), chip filter (Tất cả/Chưa gắn phòng/Đang thuê), list mỗi Tenant (avatar, họ tên, SĐT, trạng thái gắn phòng), nút nổi "+".
- **Trạng thái:** Có dữ liệu / Rỗng.
- **Hành động & điều hướng:** Tap "+" → T-02. Tap 1 Tenant → T-02 (xem/sửa).
- **Dữ liệu hiển thị:** Tenant thuộc phạm vi các nhà đang có quyền truy cập.
- **Edge cases:** `role=manager` chỉ thấy Tenant gắn với phòng thuộc nhà được cấp quyền, cộng Tenant chưa gắn phòng (dùng chung theo nhà).

### T-02 — Tenant Profile (Create/Edit)
- **Mục đích:** Tạo/sửa 1 hồ sơ Tenant, độc lập với hợp đồng.
- **Thành phần chính:** Ảnh đại diện (optional), Họ tên (bắt buộc), SĐT (bắt buộc), Giới tính, Ngày sinh, Email (optional), Số CCCD/CMND (bắt buộc), Ảnh CCCD 2 mặt (bắt buộc), Ghi chú (optional), nút Lưu/Huỷ.
- **Trạng thái:** Tạo mới / Chỉnh sửa / Lỗi validate.
- **Hành động & điều hướng:** Lưu → T-01, hoặc nếu mở shortcut từ T-04 → quay lại T-04 với Tenant vừa tạo đã chọn sẵn.
- **Dữ liệu hiển thị:** Hồ sơ Tenant (nếu sửa).
- **Edge cases:** SĐT trùng hồ sơ có sẵn → cảnh báo, gợi ý mở hồ sơ cũ.

### T-03 — Contract List
- **Mục đích:** Xem toàn bộ hợp đồng.
- **Thành phần chính:** Filter theo tên nhà (dropdown), trạng thái (Tất cả/Active/Sắp hết hạn/Ended), list card (danh sách phòng trong hợp đồng, tên Tenant, ngày hết hạn, badge trạng thái).
- **Trạng thái:** Theo filter.
- **Hành động & điều hướng:** Tap card → T-05.
- **Dữ liệu hiển thị:** Hợp đồng thuộc phạm vi các nhà đang có quyền.
- **Edge cases:** Rỗng theo filter.

### T-04 — Create Contract
- **Mục đích:** Gắn 1 Tenant vào **1 hoặc nhiều phòng cùng 1 Nhà/Dãy trọ**, tạo hợp đồng.
- **Thành phần chính:** Chọn Nhà/Dãy trọ, chọn **nhiều phòng đang Empty** (multi-select, chỉ trong nhà đã chọn), **kiểm tra & bắt buộc ghi chỉ số nhận phòng (MOVE_IN) cho từng phòng chưa có** (mở inline hoặc điều hướng nhanh sang màn ghi chỉ số rồi quay lại), chọn Tenant (từ Tenant Pool hoặc "Thêm nhanh" → T-02), Ngày bắt đầu, Kỳ hạn, Tiền cọc (cho cả hợp đồng), Tiền thuê/tháng (cho cả hợp đồng, mặc định gợi ý = tổng giá tham khảo các phòng), phương thức + đơn giá điện/nước (theo chỉ số/khoán/không thu), Chu kỳ thu tiền nhà (số tháng + kỳ neo), Ngày cố định hạn thanh toán, Phí dịch vụ (tự tính = tổng diện tích các phòng × đơn giá/m², cho sửa tay), Phí định kỳ (từng dòng, "+"), Phạt trễ hạn (optional), Môi giới (optional), nút Lưu/Huỷ.
- **Trạng thái:** Chọn phòng → Kiểm tra chỉ số nhận phòng → Chọn Tenant → Nhập điều khoản → Xác nhận.
- **Hành động & điều hướng:** Lưu → mọi phòng chuyển "Occupied" → gửi SMS/Zalo thông báo hợp đồng cho Tenant → T-05.
- **Dữ liệu hiển thị:** Thông tin Tenant đã chọn + gợi ý từ các phòng.
- **Edge cases:** Thiếu chỉ số nhận phòng cho 1 trong các phòng đã chọn → chặn nút Lưu, chỉ rõ phòng nào thiếu. Phòng vừa chọn đã có hợp đồng Active khác (race condition) → chặn lưu, báo lỗi. Chọn phòng khác nhà → chặn ngay lúc chọn.

### T-05 — Contract Detail
- **Mục đích:** Xem toàn bộ thông tin hợp đồng (điều khoản hiện hành = `currentVersionId`).
- **Thành phần chính:** Thông tin Tenant đại diện, **danh sách phòng thuộc hợp đồng**, điều khoản hiện hành (ngày, tiền cọc, tiền thuê/tháng, đơn giá/phương thức điện nước, chu kỳ thu tiền nhà, hạn thanh toán, phí dịch vụ, phí định kỳ, phạt trễ hạn, môi giới nếu có), badge trạng thái (Active/Sắp hết hạn/Ended), nút "Gia hạn" → T-06, nút "Sửa điều khoản" → T-07, nút "Xem lịch sử phiên bản" → T-08, nút "Xem lịch hoá đơn sắp tới" → T-09, nút "Kết thúc hợp đồng" → T-10.
- **Trạng thái:** Active / Sắp hết hạn (cảnh báo số ngày còn lại, ngưỡng 30 ngày) / Ended (ẩn các nút hành động, chỉ xem).
- **Hành động & điều hướng:** Như trên.
- **Dữ liệu hiển thị:** Toàn bộ dữ liệu hợp đồng + phiên bản hiện hành + danh sách phòng.
- **Edge cases:** Hợp đồng Ended nhưng còn hoá đơn chưa `Collected` → liên kết rõ tới T-10 để xem lại đối soát.

### T-06 — Renew Contract
- **Mục đích:** Gia hạn hợp đồng đang hiệu lực. **Tách riêng khỏi T-05** (khác Version 2, nơi gộp "Gia hạn"/"Sửa điều khoản" thành 1 nút mở chung 1 form).
- **Thành phần chính:** Hiển thị điều khoản hiện hành (read-only tham khảo), input ngày bắt đầu mới (mặc định nối tiếp `endDate` cũ), input kỳ hạn mới, cho phép sửa các điều khoản tiền/đơn giá nếu có thay đổi kèm gia hạn, nút Lưu/Huỷ.
- **Trạng thái:** Nhập liệu / Xác nhận.
- **Hành động & điều hướng:** Lưu → tạo `tb_contract_version` mới (`changeReason=Renewal`) → T-05. **Không yêu cầu ghi lại chỉ số** nếu giữ nguyên Tenant/phòng.
- **Dữ liệu hiển thị:** Điều khoản phiên bản hiện hành.
- **Edge cases:** Không có.

### T-07 — Amend Contract
- **Mục đích:** Sửa điều khoản giữa kỳ, **kể cả thêm/bớt phòng trong hợp đồng**. **Tách riêng khỏi T-05.**
- **Thành phần chính:** Toàn bộ field điều khoản như T-04 (cho sửa), thêm mục **"Danh sách phòng"** (thêm phòng Empty khác cùng nhà / bỏ bớt phòng hiện có), nút Lưu/Huỷ.
- **Trạng thái:** Nhập liệu / Xác nhận.
- **Hành động & điều hướng:** Lưu → tạo `tb_contract_version` mới (`changeReason=Amendment`); nếu có phòng bị loại ra → **bắt buộc điều hướng ghi chỉ số trả phòng (MOVE_OUT)** riêng cho phòng đó trước khi hoàn tất → T-05. Nếu có phòng thêm vào → kiểm tra/bắt buộc chỉ số nhận phòng (MOVE_IN) cho phòng mới như T-04.
- **Dữ liệu hiển thị:** Điều khoản phiên bản hiện hành + danh sách phòng hiện tại.
- **Edge cases:** Bỏ phòng đang thiếu chỉ số trả phòng → chặn lưu tới khi bổ sung.

### T-08 — Version History
- **Mục đích:** Xem toàn bộ lịch sử thay đổi điều khoản hợp đồng.
- **Thành phần chính:** Timeline/list các `tb_contract_version` theo `versionNo` (thời gian tạo, `changeReason`: New/Renewal/Amendment, các trường điều khoản tại thời điểm đó, danh sách phòng tại thời điểm đó).
- **Trạng thái:** Có ít nhất 1 phiên bản.
- **Hành động & điều hướng:** Tap 1 phiên bản → xem chi tiết đầy đủ (read-only).
- **Dữ liệu hiển thị:** Toàn bộ `tb_contract_version` của hợp đồng đang xem.
- **Edge cases:** Không có.

### T-09 — Invoice Schedule Preview
- **Mục đích:** Xem trước lịch các kỳ hoá đơn sắp tới của 1 hợp đồng, dựa trên chu kỳ thu tiền nhà và chu kỳ điện/nước hàng tháng.
- **Thành phần chính:** List các kỳ sắp tới (VD 3-6 kỳ), mỗi dòng: khoảng thời gian kỳ, có thu tiền nhà kỳ này hay không (theo `rentCycleMonths`/`rentCycleAnchorYm`), chip "Scheduled" (chưa phải hoá đơn thật).
- **Trạng thái:** Có dữ liệu (hợp đồng Active).
- **Hành động & điều hướng:** Chỉ xem — không tạo hoá đơn thật từ màn này (tạo hoá đơn thực hiện ở B-02/B-03).
- **Dữ liệu hiển thị:** Suy ra từ `contract_version` hiện hành, không truy vấn `tb_invoice` thật.
- **Edge cases:** Hợp đồng Ended → không hiển thị màn này (ẩn nút ở T-05).

### T-10 — End Contract (Settlement)
- **Mục đích:** Xử lý trả phòng: tổng kết công nợ, đối soát tiền cọc.
- **Thành phần chính:** **Kiểm tra & bắt buộc ghi chỉ số trả phòng (MOVE_OUT) cho từng phòng chưa có** (trừ phòng `NOT_BILLED`), danh sách hoá đơn chưa `Collected` (tính `unpaidInvoicesTotal`), số tiền cọc đã nhận (`depositAmount`, theo cả hợp đồng), ô nhập khoản trừ hư hỏng (`damageDeduction`, kèm ghi chú lý do), tổng kết cuối cùng (`refundAmount` = cọc − công nợ − khoản trừ), nút "Xác nhận trả phòng".
- **Trạng thái:** Thiếu chỉ số trả phòng (chặn) / Đang tổng kết / Đã xác nhận.
- **Hành động & điều hướng:** Xác nhận → ghi settlement vào `tb_contract` (kèm `settlementConfirmedAt`) → `status=Ended` → tạo hoá đơn cuối với số tiền đã tính (`refundAmount` âm hoặc dương) → mọi phòng trong hợp đồng chuyển "Empty" → quay lại H-04 (phòng đầu tiên) hoặc T-03.
- **Dữ liệu hiển thị:** Công nợ & tiền cọc của hợp đồng đang kết thúc.
- **Edge cases:** Thiếu chỉ số trả phòng cho bất kỳ phòng nào (không `NOT_BILLED`) → chặn nút "Xác nhận trả phòng", điều hướng ghi chỉ số ngay tại chỗ.

---

## 2.4 Bills (B-01 → B-05) — Core

### B-01 — Invoice List
- **Mục đích:** Xem toàn bộ hoá đơn — đây là màn hình trung tâm của chức năng cốt lõi Phase 1.
- **Thành phần chính:** Filter nhà (dropdown), hợp đồng (dropdown, phụ thuộc nhà đã chọn), trạng thái (Tất cả/Draft/Sent/Collected/Overdue), bộ lọc theo kỳ, tuỳ chọn sắp xếp, **danh sách nhóm theo Nhà → theo Hợp đồng**, mỗi nhóm hiện dải chip các kỳ (kỳ đã phát hành = số tiền + trạng thái; kỳ tương lai = chip "Scheduled" xám, tap vào mở T-09 của hợp đồng đó), nút nổi "+" → mở lựa chọn B-02 (hàng loạt) hoặc B-03 (đơn lẻ).
- **Trạng thái:** Theo filter đang chọn.
- **Hành động & điều hướng:** Tap card hoá đơn đã phát hành → B-05. Tap chip "Scheduled" → T-09.
- **Dữ liệu hiển thị:** Hoá đơn thuộc phạm vi các nhà đang có quyền. Xem nhanh tổng/đã thu/chưa thu/quá hạn qua filter theo trạng thái (thay cho màn Revenue Report riêng — ngoài phạm vi Phase 1).
- **Edge cases:** Rỗng theo filter → empty state phù hợp ngữ cảnh.

### B-02 — Create Invoice — Batch
- **Mục đích:** Tạo hoá đơn **hàng loạt** cho mọi hợp đồng Active của 1 Nhà/Dãy trọ trong 1 kỳ.
- **Thành phần chính:** Chọn Nhà/Dãy trọ, chọn kỳ (tháng/năm), danh sách kết quả sau khi hệ thống đọc lại chỉ số: nhóm "Sẵn sàng tạo" (đủ chỉ số) và nhóm "Thiếu dữ liệu" (liệt kê rõ hợp đồng/phòng còn thiếu chỉ số kỳ này, không cho tạo), bảng preview tổng hợp cho nhóm "Sẵn sàng tạo" (từng hợp đồng: điện/nước theo phòng, tiền nhà nếu đúng chu kỳ, phí dịch vụ, phí định kỳ, prorate nếu có MOVE_IN/MOVE_OUT trong kỳ, **Tổng cộng**), nút "Tạo & xem trước gửi" → B-04, nút "Lưu nháp tất cả" (Draft).
- **Trạng thái:** Đang tính → Preview → Đã tạo (Draft) hoặc chuyển sang gửi.
- **Hành động & điều hướng:** "Tạo & xem trước gửi" → B-04 (Send Invoice Sheet) cho toàn bộ lô vừa tạo.
- **Dữ liệu hiển thị:** Dữ liệu tính từ chỉ số đã ghi sẵn (H-06) + điều khoản từ `contract_version` hiện hành của từng hợp đồng.
- **Edge cases:** Hợp đồng thiếu chỉ số → không tạo, không ước lượng thay. Nhà chưa có tài khoản ngân hàng nhận tiền (P-03) → cảnh báo trước khi tạo, không sinh được mã QR.

### B-03 — Create Invoice — Single
- **Mục đích:** Tạo hoá đơn cho **1 hợp đồng cụ thể** (ngoài chu kỳ hàng loạt, hoặc tạo bổ sung).
- **Thành phần chính:** Chọn hợp đồng Active cần tạo hoá đơn, chọn kỳ, hiện chỉ số đã ghi để đối chiếu (không nhập tay tại đây — khác Version 2), bảng preview (giống B-02 nhưng cho 1 hợp đồng), cho phép sửa/thêm dòng phí phát sinh (`otherFees`), nút "Tạo & xem trước gửi", nút "Lưu nháp".
- **Trạng thái:** Chọn hợp đồng/kỳ → Preview (Draft) → Đã tạo.
- **Hành động & điều hướng:** "Tạo & xem trước gửi" → B-04.
- **Dữ liệu hiển thị:** Dữ liệu tính từ chỉ số đã ghi + điều khoản từ `contract_version` hiện hành.
- **Edge cases:** Hợp đồng thiếu chỉ số kỳ này → chặn, điều hướng sang H-06 để bổ sung trước.

### B-04 — Send Invoice Sheet
- **Mục đích:** Xem mã QR và chọn kênh gửi — dùng chung cho cả B-02 (hàng loạt) và B-03 (đơn lẻ).
- **Thành phần chính:** Preview mã QR VietQR/NAPAS-247 (mẫu đại diện nếu hàng loạt), chọn kênh gửi (SMS/Zalo/Cả hai), số lượng hoá đơn sẽ gửi (nếu hàng loạt), nút "Gửi", nút "Chỉ lưu nháp, gửi sau".
- **Trạng thái:** Xem trước → Đang gửi → Hoàn tất.
- **Hành động & điều hướng:** "Gửi" → hoá đơn chuyển trạng thái "Sent", hệ thống gửi qua kênh đã chọn → B-01. "Chỉ lưu nháp" → hoá đơn giữ "Draft" → B-01.
- **Dữ liệu hiển thị:** Số hoá đơn sẽ gửi + tổng tiền.
- **Edge cases:** Thiếu tài khoản ngân hàng nhận tiền của nhà → không hiện được QR, cảnh báo rõ trước khi cho gửi.

### B-05 — Invoice Detail
- **Mục đích:** Xem chi tiết 1 hoá đơn, đánh dấu đã thu tiền.
- **Thành phần chính:** Bảng chi tiết hoá đơn (danh sách phòng × điện/nước, tiền nhà, phí dịch vụ, phí định kỳ, phí khác, tổng cộng), mã QR, badge trạng thái (Draft/Sent/Overdue/Collected), nút "Đánh dấu đã thu tiền" (khi Sent/Overdue), nút "Huỷ đánh dấu" (khi Collected), nút "Gửi lại".
- **Trạng thái:** Draft / Sent / Overdue / Collected.
- **Hành động & điều hướng:** "Đánh dấu đã thu tiền" → "Collected". "Huỷ đánh dấu" → quay lại "Sent".
- **Dữ liệu hiển thị:** Chi tiết hoá đơn + lịch sử trạng thái (thời điểm gửi, thời điểm đánh dấu thu tiền).
- **Edge cases:** Hoá đơn quá hạn → cảnh báo màu đỏ + số ngày trễ.

---

## 2.5 Profile (P-01 → P-07)

### P-01 — Profile (màn gốc tab)
- **Mục đích:** Danh mục điều hướng của tab 4 — **mới** so với Version 2 (nơi tab User Setting đi thẳng vào Owner/Manager Profile).
- **Thành phần chính:** Avatar + tên tài khoản đang đăng nhập, danh sách mục: "Hồ sơ cá nhân" → P-02, "Tài khoản ngân hàng nhận tiền" → P-03, "Đổi mật khẩu" → P-04, "Người quản lý nhà" → P-05, nút "Đăng xuất" → P-07.
- **Trạng thái:** Mặc định.
- **Hành động & điều hướng:** Như trên.
- **Dữ liệu hiển thị:** Thông tin tài khoản đang đăng nhập.
- **Edge cases:** Không có.

### P-02 — Personal Profile (Detail/Edit)
- **Mục đích:** Xem/sửa hồ sơ cá nhân — dùng chung cho mọi tài khoản, không phân biệt owner/manager.
- **Thành phần chính:** Avatar (optional), Họ tên, SĐT (đổi cần OTP lại), Giới tính, Ngày sinh, Email (optional), Số CCCD/CMND, nút Lưu.
- **Trạng thái:** Xem / Đang sửa.
- **Hành động & điều hướng:** Lưu → toast xác nhận, ở lại màn hình.
- **Dữ liệu hiển thị:** Thông tin tài khoản hiện tại.
- **Edge cases:** Đổi SĐT cần xác thực OTP lại.

### P-03 — Payout Bank Account
- **Mục đích:** Xem/sửa tài khoản ngân hàng nhận tiền — **theo TỪNG Nhà/Dãy trọ**, không phải theo cá nhân (khác Version 2, nơi số tài khoản gắn với Owner Profile).
- **Thành phần chính:** Chọn nhà (nếu quản lý nhiều nhà với role=owner), tên ngân hàng, số tài khoản, mã BIN, tên chủ tài khoản, nút Lưu.
- **Trạng thái:** Xem / Đang sửa. Chỉ `role=owner` của nhà đó sửa được; `role=manager` chỉ xem.
- **Hành động & điều hướng:** Lưu → toast xác nhận, dùng ngay cho B-02/B-03/B-04 (sinh QR).
- **Dữ liệu hiển thị:** Thông tin tài khoản ngân hàng của nhà đang chọn.
- **Edge cases:** Chưa nhập → cảnh báo mỗi lần vào B-02/B-03/B-04 của nhà đó.

### P-04 — Change Password
- **Mục đích:** Đổi mật khẩu — **tách riêng khỏi luồng quên mật khẩu** (mới).
- **Thành phần chính:** Input mật khẩu hiện tại, input mật khẩu mới (2 field xác nhận), nút Lưu.
- **Trạng thái:** Nhập liệu / Lỗi (sai mật khẩu hiện tại) / Hoàn tất.
- **Hành động & điều hướng:** Lưu → toast xác nhận → P-01.
- **Dữ liệu hiển thị:** Không.
- **Edge cases:** Mật khẩu mới không đủ mạnh → cảnh báo tại chỗ.

### P-05 — House Access List ("Người quản lý nhà")
- **Mục đích:** Xem toàn bộ quyền truy cập đã cấp trên các Nhà/Dãy trọ đang có `role=owner`. **Đổi tên từ "Danh sách Manager của tôi"** (Version 2) vì vai trò không còn gắn cứng vào 1 loại tài khoản.
- **Thành phần chính:** Chọn nhà (nếu có nhiều nhà role=owner), list mỗi người đang có quyền trên nhà đó (avatar nếu có tài khoản, họ tên hoặc SĐT che một phần nếu chưa xác nhận, role, trạng thái tài khoản đã kích hoạt hay chưa), nút nổi "+" → P-06.
- **Trạng thái:** Có dữ liệu / Rỗng (chỉ có chính mình).
- **Hành động & điều hướng:** Tap "+" → P-06 (mời mới). Tap 1 dòng → P-06 (xem/thu hồi).
- **Dữ liệu hiển thị:** Mọi dòng `tb_user_house_access` của nhà đang chọn.
- **Edge cases:** Chỉ hiện với nhà đang có `role=owner`; nhà đang chỉ có `role=manager` thì không có mục này.

### P-06 — House Access Detail (Invite/Edit theo House)
- **Mục đích:** Mời quản lý mới bằng số điện thoại, hoặc xem/thu hồi 1 quyền đã cấp.
- **Thành phần chính:** Input số điện thoại (bắt buộc khi mời mới), hiển thị tên che một phần nếu số đã có tài khoản (BR-ROLE-06), chọn 1 hoặc nhiều Nhà/Dãy trọ đang có `role=owner` để cấp quyền cho số này, nút Lưu, nút "Thu hồi quyền" (chỉ hiện khi xem 1 dòng do chính mình đã cấp).
- **Trạng thái:** Mời mới / Xem / Lỗi validate.
- **Hành động & điều hướng:** Lưu → ghi 1 dòng `tb_user_house_access` (`role=manager`) cho từng nhà đã chọn, **không tạo tài khoản** → P-05.
- **Dữ liệu hiển thị:** Thông tin dòng quyền (nếu xem).
- **Edge cases:** Số điện thoại là chính mình → chặn, báo lỗi. Thu hồi quyền do người khác cấp (không phải mình) → không hiện nút thu hồi.

### P-07 — Xác nhận Đăng xuất
- **Mục đích:** Xác nhận trước khi đăng xuất.
- **Thành phần chính:** Dialog overlay: "Bạn có chắc muốn đăng xuất?", 2 nút "Huỷ"/"Đăng xuất".
- **Trạng thái:** Dialog hiện/ẩn.
- **Hành động & điều hướng:** "Huỷ" → đóng dialog. "Đăng xuất" → xoá session → S-01.
- **Dữ liệu hiển thị:** Không.
- **Edge cases:** Không có.

---

## 3. Liên kết với Figma / FigJam

- Wireframe MVP: **BizTown Rent-Manager — MVP Wireframes** → https://www.figma.com/design/AElzfTBuL8YyA8OJ85f7aX/BizTown-Rent-Manager-%E2%80%94-MVP-Wireframes?node-id=133-57 — page **MVP Wireframes (EN) - Version3** (cần build lại theo 32 màn ở mục 1; page cũ "MVP Wireframes (EN) - OLD" 35 màn đã gắn nhãn SUPERSEDED). Dùng chung style/token với các bản trước (nền `#F5F6F9`, header navy `#23305E`, accent cam `#EF9F27`, bo góc 12–16px) và bottom nav **4 tab** dùng chung mọi tài khoản theo [DESIGN-SYSTEMS.md](DESIGN-SYSTEMS.md).
- Diagram tóm tắt entity + luồng theo cấu trúc mới (nguồn cho đợt viết lại tài liệu 2026-09-08): FigJam board `PAuYWdSon7WcPKdRQStoPR`, khu vực "Version 3 — CURRENT".

**Trạng thái:** Ver3 (tài liệu) đã hoàn tất 2026-09-08. Figma MVP Wireframes cần build lại 32 màn theo cấu trúc 4 tab — chưa thực hiện tại thời điểm viết tài liệu này.

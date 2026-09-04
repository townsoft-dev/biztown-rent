# Screen Spec — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 2 — **viết lại toàn bộ theo scope Phase 1 mới** (2026-09-03)
> **Thay đổi lớn:** Bỏ toàn bộ 11 màn hình Tenant (T-01 → T-11) và các màn Search/Public listing (T-08→T-11 cũ, phần liên quan ở L-06/L-19 cũ). Tổ chức lại theo **5 menu chính** (bottom nav): House/Room Management, Tenant Management, Contract Management, Bill Management, User Setting. Thêm màn quản lý Manager. Xem [DECISIONS.md](DECISIONS.md) 2026-09-03 và [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.

---

## 1. Screen Inventory (Phase 1)

### 1.1 Chung (Shared) — 4 màn

| # | Màn hình | Ghi chú |
|---|---|---|
| S-00 | Splash | |
| S-01 | Đăng nhập (SĐT + Mật khẩu / OTP) | Dùng chung cho Landlord & Manager — không còn bước chọn vai trò (chỉ Landlord tự đăng ký, xem S-02) |
| S-02 | Đăng ký Landlord (SĐT & OTP) | Chỉ dành cho Landlord — Manager không tự đăng ký (xem M-02) |
| S-03 | Trung tâm thông báo | Cho cả Landlord & Manager |

### 1.2 Bottom Navigation — 5 menu chính

| Menu | Icon gợi ý | Màn hình con |
|---|---|---|
| 1. House/Room Management | nhà/lưới phòng | H-01 → H-04 |
| 2. Tenant Management | người | N-01 → N-02 |
| 3. Contract Management | hợp đồng | C-01 → C-05 |
| 4. Bill Management (core) | hoá đơn | B-01 → B-03 |
| 5. User Setting | bánh răng/hồ sơ | U-01 → U-04 |

### 1.3 House/Room Management (H) — 4 màn

| # | Màn hình | Ghi chú |
|---|---|---|
| H-01 | House List | Danh sách Nhà/Dãy trọ (Landlord: tất cả; Manager: chỉ nơi được cấp quyền) |
| H-02 | House Registration (Create/Edit) | |
| H-03 | Room List (theo 1 House) | Filter theo trạng thái |
| H-04 | Room Detail (Create/Edit/View) | Gộp cả 3 chế độ trong 1 màn theo trạng thái |

### 1.4 Tenant Management (N) — 2 màn

| # | Màn hình | Ghi chú |
|---|---|---|
| N-01 | Tenant Pool List | |
| N-02 | Tenant Profile (Create/Edit) | Có thể mở dưới dạng shortcut từ C-02 (Create Contract) |

### 1.5 Contract Management (C) — 5 màn

| # | Màn hình | Ghi chú |
|---|---|---|
| C-01 | Contract List | Filter: Tất cả / Active / Sắp hết hạn / Ended |
| C-02 | Create Contract | |
| C-03 | Contract Detail | Điểm vào Gia hạn/Sửa điều khoản/Kết thúc/Version History |
| C-04 | Version History | Danh sách `contract_version` theo thời gian |
| C-05 | End Contract (Settlement) | Đối soát cọc & công nợ |

### 1.6 Bill Management (B) — 3 màn (core)

| # | Màn hình | Ghi chú |
|---|---|---|
| B-01 | Invoice List | Filter theo trạng thái (Draft/Sent/Collected/Overdue) + theo tháng |
| B-02 | Create Invoice | Nhập chỉ số điện/nước → preview → gửi |
| B-03 | Invoice Detail | Xem chi tiết, đánh dấu Collected |

### 1.7 User Setting (U) — 4 màn

| # | Màn hình | Ghi chú |
|---|---|---|
| U-01 | Owner/Manager Profile (Detail/Edit) | Tùy thuộc tài khoản đăng nhập là ai  |
| U-02 | Manager Management List | Chỉ Landlord thấy |
| U-03 | Manager Detail (Create/Edit + cấp quyền theo House) | Chỉ Landlord thấy |
| U-04 | Xác nhận Đăng xuất | Dialog, cả Landlord & Manager |

**Tổng: 4 (Shared) + 4 (House/Room) + 2 (Tenant) + 5 (Contract) + 3 (Bill) + 4 (User Setting) = 22 màn hình.**

> Toàn bộ 11 màn T-xx và các màn Search/Public-listing của Version 1 (36 màn) đã được **loại bỏ** khỏi Phase 1 — có thể tham khảo lại lịch sử git nếu cần phục dựng cho Phase 2.

---

## 2. Đặc tả chi tiết

> Template: **Mục đích → Thành phần chính → Trạng thái (states) → Hành động & điều hướng → Dữ liệu hiển thị → Edge cases**

## 2.1 Shared (S-00 → S-03)

### S-00 — Splash
- **Mục đích:** Màn hình mở app, kiểm tra session hiện có.
- **Thành phần chính:** Logo BizTown Rent-Manager (logo svg trong folder logo) (nền navy), tagline.
- **Trạng thái:** Đang kiểm tra session. (hiển thị greeting )
- **Hành động & điều hướng:** Không có session/hết hạn → S-01. Có session hợp lệ → Trang chủ (menu 1, House List H-01) theo vai trò đã đăng nhập (Landlord hoặc Manager).
- **Edge cases:** Mạng chậm → timeout hợp lý (10s), không treo màn hình.

### S-01 — Đăng nhập
- **Mục đích:** Xác thực Landlord hoặc Manager bằng SĐT + Mật khẩu (hoặc OTP), dùng chung 1 màn cho cả 2 vai trò — hệ thống tự nhận diện loại tài khoản theo SĐT.
- **Thành phần chính:** Input SĐT, input Mật khẩu, nút "Đăng nhập", link "Quên mật khẩu", link "Chưa có tài khoản? Đăng ký" (chỉ dẫn tới S-02 — **chỉ áp dụng cho Landlord**, Manager không có lối tự đăng ký).
- **Trạng thái:** Nhập liệu / Lỗi (sai SĐT/mật khẩu) / Tài khoản Manager bị khoá (thông báo riêng, chặn đăng nhập — xem U-03).
- **Hành động & điều hướng:** Đăng nhập thành công → H-01 (House List, phạm vi theo vai trò). "Quên mật khẩu" → luồng xác thực OTP rồi tạo mật khẩu mới.
- **Dữ liệu hiển thị:** Không.
- **Edge cases:** Sai mật khẩu nhiều lần → rate-limit (khoá tạm 10 phút sau 5 lần sai). Tài khoản Manager bị Landlord khoá (`status=disabled`) → chặn đăng nhập, hiện "Liên hệ chủ trọ để được hỗ trợ".

### S-02 — Đăng ký Landlord (SĐT & OTP)
- **Mục đích:** Tạo tài khoản Landlord mới.
- **Thành phần chính:** Input SĐT + nút gửi OTP; 6 ô nhập OTP + đếm ngược 2 phút + gửi lại; bước tạo mật khẩu (2 field) sau khi OTP đúng.
- **Trạng thái:** Nhập SĐT → Đang gửi OTP → Nhập OTP → (sai/hết hạn) → Tạo mật khẩu → Hoàn tất.
- **Hành động & điều hướng:** Hoàn tất → H-01 (House List trống, CTA "Thêm Nhà/Dãy trọ đầu tiên").
- **Dữ liệu hiển thị:** Không.
- **Edge cases:** Nhập sai OTP nhiều lần → rate-limit. SĐT đã tồn tại → gợi ý chuyển sang S-01 (đăng nhập).

### S-03 — Trung tâm thông báo
- **Mục đích:** Tập trung thông báo cho Landlord/Manager (FR-NOTI-03).
- **Thành phần chính:** List thông báo (icon theo loại, tiêu đề, tóm tắt, thời gian tương đối, chấm chưa đọc), tab "Tất cả"/"Chưa đọc".
- **Trạng thái:** Có thông báo / Rỗng.
- **Hành động & điều hướng:** Tap → đánh dấu đã đọc + điều hướng: hoá đơn mới/nhắc thanh toán → B-03; hợp đồng sắp hết hạn → C-03; **đến hạn tạo hoá đơn kỳ mới** (BR-NOTI-05) → màn Tạo hoá đơn (Bill Management) cho đúng hợp đồng, sẵn điền kỳ/thông tin liên quan để nhập chỉ số điện/nước.
- **Dữ liệu hiển thị:** Theo BR-NOTI-01→05.
- **Edge cases:** Thông báo trỏ tới thực thể đã xoá → hiện "Không tìm thấy dữ liệu" thay vì lỗi trắng màn hình.

---

## 2.2 House/Room Management (H-01 → H-04)

### H-01 — House List
- **Mục đích:** Điểm vào chính (Trang chủ) — liệt kê Nhà/Dãy trọ.
- **Thành phần chính:** Header (lời chào + chuông → S-03), list card mỗi Nhà/Dãy trọ (ảnh, tên, địa chỉ rút gọn, tỉ lệ "x/y phòng trống"), nút nổi "+" thêm mới, Bottom Navigation (5 menu).
- **Trạng thái:** Có dữ liệu / Rỗng (CTA "Thêm Nhà/Dãy trọ đầu tiên" → H-02) — Manager chưa được cấp quyền nơi nào → thông báo "Chưa được cấp quyền truy cập, liên hệ chủ trọ".
- **Hành động & điều hướng:** Tap card → H-03. Tap "+" → H-02.
- **Dữ liệu hiển thị:** Landlord: toàn bộ `house` của mình. Manager: chỉ `house` có trong `manager_house_access` của Manager đó.
- **Edge cases:** Nhiều Nhà/Dãy trọ (Persona B) → cần search/sort nếu danh sách dài.

### H-02 — House Registration (Create/Edit)
- **Mục đích:** Tạo/sửa 1 Nhà/Dãy trọ.
- **Thành phần chính:** Ảnh (nhiều ảnh), Tên (bắt buộc), Địa chỉ (bắt buộc), Mô tả (optional), nút Lưu/Huỷ.
- **Trạng thái:** Tạo mới / Chỉnh sửa / Lỗi validate.
- **Hành động & điều hướng:** Lưu → H-01, toast xác nhận.
- **Dữ liệu hiển thị:** Thông tin nhà (nếu sửa).
- **Edge cases:** Trùng tên trong cùng Landlord → cảnh báo, không chặn. Xoá nhà đang có phòng còn hợp đồng Active → chặn.

### H-03 — Room List (theo 1 House)
- **Mục đích:** Xem toàn bộ phòng trong 1 Nhà/Dãy trọ.
- **Thành phần chính:** Header tên Nhà/Dãy trọ, chip filter (Tất cả/Empty/Occupied/UnderRepair), list card phòng (ảnh, số phòng, giá tham khảo, badge trạng thái), nút nổi "+".
- **Trạng thái:** Theo filter / Rỗng.
- **Hành động & điều hướng:** Tap card → H-04 (view). Tap "+" → H-04 (create, gắn sẵn house).
- **Dữ liệu hiển thị:** Phòng thuộc Nhà/Dãy trọ đã chọn.
- **Edge cases:** Chưa có phòng nào → empty state + CTA.

### H-04 — Room Detail (Create/Edit/View)
- **Mục đích:** Tạo/sửa/xem chi tiết 1 Phòng, là điểm vào Contract Management khi phòng đang Empty.
- **Thành phần chính:** Ảnh (nhiều ảnh, tối thiểu 1), Số phòng (bắt buộc), Diện tích (optional), Giá tham khảo/tháng (bắt buộc — dùng làm gợi ý khi tạo hợp đồng, không phải giá cố định), Tiện ích (danh sách), Phí định kỳ mặc định (tên + số tiền, optional — gợi ý khi tạo hợp đồng), Trạng thái (Empty/Occupied/UnderRepair — Occupied do hệ thống tự set khi có hợp đồng Active, UnderRepair set tay), nút Lưu/Huỷ (chế độ edit) hoặc nút "Tạo hợp đồng" (chế độ view, chỉ hiện khi Empty) → C-02, hoặc thẻ tóm tắt hợp đồng hiện tại (chế độ view khi Occupied) → C-03.
- **Trạng thái:** Tạo mới / Chỉnh sửa / Xem (View) / Lỗi validate.
- **Hành động & điều hướng:** Lưu → H-03. Tap "Tạo hợp đồng" → C-02. Tap hợp đồng hiện tại → C-03.
- **Dữ liệu hiển thị:** Thông tin phòng.
- **Edge cases:** Xoá phòng đang có hợp đồng Active → chặn. Trùng số phòng trong cùng Nhà/Dãy trọ → cảnh báo.

---

## 2.3 Tenant Management (N-01 → N-02)

### N-01 — Tenant Pool List
- **Mục đích:** Quản lý "kho" hồ sơ Tenant dùng chung cho Landlord.
- **Thành phần chính:** Ô tìm kiếm (tên/SĐT), chip filter (Tất cả/Chưa gắn phòng/Đang thuê), list mỗi Tenant (avatar, họ tên, SĐT, trạng thái gắn phòng), nút nổi "+".
- **Trạng thái:** Có dữ liệu / Rỗng.
- **Hành động & điều hướng:** Tap "+" → N-02 (tạo mới). Tap 1 Tenant → N-02 (xem/sửa).
- **Dữ liệu hiển thị:** Toàn bộ Tenant do Landlord này (và Manager được cấp quyền tương ứng) tạo.
- **Edge cases:** Manager chỉ thấy Tenant gắn với phòng thuộc phạm vi được cấp quyền, cộng thêm Tenant chưa gắn phòng nào (dùng chung toàn Landlord).

### N-02 — Tenant Profile (Create/Edit)
- **Mục đích:** Tạo/sửa 1 hồ sơ Tenant, độc lập với hợp đồng.
- **Thành phần chính:** Ảnh đại diện (optional), Họ tên (bắt buộc), SĐT (bắt buộc), Giới tính (M/F), Ngày sinh, Email (optional), Số CCCD/CMND (bắt buộc), Ảnh CCCD mặt trước/sau (bắt buộc), Ghi chú (optional), nút Lưu/Huỷ.
- **Trạng thái:** Tạo mới / Chỉnh sửa / Lỗi validate.
- **Hành động & điều hướng:** Lưu → N-01, hoặc nếu mở dưới dạng shortcut từ C-02 → quay lại C-02 với Tenant vừa tạo đã chọn sẵn.
- **Dữ liệu hiển thị:** Hồ sơ Tenant (nếu sửa).
- **Edge cases:** SĐT trùng hồ sơ có sẵn → cảnh báo, gợi ý mở hồ sơ cũ. Ảnh CCCD mã hoá khi lưu (NFR-03).

---

## 2.4 Contract Management (C-01 → C-05)

### C-01 — Contract List
- **Mục đích:** Xem toàn bộ hợp đồng, lọc theo : tên nhà (dropdown), sắp hết hạn.
- **Thành phần chính:**  filter 2 loại tên nhà (dropdown), hạn (Tất cả/Active/Sắp hết hạn/Ended), list card (tên phòng, tên Tenant, ngày hết hạn, badge trạng thái).
- **Trạng thái:** Theo filter.
- **Hành động & điều hướng:** Tap card → C-03.
- **Dữ liệu hiển thị:** Hợp đồng thuộc phạm vi Landlord/Manager hiện tại.
- **Edge cases:** Rỗng theo filter.

### C-02 — Create Contract
- **Mục đích:** Gắn 1 Tenant vào 1 Phòng đang Empty, tạo hợp đồng (tạo `contract` + `contract_version` #1).
- **Thành phần chính:** Chọn Tenant (từ Tenant Pool hoặc "Thêm nhanh" → N-02), Ngày bắt đầu (bắt buộc), Kỳ hạn (bắt buộc), Tiền cọc (bắt buộc), Tiền thuê/tháng (mặc định lấy giá tham khảo ở H-04, cho sửa), Đơn giá điện/nước, Phí định kỳ dạng từng dòng, thêm nội dung thì ấn "+" (tên+số tiền, gợi ý từ H-04), Điều khoản phạt trễ hạn (optional, free text), Thông tin môi giới (optional: tên, liên hệ, phí), nút Lưu/Huỷ.
- **Trạng thái:** Chọn Tenant → Nhập điều khoản → Xác nhận.
- **Hành động & điều hướng:** Lưu → phòng chuyển "Occupied" → hệ thống gửi SMS/Zalo thông báo cho Tenant (không phải lời mời dùng app, chỉ là thông báo hợp đồng) → C-03.
- **Dữ liệu hiển thị:** Thông tin Tenant đã chọn + gợi ý từ phòng.
- **Edge cases:** Phòng vừa chọn đã có hợp đồng Active khác (race condition) → chặn lưu, báo lỗi.

### C-03 — Contract Detail
- **Mục đích:** Xem toàn bộ thông tin hợp đồng (điều khoản hiện hành = `currentVersionId`), thực hiện gia hạn/sửa điều khoản/kết thúc.
- **Thành phần chính:** Thông tin Tenant (tên, SĐT, ảnh CCCD), thông tin phòng, điều khoản hiện hành (ngày bắt đầu/kết thúc, tiền cọc, tiền thuê/tháng, đơn giá điện/nước, phí định kỳ, phạt trễ hạn, môi giới nếu có), badge trạng thái (Active/Sắp hết hạn/Ended), nút "Gia hạn", nút "Sửa điều khoản", nút "Xem lịch sử phiên bản" → C-04, nút "Kết thúc hợp đồng" → C-05.
- **Trạng thái:** Active / Sắp hết hạn (cảnh báo số ngày còn lại) / Ended (ẩn các nút hành động, chỉ xem).
- **Hành động & điều hướng:** "Gia hạn"/"Sửa điều khoản" → form nhập điều khoản mới → lưu tạo `contract_version` mới (changeReason tương ứng) → quay lại C-03 với điều khoản mới là hiện hành. "Kết thúc hợp đồng" → C-05.
- **Dữ liệu hiển thị:** Toàn bộ dữ liệu hợp đồng + phiên bản hiện hành.
- **Edge cases:** Hợp đồng Ended nhưng còn hoá đơn chưa `Collected` → liên kết rõ tới C-05 để xem lại đối soát.

### C-04 — Version History
- **Mục đích:** Xem toàn bộ lịch sử thay đổi điều khoản hợp đồng.
- **Thành phần chính:** Timeline/list các `contract_version` theo `versionNo` (thời gian tạo, `changeReason`: New/Renewal/Amendment, các trường điều khoản tại thời điểm đó).
- **Trạng thái:** Có ít nhất 1 phiên bản (luôn có, vì tạo hợp đồng đã sinh version #1).
- **Hành động & điều hướng:** Tap 1 phiên bản → xem chi tiết đầy đủ điều khoản của phiên bản đó (read-only).
- **Dữ liệu hiển thị:** Toàn bộ `contract_version` của hợp đồng đang xem.
- **Edge cases:** Không có — đây là màn chỉ xem lịch sử.

### C-05 — End Contract (Settlement)
- **Mục đích:** Xử lý trả phòng: tổng kết công nợ, đối soát tiền cọc.
- **Thành phần chính:** Danh sách hoá đơn chưa `Collected` (nếu có, tính `unpaidInvoicesTotal`), số tiền cọc đã nhận (`depositAmount`, từ phiên bản hợp đồng hiện hành), ô nhập khoản trừ hư hỏng (`damageDeduction`, kèm ghi chú lý do), tổng kết cuối cùng (`refundAmount` = cọc − công nợ − khoản trừ), nút "Xác nhận trả phòng".
- **Trạng thái:** Đang tổng kết / Đã xác nhận.
- **Hành động & điều hướng:** Xác nhận → tạo `contract_settlement` (kèm `confirmedAt`) → `contract.status = Ended` → tạo last bill với số tiền đã tính (`refundAmount` âm hoặc dương)→  phòng chuyển "Empty" → quay lại H-04.
- **Dữ liệu hiển thị:** Công nợ & tiền cọc của hợp đồng đang kết thúc.
- **Edge cases:** 

---

## 2.5 Bill Management (B-01 → B-03) — Core

### B-01 — Invoice List
- **Mục đích:** Xem toàn bộ hoá đơn (bao gồm hóa đơn đã tạo vào hóa đơn draft nhưng dự kiến sẽ có theo thời hạn các hợp đồng đang active), lọc/sắp xếp theo nhà, phòng, trạng thái và theo tháng — đây là màn hình trung tâm của chức năng cốt lõi Phase 1.
- **Thành phần chính:** filter nhà (dropdown : tất cả, list nhà), phòng (select dropdown), trạng thái (dropdown Tất cả/Draft/Sent/Collected/Overdue), bộ lọc theo tháng/năm, tuỳ chọn sắp xếp (mới nhất/trạng thái), list card hoá đơn (tên phòng, kỳ, số tiền, badge trạng thái theo màu — xem [DESIGN](DESIGN.md)), nút nổi "+" → B-02.
- **Trạng thái:** Theo filter đang chọn.
- **Hành động & điều hướng:** Tap card → B-03. Tap "+" → B-02.
- **Dữ liệu hiển thị:** Hoá đơn thuộc phạm vi Landlord/Manager hiện tại. Có thể xem nhanh tổng/đã thu/chưa thu/quá hạn bằng cách lọc theo từng trạng thái (thay cho màn Revenue Report riêng — ngoài phạm vi Phase 1).
- **Edge cases:** Rỗng theo filter → empty state phù hợp ngữ cảnh.

### B-02 — Create Invoice
- **Mục đích:** Nhập chỉ số điện/nước mới, xem trước hoá đơn hệ thống tự tính, chọn kênh gửi.
- **Thành phần chính:** Chọn phòng/hợp đồng Active cần tạo hoá đơn, hiện chỉ số cũ để đối chiếu, input chỉ số điện mới, input chỉ số nước mới, bảng preview (Tiền phòng, Tiền điện: chỉ số cũ→mới/kWh/đơn giá/thành tiền, Tiền nước tương tự, từng dòng phí định kỳ/chi phí  (cho phép edit và thêm dòng), **Tổng cộng**), thông tin tài khoản ngân hàng, chọn kênh gửi (SMS/Zalo/Cả hai), nút "Gửi hoá đơn", nút "Lưu nháp" (Draft).
- **Trạng thái:** Nhập chỉ số → Preview (Draft) → Đã gửi (Sent).
- **Hành động & điều hướng:** Nhập chỉ số không hợp lệ (< chỉ số cũ) → chặn ngay tại chỗ. Gửi → tạo `invoice` (snapshot `contractVersionId`, `roomLabel`, `houseName`, `tenantName` tại thời điểm gửi), trạng thái "Sent" → hệ thống gửi qua kênh đã chọn → B-01 (Invoice List cập nhật).
- **Dữ liệu hiển thị:** Dữ liệu tính từ chỉ số vừa nhập + điều khoản từ `contract_version` hiện hành.
- **Edge cases:** Landlord/Manager chưa có số tài khoản ngân hàng trong Owner Profile (U-01) → cảnh báo trước khi gửi để Tenant không nhận hoá đơn thiếu thông tin thanh toán.

### B-03 — Invoice Detail
- **Mục đích:** Xem chi tiết 1 hoá đơn, đánh dấu đã thu tiền.
- **Thành phần chính:** Bảng chi tiết hoá đơn (giống preview ở B-02), badge trạng thái (Draft/Sent/Collected/Overdue), nút "Đánh dấu đã thu tiền" (khi Sent/Overdue), nút "Huỷ đánh dấu" (khi Collected, phòng trường hợp đánh dấu nhầm — BR-PAY-06), nút "Gửi lại" (khi cần gửi lại SMS/Zalo).
- **Trạng thái:** Draft / Sent / Overdue / Collected.
- **Hành động & điều hướng:** "Đánh dấu đã thu tiền" → trạng thái chuyển "Collected". "Huỷ đánh dấu" → quay lại "Sent".
- **Dữ liệu hiển thị:** Chi tiết hoá đơn + lịch sử trạng thái (thời điểm gửi, thời điểm đánh dấu thu tiền).
- **Edge cases:** Hoá đơn quá hạn → cảnh báo màu đỏ + số ngày trễ.

---

## 2.6 User Setting (U-01 → U-04)

### U-01 — Owner/Manager Profile (Detail/Edit)
- **Mục đích:** Xem/sửa hồ sơ Chủ nhà/manager — Landlord và Manager có hồ sơ tài khoản riêng tùy ai là người đăng nhập.
- **Thành phần chính:** Avatar (optional), Họ tên, SĐT (đổi cần OTP lại), Giới tính, Ngày sinh, Email (optional), Số CCCD/CMND, Mã số thuế (optional- chỉ landlord), Thông tin tài khoản ngân hàng (chỉ landlord, dùng làm mặc định khi tạo hoá đơn ở B-02), nút Lưu. Button 
- **Trạng thái:** Xem / Đang sửa.
- **Hành động & điều hướng:** Lưu → toast xác nhận, ở lại màn hình.
- **Dữ liệu hiển thị:** Thông tin tài khoản Landlord hiện tại.
- **Edge cases:** Đổi SĐT cần xác thực OTP lại.

### U-02 — Manager Management List
- **Mục đích:** Landlord xem toàn bộ tài khoản Manager đã tạo.
- **Thành phần chính:** List mỗi Manager (avatar, họ tên, SĐT, số Nhà/Dãy trọ được cấp quyền, badge trạng thái active/disabled), nút nổi "+" → U-03.
- **Trạng thái:** Có dữ liệu / Rỗng.
- **Hành động & điều hướng:** Tap "+" → U-03 (tạo mới). Tap 1 Manager → U-03 (xem/sửa).
- **Dữ liệu hiển thị:** Toàn bộ Manager do Landlord này tạo.
- **Edge cases:** Chỉ Landlord truy cập được màn này — Manager đăng nhập sẽ không thấy mục "Manager Management" trong User Setting của họ.

### U-03 — Manager Detail (Create/Edit + cấp quyền theo House)
- **Mục đích:** Tạo Manager mới hoặc sửa quyền truy cập của 1 Manager có sẵn.
- **Thành phần chính:** Họ tên (bắt buộc), SĐT (bắt buộc, dùng làm tài khoản đăng nhập), Mật khẩu ban đầu (bắt buộc khi tạo mới), Ghi chú (optional), danh sách chọn Nhà/Dãy trọ được cấp quyền (multi-select từ H-01), toggle Active/Disabled, nút Lưu/Huỷ, nút "Xoá tài khoản Manager" (chỉ hiện khi sửa).
- **Trạng thái:** Tạo mới / Chỉnh sửa / Lỗi validate.
- **Hành động & điều hướng:** Lưu → tạo/cập nhật `manager_account` + `manager_house_access` → U-02.
- **Dữ liệu hiển thị:** Thông tin Manager (nếu sửa) + danh sách House hiện có của Landlord để chọn cấp quyền.
- **Edge cases:** SĐT trùng với Manager/Landlord khác → chặn, báo lỗi. Bỏ chọn hết Nhà/Dãy trọ → Manager coi như không còn quyền gì, cảnh báo trước khi lưu.

### U-04 — Xác nhận Đăng xuất
- **Mục đích:** Xác nhận trước khi đăng xuất — FR-AUTH-06.
- **Thành phần chính:** Dialog overlay: "Bạn có chắc muốn đăng xuất?", 2 nút "Huỷ"/"Đăng xuất".
- **Trạng thái:** Dialog hiện/ẩn.
- **Hành động & điều hướng:** "Huỷ" → đóng dialog. "Đăng xuất" → xoá session → S-01.
- **Dữ liệu hiển thị:** Không.
- **Edge cases:** Không có.

---

## 3. Liên kết với Figma / FigJam

- Wireframe MVP: **BizTown Rent-Manager — MVP Wireframes** → https://www.figma.com/design/AElzfTBuL8YyA8OJ85f7aX/BizTown-Rent-Manager-%E2%80%94-MVP-Wireframes?node-id=133-57 (page MVP Wireframes (EN) - Version2) : đầy đủ 22 màn hình theo đúng mục 1 ở trên, chia theo 5 khu vực đúng cấu trúc 5 menu — Shared (S-00→S-03), House/Room Management (H-01→H-04), Tenant Management (N-01→N-02), Contract Management (C-01→C-05), Bill Management (B-01→B-03), User Setting (U-01→U-04). Dùng chung style/token với Version 1 (nền `#F5F6F9`, header navy `#23305E`, accent cam `#EF9F27`, bo góc 12–16px, Material 3 Design Kit cho icon) và bottom nav 5 tab dùng chung Landlord/Manager theo [DESIGN-SYSTEMS.md](DESIGN-SYSTEMS.md).
- Diagram tóm tắt entity + luồng theo 5 menu (nguồn cho đợt viết lại tài liệu 2026-09-03): FigJam board `PAuYWdSon7WcPKdRQStoPR`.

**Trạng thái:** Ver2 (tài liệu) — Figma MVP Wireframes (EN) - Version2 (22 màn) đã build xong. Còn thiếu: prototype liên kết giữa các màn (chỉ mới là wireframe tĩnh, chưa nối flow bằng Figma prototyping).

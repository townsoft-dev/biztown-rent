# Screen Spec — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 1  **Last updated:** 2026-08-28

---

## 1. Screen Inventory (MVP) — 36 màn hình

### 1.1 Chung (Shared / cả 2 vai trò) — 6 màn

| # | Màn hình | Vai trò | Ghi chú |
|---|---|---|---|
| S-00 | Splash | Cả hai | |
| S-01 | Chọn vai trò / Đăng ký | Cả hai | Xem flow onboarding |
| S-02 | Nhập SĐT & OTP | Cả hai | |
| S-03 | Trung tâm thông báo | Cả hai | |
| S-04 | Hồ sơ cá nhân / Cài đặt | Cả hai | Có mục "Đăng xuất" dẫn tới S-05 |
| S-05 | Xác nhận Đăng xuất | Cả hai | Dialog xác nhận → xem [USER-FLOWS](USER-FLOWS.md) Flow Z |

### 1.2 Chủ trọ (Landlord) — 19 màn

| # | Màn hình | Ghi chú |
|---|---|---|
| L-01 | Trang chủ / Dashboard Chủ trọ | Tổng quan: số phòng trống/đã thuê, cần thu tháng này, yêu cầu sửa chữa mới |
| L-02 | Danh sách Dãy trọ/Nhà | |
| L-03 | Thêm/Sửa Dãy trọ | |
| L-04 | Danh sách Phòng (theo dãy trọ) | Filter theo trạng thái |
| L-05 | Thêm/Sửa Phòng | |
| L-06 | Chi tiết Phòng | Có toggle "Đăng tìm người thuê / Public listing" |
| L-07 | Danh sách Người thuê (Tenant Pool) | Bao gồm cả người thuê chưa gắn phòng |
| L-08 | Thêm/Sửa hồ sơ Người thuê | Dùng riêng cho Flow #2 (Tenant Registration), độc lập với tạo hợp đồng |
| L-09 | Tạo Hợp đồng thuê | Chọn người thuê có sẵn (Tenant Pool / Yêu cầu liên hệ) hoặc thêm nhanh mới |
| L-10 | Chi tiết Hợp đồng | |
| L-11 | Kết thúc Hợp đồng / Trả phòng | |
| L-12 | Nhập chỉ số điện nước | |
| L-13 | Xem trước & Gửi Hoá đơn | |
| L-14 | Danh sách Hoá đơn | Filter theo trạng thái/kỳ |
| L-15 | Chi tiết Hoá đơn + Xác nhận đã thu | |
| L-16 | Báo cáo doanh thu | |
| L-17 | Danh sách Yêu cầu (Sửa chữa/Bảo trì/Đăng ký lưu trú/Khác) | |
| L-18 | Chi tiết Yêu cầu | |
| L-19 | Danh sách Yêu cầu liên hệ (Rental Inquiries) | Flow #3 — người quan tâm gửi từ T-08/T-10 |

### 1.3 Người thuê (Tenant) — 11 màn

| # | Màn hình | Ghi chú |
|---|---|---|
| T-01 | Trang chủ Người thuê | Hoá đơn gần nhất, hợp đồng, thông báo, entry point "Tìm phòng" |
| T-02 | Chi tiết Hợp đồng của tôi | |
| T-03 | Danh sách Hoá đơn | |
| T-04 | Chi tiết Hoá đơn + Thông tin thanh toán | |
| T-05 | Xác nhận đã chuyển khoản (đính kèm ảnh) | |
| T-06 | Tạo Yêu cầu (Sửa chữa/Bảo trì/Đăng ký lưu trú/Khác) | |
| T-07 | Danh sách Yêu cầu của tôi | |
| T-08 | Tìm phòng (Search Listings) | Flow #3. Bắt buộc đăng nhập (BR-LIST-04) |
| T-09 | Bộ lọc Tìm phòng (Filters) | Flow #3 |
| T-10 | Chi tiết Phòng (public view) | Flow #3 |
| T-11 | Xác nhận đã gửi Yêu cầu liên hệ | Flow #3 |

---

## 2. Đặc tả chi tiết (Detailed Spec) — đầy đủ 36/36 màn hình

> Template chuẩn cho mỗi màn hình: **Mục đích → Thành phần chính → Trạng thái (states) → Hành động & điều hướng → Dữ liệu hiển thị → Edge cases**

## 2.1 Shared (S-00 → S-05)

### S-00 — Splash

- **Mục đích:** Màn hình mở app — hiển thị thương hiệu trong lúc hệ thống kiểm tra phiên đăng nhập (session) hiện có.
- **Thành phần chính:** Logo BizTown Rent-Manager (bản trên nền navy), tagline "Simple rental management", nền navy đặc trưng thương hiệu.
- **Trạng thái màn hình:** Đang kiểm tra session (mặc định, có thể thêm loading indicator nhỏ nếu thời gian chờ > 1-2s).
- **Hành động & điều hướng:** Tự động điều hướng sau khi kiểm tra xong — chưa từng đăng nhập/không có session → S-01; có session hợp lệ → thẳng vào Trang chủ theo vai trò đã lưu (L-01 hoặc T-01), không cần qua S-01/S-02 lại.
- **Dữ liệu hiển thị:** Không có dữ liệu động — màn hình tĩnh.
- **Edge cases:** Mạng chậm khi kiểm tra session (liên quan NFR-04) → không để màn hình treo vô thời hạn, cần timeout hợp lý (10 phút). Session hết hạn/token invalid → xử lý như chưa đăng nhập, về S-01.

### S-01 — Chọn vai trò / Đăng ký

- **Mục đích:** Điểm vào cho người dùng mới — chọn vai trò (Chủ trọ/Người thuê) để bắt đầu đăng ký, hoặc chuyển sang đăng nhập nếu đã có tài khoản.
- **Thành phần chính:** Logo nhỏ ở đầu trang, 2 thẻ chọn vai trò "Chủ trọ" / "Người thuê" (icon + mô tả ngắn 1 dòng mỗi vai trò), nút CTA chính (VD "Bắt đầu"), liên kết phụ "Đã có tài khoản? Đăng nhập".
- **Trạng thái màn hình:** Mặc định (chọn vai trò tự do) / Đến từ lời mời qua link (vai trò Người thuê được điền sẵn & khoá, kèm dòng ngữ cảnh "Bạn được mời tham gia với vai trò Người thuê" — xem [USER-FLOWS](USER-FLOWS.md) Flow A2).
- **Hành động & điều hướng:** Chọn "Chủ trọ" → S-02 (đăng ký với vai trò Landlord). Chọn "Người thuê" → S-02 (đăng ký với vai trò Tenant). "Đăng nhập" → S-02 (cùng màn hình nhập SĐT, hệ thống tự nhận diện tài khoản đã tồn tại theo FR-AUTH-03).
- **Dữ liệu hiển thị:** Không có dữ liệu người dùng — chỉ là bước chọn.
- **Edge cases:** ⚠️ Người thuê bấm thẳng vào link mời khi **chưa cài app** → theo Flow A2 có thể bỏ qua màn này, vào thẳng bước "xác nhận thông tin cá nhân" sau khi cài app xong — cần dev xác nhận cơ chế deep-link cụ thể.

### S-02 — Nhập SĐT & OTP

- **Mục đích:** Xác thực số điện thoại bằng OTP (Firebase Phone Auth) cho cả đăng ký mới và đăng nhập lại; tạo mật khẩu cho tài khoản mới hoặc khi khôi phục mật khẩu.
- **Thành phần chính:** Input số điện thoại + nút "Gửi mã OTP"; sau khi gửi: 6 ô nhập OTP + đồng hồ đếm ngược + link "Gửi lại mã"; nếu là tài khoản mới hoặc quên mật khẩu: thêm bước "Tạo mật khẩu" (2 field: mật khẩu + xác nhận mật khẩu) sau khi OTP đúng.
- **Trạng thái màn hình:** Nhập SĐT → Đang gửi OTP → Nhập OTP → (OTP sai / Hết hạn — trạng thái lỗi) → Tạo mật khẩu (chỉ user mới/quên mật khẩu) → Hoàn tất.
- **Hành động & điều hướng:** OTP đúng + tài khoản đã có mật khẩu (đăng nhập) → thẳng vào Trang chủ theo vai trò (L-01/T-01). OTP đúng + tài khoản mới → bước Tạo mật khẩu → nếu đến từ S-01 (chưa chọn vai trò) tiếp tục hoàn tất onboarding → Trang chủ trống theo vai trò đã chọn ở S-01. Cũng dùng lại chính màn này cho "Quên mật khẩu" (FR-AUTH-06) — xác thực OTP trước, sau đó cho tạo mật khẩu mới.
- **Dữ liệu hiển thị:** Không lưu dữ liệu nghiệp vụ — chỉ luồng xác thực.
- **Edge cases:** Nhập sai OTP nhiều lần → cần rate-limit/khoá tạm (nhập sai 5 lần thì khóa 10 phút). SĐT đã tồn tại nhưng người dùng bấm "Đăng ký" (từ S-01) → cần thông báo rõ và gợi ý chuyển sang luồng đăng nhập. SĐT của Người thuê đến từ lời mời (Flow A2) không khớp SĐT trong hồ sơ Tenant mà Landlord đã tạo trước (L-08) → hiển thị lời nhắn "liên lạc với chủ trọ", cần cơ chế đối chiếu/cảnh báo.

### S-03 — Trung tâm thông báo

- **Mục đích:** Nơi tập trung toàn bộ thông báo trong app (Must theo FR-NOTI-03), cho cả 2 vai trò.
- **Thành phần chính:** Danh sách thông báo dạng list, mỗi dòng gồm: icon theo loại sự kiện, tiêu đề, tóm tắt ngắn, thời gian tương đối (VD "2 giờ trước"), chấm tròn đánh dấu chưa đọc. Có thể có tab/filter "Tất cả" / "Chưa đọc".
- **Trạng thái màn hình:** Có thông báo (list) / Rỗng ("Chưa có thông báo nào").
- **Hành động & điều hướng:** Bấm vào 1 thông báo → đánh dấu đã đọc + điều hướng tới màn hình liên quan tương ứng theo loại sự kiện (BR-NOTI-01→08): hoá đơn mới/nhắc thanh toán → L-15 (Landlord) hoặc T-04 (Tenant); yêu cầu mới/cập nhật trạng thái → L-18 (Landlord) hoặc T-07 (Tenant, xem chi tiết); Landlord xác nhận đã thu tiền → T-04; lời mời tham gia app → màn hình xác nhận mời (Flow A2); yêu cầu liên hệ mới (Flow #3) → L-19.
- **Dữ liệu hiển thị:** Theo các loại sự kiện ở [BUSINESS-RULES](BUSINESS-RULE.md) mục 5 (Notification Rules).
- **Edge cases:** Thông báo trỏ tới 1 thực thể đã bị xoá/không còn hợp lệ (VD yêu cầu đã bị huỷ) → cần trạng thái "không thể mở, nội dung đã thay đổi" thay vì lỗi trắng màn hình thì hiển thị "data not found".

### S-04 — Hồ sơ cá nhân / Cài đặt

- **Mục đích:** Xem/sửa thông tin cá nhân, truy cập cài đặt, và là điểm vào cho Đăng xuất.
- **Thành phần chính:** Ảnh đại diện, họ tên (sửa được), số điện thoại (hiển thị, cho sửa nhưng phải nhập otp lại), vai trò hiện tại (read-only: Chủ trọ hoặc Người thuê), mục "Đổi mật khẩu", mục "Điều khoản sử dụng & Chính sách bảo mật" (để trống tới khi được cập nhập), mục "Đăng xuất".
- **Trạng thái màn hình:** Xem / Đang sửa thông tin.
- **Hành động & điều hướng:** Lưu thay đổi hồ sơ → toast xác nhận, ở lại màn hình. Bấm "Đổi mật khẩu" → luồng xác thực lại (có thể tái dùng S-02 dạng rút gọn). Bấm "Đăng xuất" → S-05.
- **Dữ liệu hiển thị:** Thông tin tài khoản người dùng hiện tại.
- **Edge cases:** Đổi SĐT cần xác thực OTP lại →  có hỗ trợ đổi SĐT trong MVP không .

### S-05 — Xác nhận Đăng xuất

- **Mục đích:** Xác nhận lại trước khi đăng xuất, tránh bấm nhầm — theo FR-AUTH-07 và [USER-FLOWS](USER-FLOWS.md)` Flow Z.
- **Thành phần chính:** Hộp thoại (dialog) overlay trên S-04: tiêu đề "Bạn có chắc muốn đăng xuất?", 2 nút "Huỷ" và "Đăng xuất".
- **Trạng thái màn hình:** Chỉ 1 trạng thái (dialog hiện/ẩn).
- **Hành động & điều hướng:** "Huỷ" → đóng dialog, quay lại S-04. "Đăng xuất" → xoá session/token trên máy → điều hướng về S-02 (màn hình đăng nhập).
- **Dữ liệu hiển thị:** Không có.
- **Edge cases:**  đăng xuất có xoá luôn dữ liệu cache offline

---

## 2.2 Chủ trọ / Landlord (L-01 → L-19)

### L-01 — Trang chủ / Dashboard Chủ trọ

- **Mục đích:** Điểm vào chính của Landlord — cho cái nhìn tổng quan nhanh về tình hình cho thuê & thu tiền.
- **Thành phần chính:** Header (lời chào + icon chuông thông báo → S-03), các thẻ số liệu tổng quan (số phòng trống/đã thuê, tổng cần thu tháng này, số yêu cầu mới chưa xử lý), khu vực truy cập nhanh (VD "Ghi chỉ số", "Tạo hoá đơn", "Thêm phòng"), danh sách hoạt động gần đây (hoá đơn mới thanh toán, yêu cầu mới...), Bottom Navigation (Home/Rooms/Bills/Reports/Profile).
- **Trạng thái màn hình:** Có dữ liệu (đã có ít nhất 1 dãy trọ) / Trống hoàn toàn (tài khoản mới — hiện CTA nổi bật "Thêm dãy trọ đầu tiên" dẫn tới L-03).
- **Hành động & điều hướng:** Tap thẻ "phòng trống/đã thuê" → L-04. Tap thẻ "cần thu tháng này" → L-14 (lọc Chưa thanh toán/Quá hạn). Tap thẻ "yêu cầu mới" → L-17. Tap chuông → S-03. Tap avatar/tab Profile → S-04.
- **Dữ liệu hiển thị:** Toàn bộ số liệu chỉ tính trong phạm vi dữ liệu của Landlord đang đăng nhập (BR-DATA-01).
- **Edge cases:** Tài khoản mới chưa có dãy trọ nào → ẩn các thẻ số liệu, chỉ hiện empty state + CTA. Mạng yếu (NFR-04) → cần skeleton loading thay vì màn hình trắng.

### L-02 — Danh sách Dãy trọ/Nhà

- **Mục đích:** Liệt kê toàn bộ Dãy trọ/Nhà mà Landlord đang quản lý, là điểm vào Flow #1 (House/Room Registration).
- **Thành phần chính:** List card mỗi dãy trọ (ảnh đại diện, tên, địa chỉ rút gọn, tỉ lệ "x/y phòng trống"), nút nổi "+" thêm dãy trọ mới.
- **Trạng thái màn hình:** Có dữ liệu / Rỗng ("Chưa có dãy trọ nào, bấm + để thêm").
- **Hành động & điều hướng:** Tap card → L-04 (danh sách phòng của dãy trọ đó). Tap "+" → L-03.
- **Dữ liệu hiển thị:** Danh sách Dãy trọ thuộc Landlord hiện tại.
- **Edge cases:** Nhiều dãy trọ (Persona B quản lý quy mô vừa) → cần tìm kiếm/sắp xếp nếu danh sách dài (bổ sung search bar).

### L-03 — Thêm/Sửa Dãy trọ

- **Mục đích:** Tạo mới hoặc chỉnh sửa thông tin 1 Dãy trọ/Nhà (FR-ROOM-01).
- **Thành phần chính:** Ảnh (upload, nhiều ảnh), Tên dãy trọ (bắt buộc), Địa chỉ (bắt buộc), Mô tả (optional), nút Lưu/Huỷ.
- **Trạng thái màn hình:** Tạo mới (trống) / Chỉnh sửa (pre-filled) / Lỗi validate.
- **Hành động & điều hướng:** Lưu thành công → quay lại L-02, toast xác nhận. Huỷ → quay lại không lưu.
- **Dữ liệu hiển thị:** Thông tin dãy trọ (nếu đang sửa).
- **Edge cases:** Trùng tên dãy trọ trong cùng tài khoản Landlord → ko chặn chỉ cảnh báo . Xoá dãy trọ đang có phòng còn hợp đồng active → cần chặn tương tự quy tắc xoá phòng ở L-05.

### L-04 — Danh sách Phòng (theo dãy trọ)

- **Mục đích:** Xem toàn bộ phòng trong 1 Dãy trọ, lọc theo trạng thái (FR-ROOM-03/04).
- **Thành phần chính:** Header hiển thị tên dãy trọ đang xem, chip filter (Tất cả/Trống/Đã thuê/Đang sửa chữa), list card phòng (ảnh thumbnail, tên/số phòng, giá thuê, badge trạng thái theo màu — xem [DESIGN](DESIGN.md) mục 6), nút nổi "+" thêm phòng.
- **Trạng thái màn hình:** Theo filter đang chọn / Rỗng theo filter (VD "Không có phòng trống").
- **Hành động & điều hướng:** Tap card → L-06. Tap "+" → L-05 (tạo mới, gắn sẵn vào dãy trọ đang xem).
- **Dữ liệu hiển thị:** Danh sách phòng thuộc dãy trọ đã chọn.
- **Edge cases:** Dãy trọ chưa có phòng nào → empty state + CTA "Thêm phòng đầu tiên".

### L-05 — Thêm/Sửa Phòng

- **Mục đích:** Cho phép Landlord tạo phòng mới hoặc chỉnh sửa thông tin phòng hiện có trong 1 Dãy trọ.
- **Thành phần chính:**
  - Ảnh phòng (upload nhiều ảnh, tối thiểu 1)
  - Tên/Số phòng (bắt buộc)
  - Diện tích (m²) — optional
  - Giá thuê / tháng (bắt buộc, VNĐ)
  - Đơn giá điện (VNĐ/kWh) — bắt buộc nếu bật tính hoá đơn tự động
  - Đơn giá nước (VNĐ/m³ hoặc VNĐ/người —  xem [BUSINESS-RULES](BUSINESS-RULE.md))
  - Phí dịch vụ khác (danh sách có thể thêm: internet, rác, gửi xe...) — optional
  - Trạng thái phòng: Trống / Đã thuê / Đang sửa chữa (read-only, hệ thống tự set trừ "Đang sửa chữa" có thể set tay)
  - Nút Lưu / Huỷ
- **Trạng thái màn hình:** Tạo mới (trống) / Chỉnh sửa (pre-filled) / Lỗi validate (thiếu trường bắt buộc)
- **Hành động & điều hướng:** Lưu thành công → quay lại L-04 (danh sách phòng), hiển thị toast xác nhận. Huỷ → quay lại không lưu.
- **Edge cases:** Xoá phòng đang có hợp đồng active → phải chặn. Trùng tên phòng trong cùng dãy trọ → cảnh báo.

### L-06 — Chi tiết Phòng

- **Mục đích:** Xem đầy đủ thông tin 1 phòng, quản lý trạng thái hiển thị public (Flow #3) và là điểm vào Flow #4 (Tạo hợp đồng).
- **Thành phần chính:** Ảnh gallery, tên/số phòng, giá thuê, diện tích, tiện ích, đơn giá điện/nước, badge trạng thái (Trống/Đã thuê/Đang sửa chữa), toggle **"Đăng tìm người thuê / Public listing"** (chỉ bật được khi phòng đang Trống — BR-LIST-01), nút "Sửa" → L-05, nút "Tạo hợp đồng" (chỉ hiện khi Trống) → L-09; nếu Đã thuê, hiện thẻ tóm tắt hợp đồng hiện tại dẫn tới L-10.
- **Trạng thái màn hình:** Trống (toggle khả dụng, nút Tạo hợp đồng hiện) / Đã thuê (toggle tự tắt & khoá — BR-LIST-02, hiện link hợp đồng) / Đang sửa chữa (toggle khoá tắt).
- **Hành động & điều hướng:** Bật toggle → phòng xuất hiện trong kết quả Tìm kiếm ở T-08 (Flow 3b). Tap "Tạo hợp đồng" → L-09. Tap hợp đồng hiện tại (khi Đã thuê) → L-10.
- **Dữ liệu hiển thị:** Dữ liệu phòng lấy từ hồ sơ đã tạo ở L-05 — màn hình public T-10 dùng lại chính dữ liệu này (BR-LIST-03), không có form nhập riêng cho "tin đăng".
- **Edge cases:** Cố bật toggle khi phòng không ở trạng thái Trống → nút toggle bị ẩn/disable kèm tooltip giải thích.

### L-07 — Danh sách Người thuê (Tenant Pool)

- **Mục đích:** Quản lý "kho" hồ sơ Người thuê — bao gồm cả người chưa gắn phòng nào (mô hình Tenant Pool, BR-CTR-06).
- **Thành phần chính:** Ô tìm kiếm (theo tên/SĐT), chip filter (Tất cả/Chưa gắn phòng/Đang thuê), list mỗi người thuê (avatar, họ tên, SĐT, trạng thái gắn phòng: "Chưa gắn phòng" hoặc "Đang thuê — [tên phòng]"), nút nổi "+" thêm người thuê mới.
- **Trạng thái màn hình:** Có dữ liệu / Rỗng.
- **Hành động & điều hướng:** Tap "+" → L-08 (tạo mới). Tap 1 người thuê → L-08 ở chế độ xem/sửa hồ sơ. Từ đây Landlord có thể tiếp tục sang L-09 để gắn người thuê đã chọn vào 1 phòng cụ thể (theo Flow #2 → #4).
- **Dữ liệu hiển thị:** Toàn bộ hồ sơ Tenant do Landlord này tạo (không thấy Tenant của Landlord khác — BR-DATA-01).
- **Edge cases:** Người thuê đã có hợp đồng ở Landlord khác (BR-DATA-03) — hồ sơ vẫn tách biệt theo từng Landlord, không hiển thị chéo.

### L-08 — Thêm/Sửa hồ sơ Người thuê

- **Mục đích:** Tạo hoặc cập nhật hồ sơ 1 Người thuê, độc lập với việc gắn hợp đồng (Flow #2 — Tenant Registration, FR-CTR-01).
- **Thành phần chính:** Ảnh đại diện (optional), Họ tên (bắt buộc), Số điện thoại (bắt buộc), Số CMND/CCCD (bắt buộc), Ảnh CCCD mặt trước/sau (bắt buộc theo BR-CTR-08), nút Lưu/Huỷ.
- **Trạng thái màn hình:** Tạo mới / Chỉnh sửa / Lỗi validate.
- **Hành động & điều hướng:** Lưu → quay lại L-07 (hoặc, nếu được mở dưới dạng "thêm nhanh" từ trong L-09, quay lại L-09 với người thuê vừa tạo đã được chọn sẵn). Người thuê mới lưu vào Tenant Pool, **chưa** gắn phòng/hợp đồng (BR-CTR-06).
- **Dữ liệu hiển thị:** Hồ sơ người thuê (nếu đang sửa).
- **Edge cases:** SĐT trùng với hồ sơ Tenant có sẵn trong cùng tài khoản Landlord → cảnh báo trùng, gợi ý mở hồ sơ cũ thay vì tạo mới. Lưu trữ ảnh CCCD cần tuân thủ [BUSINESS-RULES](BUSINESS-RULE.md) mục 7 (Privacy) — mã hoá khi lưu (NFR-03).

### L-09 — Tạo Hợp đồng thuê

- **Mục đích:** Gắn 1 Người thuê vào 1 Phòng đang Trống, tạo hợp đồng thuê (Flow #4, FR-CTR-02).
- **Thành phần chính:**
  - Bước chọn người thuê: từ Tenant Pool có sẵn (L-07), từ Yêu cầu liên hệ đã chốt (L-19), hoặc "Thêm nhanh" (mở form rút gọn tương đương L-08)
  - Ngày bắt đầu hợp đồng (bắt buộc)
  - Kỳ hạn thuê (số tháng hoặc ngày kết thúc, bắt buộc)
  - Tiền cọc (bắt buộc, không gợi ý để landlord điền — BR-CTR-01)
  - Tiền thuê/tháng (mặc định lấy từ giá phòng ở L-05, cho phép sửa)
  - **Điều khoản phạt trễ hạn** (mới bổ sung theo BR-PAY-05 — nhập tự do dạng text hoặc công thức đơn giản, vì đây không phải quy tắc cố định toàn hệ thống mà theo từng hợp đồng)
  - Nút Lưu / Huỷ
- **Trạng thái màn hình:** Chọn người thuê → Nhập điều khoản → Xác nhận.
- **Hành động & điều hướng:** Lưu → phòng chuyển trạng thái "Đã thuê" (toggle Public listing tự tắt nếu đang bật — BR-LIST-02) → hệ thống tự gửi lời mời cho người thuê qua SMS/Zalo (Flow A2) → chuyển tới L-10 (Chi tiết Hợp đồng vừa tạo).
- **Dữ liệu hiển thị:** Thông tin người thuê đã chọn + thông tin phòng (giá thuê mặc định).
- **Edge cases:** Phòng vừa được chọn lại có hợp đồng active khác được tạo trước đó trong lúc đang nhập (race condition, nhiều thiết bị) → chặn lưu, báo lỗi "Phòng đã có hợp đồng".

### L-10 — Chi tiết Hợp đồng

- **Mục đích:** Xem toàn bộ thông tin 1 hợp đồng, thực hiện gia hạn hoặc kết thúc hợp đồng.
- **Thành phần chính:** Thông tin người thuê (tên, SĐT, ảnh CCCD), thông tin phòng, ngày bắt đầu/kết thúc, tiền cọc, tiền thuê/tháng, điều khoản phạt trễ hạn (nếu có), badge trạng thái hợp đồng (Active/Sắp hết hạn/Đã kết thúc), nút "Gia hạn", nút "Kết thúc hợp đồng".
- **Trạng thái màn hình:** Active / Sắp hết hạn (hiển thị cảnh báo số ngày còn lại — liên quan BR-NOTI-07, hiện là Could) / Đã kết thúc (ẩn 2 nút hành động, chỉ xem lịch sử).
- **Hành động & điều hướng:** Tap "Gia hạn" → dialog/form nhập kỳ hạn mới (cơ chế thao tác thủ công mỗi lần). Tap "Kết thúc hợp đồng" → L-11.
- **Dữ liệu hiển thị:** Toàn bộ dữ liệu hợp đồng, cả 2 phía Landlord & Tenant đều xem được (FR-CTR-03), Tenant chỉ xem được hợp đồng của chính mình (T-02).
- **Edge cases:** Hợp đồng đã kết thúc nhưng vẫn còn hoá đơn chưa xử lý xong (công nợ tồn đọng) — cần liên kết rõ tới L-11 để xem lại quá trình đối soát.

### L-11 — Kết thúc Hợp đồng / Trả phòng

- **Mục đích:** Xử lý quy trình trả phòng: tổng kết công nợ, đối soát tiền cọc (FR-CTR-04).
- **Thành phần chính:** Danh sách hoá đơn chưa thanh toán (nếu có), số tiền cọc đã nhận ban đầu, ô nhập số tiền hoàn/trừ cọc (kèm ghi chú lý do trừ, nếu có), tổng kết cuối cùng (số tiền hoàn cho Tenant hoặc số tiền Tenant còn nợ), nút "Xác nhận trả phòng".
- **Trạng thái màn hình:** Đang tổng kết / Đã xác nhận.
- **Hành động & điều hướng:** Xác nhận → phòng chuyển trạng thái "Trống" → quay lại L-06 (Chi tiết Phòng, giờ đã Trống trở lại).
- **Dữ liệu hiển thị:** Dữ liệu công nợ & tiền cọc của hợp đồng đang kết thúc.
- **Edge cases:**  Quy trình đối soát cọc cụ thể ([BUSINESS-RULES](BUSINESS-RULE.md)).

### L-12 — Nhập chỉ số điện nước

- **Mục đích:** Ghi chỉ số điện/nước định kỳ hàng tháng cho từng phòng, độc lập với việc tạo hoá đơn (Flow #5, BR-CTR-07).
- **Thành phần chính:** Bước 1 — chọn Dãy trọ; Bước 2 — danh sách Phòng trong dãy trọ đó, mỗi dòng hiện ngày ghi số gần nhất + trạng thái (đã ghi kỳ này/chưa); chọn 1 phòng → form nhập: chỉ số điện mới (hiện chỉ số cũ để đối chiếu), chỉ số nước mới (tương tự), nút Lưu.
- **Trạng thái màn hình:** Chưa ghi kỳ này / Đã ghi kỳ này (hiện read-only, cho sửa lại nếu cần — có cho sửa sau khi đã tạo hoá đơn từ chỉ số đó).
- **Hành động & điều hướng:** Lưu (validate chỉ số mới ≥ chỉ số cũ — BR-BILL-05) → tự động chuyển sang phòng kế tiếp chưa ghi trong cùng dãy trọ, hoặc quay lại danh sách/Trang chủ nếu đã ghi hết, có thể tiếp tục sang Flow #6 (L-13) để tạo hoá đơn.
- **Dữ liệu hiển thị:** Lịch sử chỉ số của từng phòng.
- **Edge cases:** Nhập chỉ số mới nhỏ hơn chỉ số cũ → lỗi validate ngay tại chỗ, không cho lưu.  hỗ trợ ghi số hàng loạt nhiều phòng trong 1 màn (bulk entry) .

### L-13 — Xem trước & Gửi Hoá đơn

- **Mục đích:** Xem lại hoá đơn hệ thống tự tính trước khi gửi, chọn kênh gửi (Flow #6, FR-BILL-02/03/04).
- **Thành phần chính:** Bảng chi tiết (Tiền phòng, Tiền điện: chỉ số cũ→mới/số kWh/đơn giá/thành tiền, Tiền nước: tương tự, từng dòng Phí khác, **Tổng cộng**), chọn kênh gửi (SMS / Zalo / Cả hai), nút "Gửi hoá đơn", nút "Sửa" (quay lại chỉnh chỉ số nếu phát hiện sai).
- **Trạng thái màn hình:** Preview (chưa gửi) / Đã gửi.
- **Hành động & điều hướng:** Gửi → hoá đơn được tạo, trạng thái "Chưa thanh toán", hệ thống tự động gửi qua kênh đã chọn (FR-BILL-04) → chuyển tới L-14, Trang chủ (L-01) cập nhật số liệu "cần thu tháng này".
- **Dữ liệu hiển thị:** Dữ liệu tính từ chỉ số vừa ghi ở L-12 + cấu hình đơn giá/phí khác từ L-05.
- **Edge cases:** Landlord chưa nhập thông tin số tài khoản ngân hàng ở đâu đó trong hồ sơ (liên quan T-04) → nên cảnh báo tại đây trước khi gửi, để Tenant không nhận hoá đơn thiếu thông tin thanh toán (thêm phần ghi số tài khoản ở mục tạo hóa đơn).

### L-14 — Danh sách Hoá đơn

- **Mục đích:** Xem toàn bộ hoá đơn đã tạo, lọc theo trạng thái/kỳ.
- **Thành phần chính:** Chip filter (Tất cả/Chưa thanh toán/Chờ xác nhận/Đã thanh toán/Quá hạn), bộ lọc theo kỳ (tháng/năm), list card hoá đơn (tên phòng, kỳ, số tiền, badge trạng thái theo màu).
- **Trạng thái màn hình:** Theo filter đang chọn.
- **Hành động & điều hướng:** Tap card → L-15.
- **Dữ liệu hiển thị:** Toàn bộ hoá đơn thuộc Landlord hiện tại.
- **Edge cases:** Rỗng theo filter (VD chưa có hoá đơn quá hạn nào) → empty state phù hợp ngữ cảnh.

### L-15 — Chi tiết Hoá đơn + Xác nhận đã thu

- **Mục đích:** Xem chi tiết 1 hoá đơn từ góc nhìn Landlord và xác nhận đã nhận được tiền (FR-BILL-06).
- **Thành phần chính:** Bảng chi tiết hoá đơn (giống T-04), badge trạng thái, nếu Tenant đã đánh dấu "Đã chuyển khoản" (T-05) thì hiện ảnh chứng từ đính kèm (nếu có), nút "Xác nhận đã thu tiền".
- **Trạng thái màn hình:** Chưa thanh toán / Chờ xác nhận (Tenant đã đánh dấu, chờ Landlord duyệt) / Đã thanh toán / Quá hạn.
- **Hành động & điều hướng:** Tap "Xác nhận đã thu tiền" → trạng thái chuyển "Đã thanh toán" → gửi thông báo cho Tenant (BR-NOTI-03).
- **Dữ liệu hiển thị:** Chi tiết hoá đơn + lịch sử trạng thái + ảnh chứng từ (nếu Tenant đính kèm).
- **Edge cases:** Trường hợp Tenant đánh dấu "Đã chuyển khoản" nhầm hoặc Landlord chưa thực sự nhận được tiền — hiện **chưa có** nút "Từ chối xác nhận / báo chưa nhận được" trong tài liệu nguồn, chỉ có 1 chiều Chưa→Chờ xác nhận→Đã thanh toán. cho phép landlord từ chối xác nhận, đẩy thông báo đóng tiền lại 1 lần nữa cho người thuê, đổi trạng thái thành chưa chuyển khoản trên tài khoản của tenant

### L-16 — Báo cáo doanh thu

- **Mục đích:** Xem báo cáo doanh thu tổng hợp theo thời gian/phạm vi (Flow #7, FR-RPT-01/02/03).
- **Thành phần chính:** Bộ chọn khoảng thời gian (tháng/quý/tuỳ chọn), bộ chọn phạm vi (tất cả dãy trọ/1 dãy/1 phòng), 4 thẻ tổng quan (Tổng doanh thu, Đã thu, Chưa thu, Quá hạn), bảng chi tiết theo từng phòng/hợp đồng, nút "Xuất báo cáo" (PDF/Excel).
- **Trạng thái màn hình:** Theo bộ lọc thời gian/phạm vi đang chọn.
- **Hành động & điều hướng:** Tap "Xuất báo cáo" → tạo file PDF/Excel, chia sẻ/tải về (Should, FR-RPT-03).
- **Dữ liệu hiển thị:** Tổng hợp từ toàn bộ hoá đơn trong phạm vi/thời gian đã chọn.
- **Edge cases:** Không có dữ liệu trong khoảng thời gian đã chọn → empty state. Biểu đồ trực quan (doanh thu theo tháng, tỉ lệ lấp đầy) là Could/Phase 2 — MVP chỉ cần dạng số liệu + bảng (FR-RPT-04).

### L-17 — Danh sách Yêu cầu (Sửa chữa/Bảo trì/Đăng ký lưu trú/Khác)

- **Mục đích:** Xem toàn bộ yêu cầu từ Người thuê, lọc theo loại/trạng thái (Flow #8, FR-MAINT-03).
- **Thành phần chính:** Chip filter theo loại (Sửa chữa/Bảo trì/Đăng ký lưu trú/Khác) và theo trạng thái (Mới/Đang xử lý/Đã xử lý/Từ chối), list card (tên Tenant, phòng, loại yêu cầu, mô tả rút gọn, thời gian gửi, badge trạng thái).
- **Trạng thái màn hình:** Theo filter.
- **Hành động & điều hướng:** Tap card → L-18.
- **Dữ liệu hiển thị:** Toàn bộ yêu cầu thuộc các phòng/Tenant của Landlord hiện tại.
- **Edge cases:** Rỗng theo filter.

### L-18 — Chi tiết Yêu cầu

- **Mục đích:** Landlord xem & xử lý 1 yêu cầu từ Tenant.
- **Thành phần chính:**
  - Thông tin phòng & người gửi yêu cầu
  - Loại vấn đề (dropdown: Sửa chữa / Bảo trì / Đăng ký lưu trú / Khác — khác thì có input để điền)
  - Mô tả chi tiết + ảnh đính kèm (gallery)
  - Thời gian gửi
  - Trạng thái hiện tại (Mới / Đang xử lý / Đã xử lý / Từ chối)
  - Ô ghi chú phản hồi của Landlord
  - Nút cập nhật trạng thái
- **Trạng thái màn hình:** Theo từng trạng thái yêu cầu — nút hành động thay đổi tương ứng (VD: "Mới" → nút "Tiếp nhận"; "Đang xử lý" → nút "Hoàn tất").
- **Hành động & điều hướng:** Cập nhật trạng thái → gửi thông báo cho Tenant → quay lại L-17.
- **Edge cases:** Yêu cầu bị Tenant huỷ trước khi xử lý →  có cho phép huỷ không. Chi phí sửa chữa gắn vào hoá đơn kỳ sau > thêm trường "Chi phí phát sinh" tại đây cho landlord điền 

### L-19 — Danh sách Yêu cầu liên hệ (Rental Inquiries)

- **Mục đích:** Quản lý các yêu cầu liên hệ từ người quan tâm gửi qua Flow #3 (Search) — FR-DISC-05.
- **Thành phần chính:** List mỗi yêu cầu (tên người quan tâm, SĐT liên hệ, phòng họ quan tâm, thời gian gửi, badge trạng thái: Mới/Đã liên hệ/Không chốt), tap vào 1 dòng → chi tiết (đầy đủ thông tin trên + nút gọi điện/nhắn Zalo ra ngoài app + nút đánh dấu trạng thái).
- **Trạng thái màn hình:** Theo trạng thái yêu cầu.
- **Hành động & điều hướng:** Đánh dấu "Đã liên hệ" hoặc "Không chốt" (cập nhật trạng thái). Nếu chốt thuê → Landlord chủ động chuyển sang Flow #2 (L-08, tạo hồ sơ Tenant nếu người này chưa có trong Tenant Pool) rồi Flow #4 (L-09, chọn từ "Yêu cầu liên hệ" làm nguồn người thuê) — yêu cầu liên hệ **không tự động** tạo hồ sơ Tenant hay hợp đồng (BR-LIST-05).
- **Dữ liệu hiển thị:** Danh sách yêu cầu liên hệ tới các phòng của Landlord hiện tại.
- **Edge cases:** : thời gian lưu trữ /tự ẩn 1 yêu cầu nếu Landlord không phản hồi - vô thời hạn cho tới khi Landlord tự đánh dấu.

---

## 2.3 Người thuê / Tenant (T-01 → T-11)

### T-01 — Trang chủ Người thuê

- **Mục đích:** Điểm vào chính của Tenant — xem nhanh hoá đơn/hợp đồng và truy cập Tìm phòng.
- **Thành phần chính:** Header (lời chào + icon chuông → S-03), thẻ hoá đơn gần nhất (số tiền, hạn thanh toán, badge trạng thái, CTA "Xem/Thanh toán"), thẻ tóm tắt hợp đồng hiện tại (tên phòng, ngày hết hạn), entry point nổi bật "Tìm phòng" (Flow #3) → T-08, danh sách thông báo/hoạt động gần đây, Bottom Navigation (Home/Contract/Bills/Repairs/Profile).
- **Trạng thái màn hình:** Đang có hợp đồng active (hiện đầy đủ thẻ hoá đơn/hợp đồng) / Chưa có hợp đồng nào (trạng thái mới hoặc đang tìm phòng — ẩn thẻ hợp đồng/hoá đơn, hiện CTA "Tìm phòng" nổi bật hơn).
- **Hành động & điều hướng:** Tap thẻ hoá đơn → T-04. Tap thẻ hợp đồng → T-02. Tap "Tìm phòng" → T-08. Tap chuông → S-03.
- **Dữ liệu hiển thị:** Chỉ dữ liệu thuộc về Tenant hiện tại (BR-DATA-02).
- **Edge cases:** Tenant chưa từng có hợp đồng nào (mới đăng ký, hoặc đang giữa 2 hợp đồng) → home hiển thị trạng thái trống + đẩy mạnh CTA Tìm phòng.

### T-02 — Chi tiết Hợp đồng của tôi

- **Mục đích:** Cho Tenant xem chi tiết hợp đồng đang thuê (FR-CTR-03, phía Tenant).
- **Thành phần chính:** Thông tin phòng (ảnh, tên, địa chỉ), ngày bắt đầu/kết thúc, tiền cọc, tiền thuê/tháng, badge trạng thái (Active/Sắp hết hạn/Đã kết thúc), thông tin liên hệ Landlord (tên, SĐT).
- **Trạng thái màn hình:** Active / Sắp hết hạn / Đã kết thúc.
- **Hành động & điều hướng:** Xem lịch sử hoá đơn liên quan tới hợp đồng này → T-03.
- **Dữ liệu hiển thị:** Chỉ hợp đồng của chính Tenant đang đăng nhập (BR-DATA-02).
- **Edge cases:** Tenant có nhiều hợp đồng ở nhiều Landlord khác nhau theo thời gian  — > thêm cơ chế chọn/chuyển giữa các hợp đồng (hiện tại/lịch sử) 

### T-03 — Danh sách Hoá đơn

- **Mục đích:** Xem lịch sử toàn bộ hoá đơn của Tenant (FR-BILL-05).
- **Thành phần chính:** Chip filter theo trạng thái/kỳ, list card hoá đơn (kỳ, số tiền, badge trạng thái).
- **Trạng thái màn hình:** Theo filter.
- **Hành động & điều hướng:** Tap card → T-04.
- **Dữ liệu hiển thị:** Toàn bộ hoá đơn của Tenant hiện tại.
- **Edge cases:** Rỗng (Tenant mới, chưa có hoá đơn nào).

### T-04 — Chi tiết Hoá đơn + Thông tin thanh toán

- **Mục đích:** Cho Tenant xem chi tiết 1 hoá đơn và biết cách thanh toán.
- **Thành phần chính:**
  - Kỳ hoá đơn (tháng/năm)
  - Bảng chi tiết: Tiền phòng, Tiền điện (chỉ số cũ → mới, số kWh, đơn giá, thành tiền), Tiền nước (tương tự), Phí khác (từng dòng), **Tổng cộng**
  - Hạn thanh toán
  - Trạng thái: Chưa thanh toán / Chờ xác nhận / Đã thanh toán / Quá hạn (badge màu — xem  [DESIGN](DESIGN.md))
  - Thông tin thanh toán: số tài khoản ngân hàng của Landlord + mã QR nhập khi tạo hóa đơn (cho phép lưu tại profile landlord để lấy làm default)
  - Nút "Tôi đã chuyển khoản" → sang T-05
- **Trạng thái màn hình:** Chưa thanh toán (hiện nút CTA) / Đã thanh toán (ẩn nút CTA, hiện ngày xác nhận)
- **Hành động & điều hướng:** Bấm CTA → T-05. Bấm vào từng dòng chi tiết điện/nước → có thể mở rộng xem chỉ số (accordion).
- **Edge cases:** Hoá đơn quá hạn → hiển thị cảnh báo màu đỏ + số ngày trễ. 

### T-05 — Xác nhận đã chuyển khoản (đính kèm ảnh)

- **Mục đích:** Cho Tenant chủ động báo đã chuyển khoản, kèm ảnh chứng từ (FR-BILL-07).
- **Thành phần chính:** Tóm tắt hoá đơn (kỳ, số tiền), khu vực upload ảnh chứng từ chuyển khoản (optional vì FR-BILL-07 là Should, không bắt buộc), nút "Xác nhận đã chuyển khoản".
- **Trạng thái màn hình:** Chưa gửi / Đã gửi xác nhận.
- **Hành động & điều hướng:** Xác nhận → trạng thái hoá đơn chuyển "Chờ xác nhận" (BR-PAY-03) → quay lại T-04, chờ Landlord xác nhận (L-15).
- **Dữ liệu hiển thị:** Thông tin hoá đơn liên quan.
- **Edge cases:** Không đính kèm ảnh vẫn cho phép xác nhận gửi (vì đây là tính năng Should, không Must) — chỉ hiện gợi ý "nên đính kèm ảnh để xác nhận nhanh hơn".

### T-06 — Tạo Yêu cầu (Sửa chữa/Bảo trì/Đăng ký lưu trú/Khác)

- **Mục đích:** Cho Tenant gửi yêu cầu tới Landlord (Flow #8, FR-MAINT-01) — không chỉ sửa chữa mà mở rộng nhiều loại.
- **Thành phần chính:** Dropdown chọn loại yêu cầu (Sửa chữa/Bảo trì/Đăng ký lưu trú/Khác — khác thì hiện input để tự nhập), ô mô tả chi tiết, khu vực đính kèm ảnh/tài liệu (optional), nút "Gửi yêu cầu".
- **Trạng thái màn hình:** Nhập liệu / Lỗi validate (thiếu mô tả).
- **Hành động & điều hướng:** Gửi → thông báo tới Landlord (BR-NOTI-04) → chuyển tới T-07, yêu cầu mới có trạng thái "Mới".
- **Dữ liệu hiển thị:** Không có dữ liệu trước — form nhập mới.
- **Edge cases:** "Đăng ký lưu trú" có dùng chung form với Sửa chữa/Bảo trì hay cần luồng riêng (hiện đặc tả dùng chung 1 form cho đơn giản).

### T-07 — Danh sách Yêu cầu của tôi

- **Mục đích:** Xem lịch sử & trạng thái các yêu cầu Tenant đã gửi (FR-MAINT-04).
- **Thành phần chính:** Chip filter theo trạng thái, list card (loại yêu cầu, mô tả rút gọn, badge trạng thái, thời gian gửi).
- **Trạng thái màn hình:** Theo filter.
- **Hành động & điều hướng:** Tap card → xem chi tiết (bản chỉ-xem, tương tự L-18 nhưng ẩn các control chỉ Landlord dùng — không có dropdown đổi trạng thái, chỉ hiện trạng thái hiện tại + ghi chú phản hồi của Landlord nếu có).
- **Dữ liệu hiển thị:** Yêu cầu của Tenant hiện tại.
- **Edge cases:** : Tenant có được huỷ yêu cầu trước khi Landlord xử lý  —  thêm nút "Huỷ yêu cầu" ở trạng thái "Mới".

### T-08 — Tìm phòng (Search Listings)

- **Mục đích:** Cho Tenant tìm kiếm phòng đang mở public (Flow #3a, FR-DISC-02). Bắt buộc đăng nhập (BR-LIST-04).
- **Thành phần chính:** Thanh tìm kiếm (icon search + icon vị trí), nút mở bộ lọc → T-09, list card phòng public (ảnh, giá, khu vực/địa chỉ rút gọn, tên dãy trọ), sắp xếp mặc định theo mới nhất/gần nhất.
- **Trạng thái màn hình:** Có kết quả / Không có kết quả theo bộ lọc / Chưa có phòng public nào trong hệ thống.
- **Hành động & điều hướng:** Tap filter → T-09. Tap card → T-10.
- **Dữ liệu hiển thị:** Chỉ các phòng đang bật toggle "Public listing" (từ L-06) trên toàn hệ thống (không giới hạn theo 1 Landlord).
- **Edge cases:** Không có map view trong MVP (BR-LIST-09, Phase 2) — chỉ list + filter dạng text.

### T-09 — Bộ lọc Tìm phòng (Filters)

- **Mục đích:** Thu hẹp kết quả tìm kiếm theo tiêu chí (FR-DISC-02).
- **Thành phần chính:** Chọn khu vực/quận, khoảng giá (min-max hoặc slider), loại phòng (chips chọn nhiều), nút "Áp dụng" và "Xoá bộ lọc".
- **Trạng thái màn hình:** Mặc định (chưa lọc) / Đang chọn.
- **Hành động & điều hướng:** Áp dụng → quay lại T-08 với kết quả đã lọc.
- **Dữ liệu hiển thị:** Không có dữ liệu kết quả tại đây — chỉ là bộ điều khiển filter.
- **Edge cases:** Không có bản đồ chọn khu vực (map view ngoài phạm vi MVP) — chọn khu vực dạng danh sách/text.

### T-10 — Chi tiết Phòng (public view)

- **Mục đích:** Cho Tenant xem đầy đủ thông tin 1 phòng đang mở public và gửi yêu cầu liên hệ (Flow #3a, FR-DISC-03/04).
- **Thành phần chính:** Ảnh gallery, giá thuê, diện tích, tiện ích (icon check từng mục), khu vực/địa chỉ rút gọn, mô tả, tên dãy trọ, nút "Gửi yêu cầu liên hệ". Khác với L-06 ở chỗ đây là view rút gọn, **không có** nút quản lý (Sửa/Tạo hợp đồng/toggle).
- **Trạng thái màn hình:** Mặc định / Đã gửi yêu cầu rồi (ẩn/disable nút, hiện "Bạn đã gửi yêu cầu cho phòng này").
- **Hành động & điều hướng:** Tap "Gửi yêu cầu liên hệ" → bước xác nhận số điện thoại liên hệ (lấy sẵn từ hồ sơ Tenant, cho sửa nếu cần — có thể hiện dưới dạng bottom sheet/dialog ngay trên màn này) → gửi → T-11.
- **Dữ liệu hiển thị:** Dữ liệu phòng lấy trực tiếp từ hồ sơ phòng Landlord đã tạo (BR-LIST-03) — không có nội dung "tin đăng" riêng.
- **Edge cases:** Tenant đã gửi đủ 10 yêu cầu trong ngày (BR-LIST-06) → disable nút "Gửi yêu cầu liên hệ" kèm thông báo giới hạn.

### T-11 — Xác nhận đã gửi Yêu cầu liên hệ

- **Mục đích:** Xác nhận cho Tenant biết yêu cầu liên hệ đã được gửi thành công (Flow #3a).
- **Thành phần chính:** Thông điệp xác nhận (VD "Đã gửi yêu cầu, Chủ trọ sẽ liên hệ lại với bạn"), nút "Quay lại danh sách" (→ T-08) và/hoặc "Về trang chủ" (→ T-01).
- **Trạng thái màn hình:** 1 trạng thái duy nhất.
- **Hành động & điều hướng:** Như trên.
- **Dữ liệu hiển thị:** Không có.
- **Edge cases:** Không có — đây là màn hình xác nhận đơn giản, không có nghiệp vụ phức tạp.

---

## 3. Liên kết với Figma

Wireframe MVP (low-fi, tiếng Anh): **BizTown Rent-Manager — MVP Wireframes** → https://www.figma.com/design/AElzfTBuL8YyA8OJ85f7aX/BizTown-Rent-Manager-%E2%80%94-MVP-Wireframes

**Trạng thái** Ver1

**Cập nhật 2026-08-28 :**


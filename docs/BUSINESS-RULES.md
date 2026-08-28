# Business Rules — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 1  **Last updated:** 2026-08-28

---

## 1. Quy tắc tính Hoá đơn (Billing Calculation)

| ID | Quy tắc | Trạng thái |
|---|---|---|
| BR-BILL-01 | Hoá đơn hàng tháng = Tiền phòng (cố định theo hợp đồng) + Tiền điện + Tiền nước + Tổng phí khác | Draft — cần xác nhận công thức |
| BR-BILL-02 | Tiền điện = (Chỉ số mới − Chỉ số cũ) × Đơn giá điện/phòng | Đơn giá là giá trị default lấy từ nội dung hợp đồng (có thể sửa mỗi lần tạo hóa đơn) |
| BR-BILL-03 | Tiền nước = (Chỉ số mới − Chỉ số cũ) × Đơn giá nước/phòng | tính theo đồng hồ (m³) hay tính khoán theo đầu người/phòng phụ thuộc điều khoản hợp đồng, được tự do điền khi tạo bill |
| BR-BILL-04 | Phí khác = tổng các khoản phí cấu hình theo phòng (internet, rác, gửi xe...) | danh mục phí mặc định hệ thống gợi ý sẵn : "tiền dịch vụ", "tiền vệ sinh", "tiền wifi",... và được tự nhập |
| BR-BILL-05 | Chỉ số điện/nước mới phải ≥ chỉnh số cũ (validate chống nhập sai) |  |
| BR-BILL-06 | Kỳ hoá đơn: theo tháng dương lịch  |  |
| BR-BILL-07 | Không làm tròn số tiền hoá đơn (chỉ bỏ số thập phân)? |  |

---

## 2. Quy tắc Thanh toán & Nhắc nhở (Payment & Reminders)

| ID | Quy tắc | Trạng thái |
|---|---|---|
| BR-PAY-01 | Hạn thanh toán mặc định = N ngày sau khi hoá đơn được gửi | giá trị N mặc định theo nội dung hợp đồng, có cho Landlord tuỳ chỉnh |
| BR-PAY-02 | Phương thức thanh toán MVP: Tenant chuyển khoản ngoài app → tự đánh dấu "Đã thanh toán" (đính kèm ảnh) → Landlord xác nhận thủ công trong app | (theo FR-BILL-06 Must / FR-BILL-07 Should trong [REQUIREMENTS](REQUIREMENTS.md)) — xem [USER-FLOWS](USER-FLOWS.md) Flow B |
| BR-PAY-03 | Trạng thái hoá đơn: `Chưa thanh toán` → (Tenant đánh dấu đã thanh toán) → `Chờ xác nhận` → (Landlord xác nhận) → `Đã thanh toán`; hoặc quá hạn → `Quá hạn` |  |
| BR-PAY-04 | Lịch nhắc tự động: trước hạn X ngày, đúng hạn, sau hạn Y ngày |khớp [REQUIREMENTS](REQUIREMENTS.md) FR-BILL-08/FR-NOTI-02; [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.2. Xem [USER-FLOWS](USER-FLOWS.md) Flow C. giá trị X, Y cụ thể (số ngày trước/sau hạn) . |
| BR-PAY-05 | Phí phạt trễ hạn (nếu có): công thức tính theo **điều khoản ghi trong từng hợp đồng** (không phải công thức cố định toàn hệ thống) | Theo FR-BILL-010 trong [REQUIREMENTS](REQUIREMENTS.md) (Could) — cần làm rõ: điều khoản phạt trễ hạn được nhập ở trong Flow #4 (Lease Contract Creation) |

---

## 3. Quy tắc Hợp đồng & Đặt cọc (Contract & Deposit)

| ID | Quy tắc | Trạng thái |
|---|---|---|
| BR-CTR-01 | Tiền cọc mặc định = X tháng tiền thuê | Landlord tự nhập |
| BR-CTR-02 | Khi trả phòng: Tiền cọc được hoàn lại trừ đi các khoản nợ chưa thanh toán (hoá đơn còn thiếu, chi phí hư hỏng...) | cần người  xác nhận số tiền hoàn |
| BR-CTR-03 | Chấm dứt hợp đồng trước hạn có phạt cọc | có thể thương lượng với chủ trọ |
| BR-CTR-04 | 1 phòng chỉ có 1 hợp đồng "Active" tại 1 thời điểm|1 phòng chỉ 1 người đại diện làm hợp đồng |
| BR-CTR-05 | Gia hạn hợp đồng —  phải thao tác thủ công mỗi lần  ||
| BR-CTR-06 | Tenant có thể được đăng ký (Flow #2) **độc lập** với hợp đồng, tồn tại ở trạng thái "Tenant Pool" chưa gắn phòng, cho tới khi được chọn ở Flow #4 (Lease Contract Creation) |  |
| BR-CTR-07 | Chỉ số điện/nước (Flow #5 Meter Reading) được ghi & lưu **độc lập** với việc tạo hoá đơn — 1 lần ghi số có thể chưa lập tức tạo hoá đơn ngay |  |
| BR-CTR-08 | Hồ sơ Tenant (Flow #2) **lưu ảnh CCCD/CMND** | |

---
## 3bis. Tìm kiếm & Đăng tìm người thuê (Listing Visibility) — Flow #3 (House/Room Search)

| ID | Quy tắc | Trạng thái |
|---|---|---|
| BR-LIST-01 | Chỉ phòng ở trạng thái **Trống** mới được bật toggle "Đăng tìm người thuê / Public listing" |  |
| BR-LIST-02 | Khi phòng chuyển sang "Đã thuê" (có hợp đồng active — xem Flow #4), hệ thống **tự động tắt** toggle Public listing | |
| BR-LIST-03 | Dữ liệu hiển thị ở màn hình public (T-10) lấy trực tiếp từ hồ sơ phòng (Flow #1) — không có form nhập riêng cho "tin đăng" |  |
| BR-LIST-04 | Tenant chỉ xem được danh sách/gửi yêu cầu liên hệ khi **đã đăng nhập** (không hỗ trợ xem ẩn danh trong MVP) | người thuê phải có tài khoản mới xem được danh sách phòng |
| BR-LIST-05 | Yêu cầu liên hệ (inquiry) không tự tạo hồ sơ Tenant hay hợp đồng — Landlord phải chủ động tạo qua Flow #2/#4 nếu chốt thuê |  |
| BR-LIST-06 | Giới hạn số yêu cầu liên hệ Tenant có thể gửi/ngày (chống spam) = **10 yêu cầu/ngày** | |
| BR-LIST-07 | Giới hạn số phòng 1 Landlord được đăng public cùng lúc theo gói dịch vụ | Phase 1 hoàn toàn miễn phí |
| BR-LIST-08 | Thời gian lưu trữ/tự ẩn 1 yêu cầu liên hệ nếu Landlord không phản hồi | khi phòng không còn trống |
| BR-LIST-09 | Bản đồ (map view) cho danh sách tìm kiếm | (Phase 2) — MVP chỉ có list + filter dạng text (theo FR-DISC-07) |

---
## 4. Vai trò & Phân quyền (Roles & Permissions)
| Hành động | Landlord | Tenant | Tài khoản quản lý thứ cấp *(Phase 2, chưa có chi tiết)* |
|---|---|---|---|
| Tạo/sửa/xoá Phòng, Dãy trọ | ✅ | ❌ | `TBD` |
| Tạo hồ sơ Tenant, Hợp đồng | ✅ | ❌ | `TBD` |
| Xem hợp đồng của chính mình | ✅ (tất cả) | ✅ (chỉ của mình) | `TBD` |
| Nhập chỉ số điện nước, tạo hoá đơn | ✅ | ❌ | `TBD` |
| Xem hoá đơn | ✅ (tất cả) | ✅ (chỉ của mình) | `TBD` |
| Xác nhận đã thu tiền | ✅ | ❌ (chỉ tự đánh dấu đã thanh toán) | `TBD` |
| Tạo yêu cầu (sửa chữa/bảo trì/đăng ký lưu trú/khác) | ❌ (không cần, Landlord xử lý) | ✅ | ❌ |
| Cập nhật trạng thái yêu cầu | ✅ | ❌ | `TBD` |
| Xem báo cáo doanh thu | ✅ | ❌ | `TBD`: giới hạn phạm vi nào |
| Bật/tắt Public listing cho phòng, xem Yêu cầu liên hệ | ✅ | ❌ | `TBD` |
| Tìm kiếm/xem phòng public, gửi Yêu cầu liên hệ (Flow #3) | ❌ | ✅ (bắt buộc đăng nhập — BR-LIST-04) | ❌ |

---

## 5. Quy tắc Thông báo (Notification Rules)

| ID | Sự kiện | Kênh | Trạng thái |
|---|---|---|---|
| BR-NOTI-01 | Hoá đơn mới được tạo | Push + SMS/Zalo | Must |
| BR-NOTI-02 | Nhắc thanh toán (trước/đúng/sau hạn) | Push + SMS/Zalo | Must — đã xác nhận trong phạm vi MVP xem BR-PAY-04|
| BR-NOTI-03 | Landlord xác nhận đã thu tiền | Push | Should |
| BR-NOTI-04 | Yêu cầu mới (sửa chữa/bảo trì/đăng ký lưu trú/khác) | Push | Must |
| BR-NOTI-05 | Cập nhật trạng thái yêu cầu | Push | Must |
| BR-NOTI-06 | Lời mời tham gia app (Tenant mới) | SMS/Zalo | Must |
| BR-NOTI-07 | Hợp đồng sắp hết hạn (nhắc gia hạn) | Push + SMS/Zalo | Could |
| BR-NOTI-08 | Yêu cầu liên hệ mới từ Flow #3 (Search) | Push | Must (theo FR-DISC-06) |

---

## 6. Multi-tenancy & Cô lập dữ liệu (Data Isolation)
| ID | Quy tắc |
|---|---|
| BR-DATA-01 | Mỗi Landlord chỉ thấy dữ liệu (Dãy trọ, Phòng, Tenant, Hợp đồng, Hoá đơn) thuộc tài khoản của mình. |
| BR-DATA-02 | Mỗi Tenant chỉ thấy dữ liệu liên quan tới hợp đồng/phòng mình đang thuê — không thấy dữ liệu của Tenant khác hoặc Landlord khác. |
| BR-DATA-03 | 1 Tenant có thể thuê phòng của nhiều Landlord khác nhau cùng lúc (VD: chuyển trọ) — dữ liệu lịch sử vẫn giữ, tách theo từng hợp đồng. | xác nhận có hỗ trợ 1 tài khoản Tenant gắn nhiều hợp đồng ở nhiều nơi khác nhau (kể cả trong quá khứ) |

---

## 7. Quyền riêng tư & Lưu trữ dữ liệu (Privacy & Data Retention)
- Thời gian lưu trữ dữ liệu sau khi hợp đồng kết thúc: 3 năm
- Chính sách xoá tài khoản/dữ liệu theo yêu cầu người dùng: có (phase 2)
- Có cần điều khoản sử dụng (Terms) & chính sách bảo mật (Privacy Policy) hiển thị khi onboarding: Có, bắt buộc
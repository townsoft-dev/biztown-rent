# Requirements — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 1  **Last updated:** 2026-08-28
> **MoSCoW** (Must / Should / Could / Won't-for-MVP)

---

## 1. Phạm vi & Actors

**Actors:**
- `Landlord` — Chủ trọ
- `Tenant` — Người thuê
- `System` — tác vụ tự động (tính hoá đơn, gửi SMS/Zalo, nhắc thanh toán)

**Tech scope:** Mobile app iOS + Android, cross-platform, xem [CLAUDE](CLAUDE.md)

## 2. Functional Requirements

### 2.1 Authentication & Onboarding
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-AUTH-01 | Người dùng đăng ký tài khoản bằng số điện thoại + OTP + Tạo mật khẩu| Must | nhà cung cấp OTP SMS: Firebase Phone Auth |
| FR-AUTH-02 | Người dùng chọn vai trò khi đăng ký lần đầu (Landlord/Tenant) hoặc được gán vai trò qua lời mời | Must | |
| FR-AUTH-03 | Đăng nhập lại bằng SĐT/OTP hoặc mật khẩu | Must | |
| FR-AUTH-04 | Landlord có thể tạo hồ sơ Tenant thay họ và gửi lời mời qua SMS/Zalo | Must | Xem flow #2 trong [USER-FLOWS.md](USER-FLOWS.md) |
| FR-AUTH-05 | Tenant có thể dùng app mà không cần Landlord mời (tự tìm & xin vào phòng bằng mã) | Won't (MVP) | Thuộc marketplace — Phase 2 |
| FR-AUTH-06 | Quên mật khẩu / khôi phục tài khoản | Should | Quên mật khẩu bắt buộc xác nhận OTP để tạo mật khẩu mới |
| FR-AUTH-07 | Đăng xuất (Logout) — xoá session/token, quay về màn hình Đăng nhập, có dialog xác nhận trước khi đăng xuất | Must | Xem [USER-FLOWS.md](USER-FLOWS.md) Flow Z |

### 2.2 Quản lý Nhà/Dãy trọ & Phòng (Property & Room Management)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-ROOM-01 | Landlord tạo/sửa/xoá thông tin Nhà/Dãy trọ (tên, địa chỉ, ảnh) | Must | |
| FR-ROOM-02 | Landlord tạo/sửa/xoá Phòng trong 1 Dãy trọ (tên phòng, giá thuê, diện tích, tiện ích, ảnh) | Must | |
| FR-ROOM-03 | Xem danh sách phòng với trạng thái: Trống / Đã thuê / Đang sửa chữa | Must | |
| FR-ROOM-04 | Lọc/tìm kiếm phòng theo dãy trọ, trạng thái | Should | |
| FR-ROOM-05 | Cấu hình đơn giá điện/nước & phí dịch vụ mặc định theo từng phòng hoặc theo dãy trọ | Must |cố định theo hợp đồng — xem [BUSINESS-RULES](BUSINESS-RULES.md) |
| FR-ROOM-06 | Quản lý nhiều Dãy trọ cùng lúc trong 1 tài khoản Landlord | Must | Bắt buộc theo mô hình đã chọn (đa quy mô) |

### 2.3 Tìm kiếm & Xem nhà/phòng cho thuê (Discovery / Search)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-DISC-01 | Landlord bật/tắt hiển thị 1 phòng lên danh sách tìm kiếm public (toggle "Đăng tìm người thuê") | Must | Chỉ áp dụng cho phòng đang Trống — xem L-06 |
| FR-DISC-02 | Tenant tìm kiếm/lọc danh sách phòng đang mở public theo khu vực, khoảng giá, loại phòng | Must | Xem T-08/T-09 |
| FR-DISC-03 | Tenant xem chi tiết 1 phòng ở chế độ public (ảnh, giá, tiện ích, khu vực, mô tả) | Must | Xem T-10 — dữ liệu lấy từ hồ sơ phòng đã tạo ở FR-ROOM-02 |
| FR-DISC-04 | Tenant gửi "Yêu cầu liên hệ" (inquiry) tới Landlord cho 1 phòng quan tâm | Must | Xem T-11 |
| FR-DISC-05 | Landlord xem danh sách Yêu cầu liên hệ đã nhận, đánh dấu trạng thái (Mới/Đã liên hệ/Không chốt) | Must | Xem L-19 |
| FR-DISC-06 | Landlord nhận thông báo khi có Yêu cầu liên hệ mới | Must | Dùng chung cơ chế push với FR-NOTI-01 |
| FR-DISC-07 | Bản đồ (map view) cho danh sách tìm kiếm | Could | Phase 2, Phase 1 chỉ list + filter text |
| FR-DISC-08 | Giới hạn số yêu cầu liên hệ Tenant gửi/ngày (chống spam) | Should | 10 yêu cầu 1 ngày |
| FR-DISC-09 | Tự động tắt toggle Public listing khi phòng chuyển "Đã thuê" | Must | Xem [BUSINESS-RULES](BUSINESS-RULES.md) BR-LIST-xx |
| FR-DISC-10 | Chat/nhắn tin trong app giữa Tenant quan tâm & Landlord | Won't (MVP) | Trùng với FR chat chung — vẫn ngoài phạm vi theo [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md); MVP chỉ dừng ở gửi inquiry, liên hệ tiếp diễn ra ngoài app |

### 2.4 Quản lý Người thuê & Hợp đồng (Tenant & Contract)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-CTR-01 | Landlord tạo hồ sơ Tenant (tên, SĐT, CMND/CCCD, ảnh giấy tờ) — **độc lập với hợp đồng**, lưu vào "Tenant Pool" (Flow #2 Tenant Registration) | Must | có lưu ảnh CCCD |
| FR-CTR-02 | Landlord tạo Hợp đồng thuê gắn Tenant với Phòng: ngày bắt đầu, kỳ hạn, tiền cọc, tiền thuê | Must | |
| FR-CTR-03 | Xem chi tiết hợp đồng (cả 2 phía Landlord & Tenant) | Must | |
| FR-CTR-04 | Kết thúc hợp đồng / trả phòng, xử lý tiền cọc | Must | chi tiết quy trình đối soát cọc — xem  [BUSINESS-RULES](BUSINESS-RULES.md)|
| FR-CTR-05 | Gia hạn hợp đồng | Must | |
| FR-CTR-06 | Nhiều Tenant trên cùng 1 hợp đồng/phòng (ở ghép) | Could | xem flow #3 |
| FR-CTR-07 | Ký hợp đồng điện tử (e-signature) trong app | Won't (MVP) | Phase 2 |


### 2.5 Hoá đơn điện nước & Thu tiền (Billing & Collection)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-BILL-01 | Landlord nhập chỉ số điện/nước hàng kỳ theo từng phòng | Must | |
| FR-BILL-02 | Hệ thống tự tính hoá đơn = Tiền phòng + Tiền điện + Tiền nước + Phí khác | Must | |
| FR-BILL-03 | Landlord xem trước (preview) hoá đơn trước khi gửi | Must | |
| FR-BILL-04 | Hệ thống **tự động gửi hoá đơn** cho Tenant qua SMS và/hoặc Zalo | Must | đang nghiên cứu chọn nhà cung cấp tích hợp |
| FR-BILL-05 | Tenant xem lịch sử hoá đơn trong app | Must | |
| FR-BILL-06 | Landlord đánh dấu hoá đơn "Đã thu tiền" thủ công | Must | Theo hướng thanh toán thủ công MVP |
| FR-BILL-07 | Tenant chủ động đánh dấu "Đã thanh toán" + đính kèm ảnh chứng từ | Should | |
| FR-BILL-08 | Hệ thống tự động nhắc thanh toán trước/đúng/sau hạn | Must | lịch nhắc cụ thể — xem [BUSINESS-RULES](BUSINESS-RULES.md) |
| FR-BILL-010 | Tính phí phạt trễ hạn tự động | Could | có áp dụng không, công thức theo điều khoản hợp đồng |

### 2.6 Báo cáo doanh thu (Reporting)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-RPT-01 | Landlord xem tổng quan doanh thu theo tháng: Tổng/Đã thu/Chưa thu/Quá hạn | Must | |
| FR-RPT-02 | Lọc báo cáo theo Dãy trọ / Phòng / khoảng thời gian | Should | |
| FR-RPT-03 | Xuất báo cáo PDF/Excel | Should | |
| FR-RPT-04 | Biểu đồ trực quan (doanh thu theo tháng, tỉ lệ lấp đầy phòng) | Could | Phase 2 khả thi hơn |

### 2.7 Yêu cầu sửa chữa / Bảo trì (Maintenance)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-MAINT-01 | Tenant tạo yêu cầu sửa chữa, bảo trì, đăng ký lưu trú,etc  (loại vấn đề, mô tả, ảnh đính kèm) | Must | |
| FR-MAINT-02 | Landlord nhận thông báo yêu cầu mới | Must | |
| FR-MAINT-03 | Landlord cập nhật trạng thái yêu cầu (Tiếp nhận/Đang xử lý/Đã xử lý/Từ chối) | Must | |
| FR-MAINT-04 | Tenant xem lịch sử & trạng thái yêu cầu của mình | Must | |
| FR-MAINT-05 | Gắn chi phí sửa chữa vào hoá đơn kỳ sau | Could | Option tùy trường hợp từng yêu cầu |

### 2.8 Thông báo (Notifications)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-NOTI-01 | Push notification trong app cho các sự kiện chính (hoá đơn mới, thanh toán xác nhận, yêu cầu sửa chữa) | Must | |
| FR-NOTI-02 | Gửi SMS/Zalo song song với push cho các sự kiện quan trọng (hoá đơn, nhắc hạn) | Must | Vì không phải ai cũng mở app thường xuyên |
| FR-NOTI-03 | Trung tâm thông báo (notification inbox) trong app | Must | |

---

## 3. Non-Functional Requirements
| ID | Yêu cầu | Ghi chú |
|---|---|---|
| NFR-01 | Hỗ trợ iOS và Android, cross-platform framework | Flutter|
| NFR-02 | Giao diện tiếng Anh là ngôn ngữ chính | có cần đa ngôn ngữ (English) vào Phase 2 |
| NFR-03 | Dữ liệu cá nhân (CCCD, SĐT) cần mã hoá khi lưu trữ & tuân thủ quy định bảo vệ dữ liệu cá nhân | |
| NFR-04 | Hoạt động ổn định với kết nối mạng yếu (khu trọ/vùng ven đô có thể mạng chậm) | |
| NFR-05 | Thời gian phản hồi tạo hoá đơn tự động < 2s cho 1 phòng |  |
| NFR-06 | Khả năng mở rộng multi-tenant (nhiều chủ trọ, dữ liệu tách biệt an toàn) | Phù hợp mô hình SaaS đã chọn |
| NFR-07 | Sao lưu dữ liệu định kỳ, có khả năng khôi phục | |
| NFR-08 | Accessibility cơ bản (cỡ chữ, contrast) — xem [DESIGN](DESIGN.md) | |

---

## 4. Integration Requirements
| ID | Tích hợp | Trạng thái |
|---|---|---|
| INT-01 | Zalo ZNS (Zalo Notification Service) hoặc Zalo OA để gửi hoá đơn/thông báo | đang nghiên cứu chọn nhà cung cấp |
| INT-02 | SMS Brandname (qua eSMS, Speedsms, hoặc nhà mạng) | đang nghiên cứu chọn nhà cung cấp |
| INT-03 | OTP xác thực đăng ký/đăng nhập |  dùng chung với INT-02 |
| INT-04 | Push notification (Firebase Cloud Messaging / APNs) | Xác nhận lại ở [ARCHITECTURE](ARCHITECTURE.md) |
| INT-05 | Cổng thanh toán online (VNPay/Momo/ZaloPay) | Ngoài phạm vi MVP — Phase 2 |
| INT-06 | Lưu trữ ảnh (hồ sơ, CCCD, ảnh sửa chữa) — Cloud storage |Xác nhận lại ở [ARCHITECTURE](ARCHITECTURE.md) |

---

## 5. Data Overview (sơ bộ — không phải data model đầy đủ, cần thiết kế cụ thểdev/claude)
Các thực thể chính dự kiến: `Landlord`, `Tenant`, `Property` (Dãy trọ/Nhà), `Room` (Phòng), `Contract` (Hợp đồng), `Invoice` (Hoá đơn), `Payment` (Thanh toán), `MaintenanceRequest` (Yêu cầu sửa chữa), `Notification`.

---

## 6. Ngoài phạm vi (Out of Scope cho MVP)
Xem chi tiết tại [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md). Tóm tắt: thanh toán online trong app, vai trò Nhân viên quản lý, chat trong app, e-signature, đa ngôn ngữ. tìm phòng marketplace công khai/SEO/quảng cáo trả phí vẫn ngoài phạm vi.
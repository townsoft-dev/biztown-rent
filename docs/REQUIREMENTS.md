# Requirements — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 2 **Last updated:** 2026-09-03
> **MoSCoW** (Must / Should / Could / Won't-for-MVP)
> **Thay đổi lớn so với Version 1:** Bỏ actor `Tenant` khỏi app (không đăng nhập/không dùng app) — thay bằng actor `Manager` (tài khoản phụ do Landlord tạo). Toàn bộ mục Discovery/Search (2.3) và Maintenance (2.7) chuyển "Ngoài phạm vi Phase 1". Xem [DECISIONS.md](DECISIONS.md) 2026-09-03.

---

## 1. Phạm vi & Actors

**Actors:**
- `Landlord` — Chủ trọ, tài khoản gốc.
- `Manager` — Tài khoản quản lý phụ, **do Landlord tạo** (không tự đăng ký), phạm vi truy cập giới hạn theo từng Nhà/Dãy trọ được cấp quyền (xem [BUSINESS-RULES](BUSINESS-RULES.md) mục 4).
- `Tenant` — Người thuê. **Không phải actor của app trong Phase 1** (không đăng nhập, không thao tác trên app) — chỉ là dữ liệu hồ sơ + người nhận SMS/Zalo một chiều.
- `System` — tác vụ tự động (tính hoá đơn, gửi SMS/Zalo, nhắc thanh toán).

**Tech scope:** Mobile app iOS + Android, cross-platform, xem [CLAUDE](CLAUDE.md)

## 2. Functional Requirements

### 2.1 Authentication & Onboarding
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-AUTH-01 | Landlord đăng ký tài khoản bằng số điện thoại + OTP + Tạo mật khẩu | Must | Supabase Auth Phone/OTP — xem [ARCHITECTURE](ARCHITECTURE.md) |
| FR-AUTH-02 | Đăng nhập lại bằng SĐT/OTP hoặc mật khẩu | Must | Áp dụng cho cả Landlord và Manager |
| FR-AUTH-03 | Landlord tạo tài khoản Manager (SĐT, mật khẩu ban đầu, họ tên) và cấp quyền truy cập theo từng Nhà/Dãy trọ cụ thể | Must | Thay thế FR-AUTH-04 cũ (mời Tenant) — xem Flow User Setting trong [USER-FLOWS.md](USER-FLOWS.md) |
| FR-AUTH-04 | Landlord bật/tắt (khoá) tài khoản Manager, thu hồi/thêm quyền truy cập theo Nhà/Dãy trọ | Must | |
| FR-AUTH-05 | Quên mật khẩu / khôi phục tài khoản (Landlord & Manager) | Should | Bắt buộc xác nhận OTP để tạo mật khẩu mới |
| FR-AUTH-06 | Đăng xuất (Logout) — xoá session/token, quay về màn hình Đăng nhập, có dialog xác nhận trước khi đăng xuất | Must | Xem [USER-FLOWS.md](USER-FLOWS.md) Flow Z |
| ~~FR-AUTH-02 (cũ)~~ | ~~Người dùng chọn vai trò khi đăng ký (Landlord/Tenant)~~ | Removed | Không còn vai trò Tenant tự đăng ký |
| ~~FR-AUTH-05 (cũ)~~ | ~~Tenant tự tìm & xin vào phòng bằng mã~~ | Removed | Gắn với Search — ngoài phạm vi Phase 1 |

### 2.2 Quản lý Nhà/Dãy trọ & Phòng (House/Room Management)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-ROOM-01 | Landlord/Manager (có quyền) tạo/sửa/xoá thông tin Nhà/Dãy trọ (tên, địa chỉ, mô tả, ảnh) | Must | Manager chỉ thao tác trên Nhà/Dãy trọ được Landlord cấp quyền |
| FR-ROOM-02 | Landlord/Manager tạo/sửa/xoá Phòng trong 1 Dãy trọ (số phòng, diện tích, giá tham khảo, tiện ích, phí định kỳ mặc định, ảnh) | Must | |
| FR-ROOM-03 | Xem danh sách phòng với trạng thái: Trống / Đã thuê / Đang sửa chữa | Must | |
| FR-ROOM-04 | Lọc/tìm kiếm phòng theo dãy trọ, trạng thái | Should | |
| FR-ROOM-05 | Cấu hình giá thuê tham khảo & phí dịch vụ định kỳ mặc định theo phòng (dùng làm gợi ý khi tạo hợp đồng, không cố định) | Must | Giá/phí thật sự áp dụng nằm ở phiên bản hợp đồng — xem [BUSINESS-RULES](BUSINESS-RULES.md) |
| FR-ROOM-06 | Quản lý nhiều Dãy trọ cùng lúc trong 1 tài khoản Landlord | Must | Bắt buộc theo mô hình đã chọn (đa quy mô) |
| ~~FR-ROOM cũ về Public listing~~ | ~~Toggle hiển thị public~~ | Removed | Gắn với Search — ngoài phạm vi Phase 1 |

### 2.3 Quản lý Người thuê (Tenant Management)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-TEN-01 | Landlord/Manager tạo hồ sơ Tenant (họ tên, SĐT, giới tính, ngày sinh, email tuỳ chọn, CCCD/CMND, ảnh CCCD 2 mặt, ghi chú) — lưu vào "Tenant Pool" dùng chung cho Landlord | Must | Kế thừa FR-CTR-01 cũ |
| FR-TEN-02 | Tạo hồ sơ Tenant **ngay trong lúc** tạo hợp đồng (shortcut), không bắt buộc tạo trước | Must | |
| FR-TEN-03 | Tìm kiếm/lọc Tenant Pool theo tên/SĐT, theo trạng thái gắn phòng | Should | |
| ~~FR-DISC-xx (toàn bộ mục Discovery/Search cũ)~~ | ~~Tìm kiếm & xem nhà/phòng cho thuê phía Tenant~~ | **Ngoài phạm vi Phase 1** | Yêu cầu Tenant có tài khoản/app — dời Phase 2, xem [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.2 |

### 2.4 Quản lý Hợp đồng (Contract Management)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-CTR-01 | Landlord/Manager tạo Hợp đồng gắn Tenant (từ Tenant Pool hoặc tạo nhanh) với Phòng: ngày bắt đầu, kỳ hạn, tiền cọc, tiền thuê/tháng, đơn giá điện/nước, phí định kỳ, điều khoản phạt trễ hạn (optional), thông tin môi giới (optional: tên, liên hệ, phí) | Must | Khởi tạo `contract` + phiên bản điều khoản đầu tiên (`contract_version`, changeReason = New) |
| FR-CTR-02 | Xem danh sách hợp đồng, lọc theo **sắp hết hạn** | Must | |
| FR-CTR-03 | Xem chi tiết 1 hợp đồng | Must | |
| FR-CTR-04 | **Lịch sử phiên bản điều khoản (Version History)** — mỗi lần gia hạn (Renewal) hoặc sửa điều khoản (Amendment) tạo 1 bản ghi `contract_version` mới, giữ nguyên lịch sử các bản trước | Must | Mới bổ sung — thay cho "gia hạn thủ công không lưu vết" ở Version 1 |
| FR-CTR-05 | Gia hạn hợp đồng (tạo `contract_version` mới, changeReason = Renewal) | Must | |
| FR-CTR-06 | Sửa điều khoản hợp đồng đang hiệu lực (tạo `contract_version` mới, changeReason = Amendment) | Should | VD: đổi đơn giá điện/nước giữa kỳ |
| FR-CTR-07 | Kết thúc hợp đồng / trả phòng — tổng kết công nợ (hoá đơn chưa thanh toán), đối soát tiền cọc (trừ hư hỏng nếu có), xác nhận số tiền hoàn/thu thêm | Must | Tạo bản ghi đối soát (`contract_settlement`) |
| FR-CTR-08 | Nhiều Tenant trên cùng 1 hợp đồng/phòng (ở ghép) | Won't (Phase 1) | Phase 1 chỉ 1 người đại diện (`tenantId`) mỗi hợp đồng |
| FR-CTR-09 | Ký hợp đồng điện tử (e-signature) trong app | Won't (MVP) | Phase 2 |

### 2.5 Hoá đơn điện nước & Thu tiền (Bill Management — Core)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-BILL-01 | Landlord/Manager nhập chỉ số điện/nước mới theo từng phòng khi tạo hoá đơn | Must | |
| FR-BILL-02 | Hệ thống **tự động tính** hoá đơn = Tiền phòng (theo phiên bản hợp đồng hiệu lực) + Tiền điện + Tiền nước + Phí định kỳ khác | Must | Đây là **chức năng cốt lõi (core)** của Phase 1 |
| FR-BILL-03 | Landlord/Manager xem trước (preview) hoá đơn trước khi gửi | Must | |
| FR-BILL-04 | Hệ thống **tự động gửi hoá đơn** cho Tenant qua SMS và/hoặc Zalo | Must | Một chiều — Tenant không có app để xem lại trong app |
| FR-BILL-05 | Landlord/Manager xem danh sách hoá đơn, lọc/sắp xếp theo **trạng thái** (Draft/Sent/Collected/Overdue) và theo **tháng** | Must | |
| FR-BILL-06 | Landlord/Manager đánh dấu hoá đơn "Đã thu tiền" (Collected) thủ công | Must | Không còn bước Tenant tự đánh dấu "Đã thanh toán" (vì không có app) — xem [BUSINESS-RULES](BUSINESS-RULES.md) BR-PAY |
| FR-BILL-07 | Hệ thống tự động nhắc thanh toán trước/đúng/sau hạn qua SMS/Zalo cho Tenant + Push cho Landlord/Manager | Must | Lịch nhắc cụ thể — xem [BUSINESS-RULES](BUSINESS-RULES.md) |
| FR-BILL-08 | Tính phí phạt trễ hạn tự động | Could | Theo điều khoản `lateFeeTerms` trong phiên bản hợp đồng |
| ~~FR-BILL cũ (Tenant xem lịch sử hoá đơn trong app, tự đánh dấu đã thanh toán + đính ảnh)~~ | | Removed | Không có app Tenant |

### 2.6 Báo cáo doanh thu (Reporting)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-RPT-01 | Xem nhanh tổng/đã thu/chưa thu/quá hạn ngay trong Bill Management qua filter theo trạng thái + tháng | Should | Thay thế cho màn Revenue Report riêng — xem [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.2 |
| ~~FR-RPT cũ (màn Revenue Report riêng, xuất PDF/Excel, biểu đồ)~~ | | **Ngoài phạm vi Phase 1** | Dời Phase 2 |

### 2.7 Yêu cầu sửa chữa / Bảo trì (Maintenance)
| ~~FR-MAINT-xx (toàn bộ)~~ | | **Ngoài phạm vi Phase 1** | Yêu cầu Tenant có app để gửi yêu cầu — dời Phase 2, xem [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.2 |

### 2.8 Thông báo (Notifications)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-NOTI-01 | Push notification trong app cho Landlord/Manager (hoá đơn mới tạo, đến hạn ghi số, hợp đồng sắp hết hạn) | Must | Không còn Push cho Tenant (không có app) |
| FR-NOTI-02 | Gửi SMS/Zalo cho Tenant khi có hoá đơn mới và khi nhắc thanh toán | Must | Kênh duy nhất tiếp cận Tenant |
| FR-NOTI-03 | Trung tâm thông báo (notification inbox) trong app cho Landlord/Manager | Must | |

### 2.9 Quản lý tài khoản Manager (User Setting)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-MGR-01 | Landlord xem/sửa Hồ sơ Chủ nhà (họ tên, SĐT, giới tính, ngày sinh, email, CCCD/CMND, mã số thuế, thông tin tài khoản ngân hàng, avatar) | Must | Số tài khoản ngân hàng dùng làm mặc định khi tạo hoá đơn |
| FR-MGR-02 | Landlord tạo/xem/sửa danh sách tài khoản Manager | Must | |
| FR-MGR-03 | Landlord gán/thu hồi quyền truy cập của 1 Manager theo từng Nhà/Dãy trọ cụ thể | Must | `tb_manager_house_access` |
| FR-MGR-04 | Manager chỉ thấy/thao tác trên dữ liệu (Phòng, Tenant liên quan, Hợp đồng, Hoá đơn) thuộc Nhà/Dãy trọ được cấp quyền | Must | Enforce qua RLS — xem [BUSINESS-RULES](BUSINESS-RULES.md) mục 6 |

---

## 3. Non-Functional Requirements
| ID | Yêu cầu | Ghi chú |
|---|---|---|
| NFR-01 | Hỗ trợ iOS và Android, cross-platform framework | Flutter |
| NFR-02 | Giao diện tiếng Anh là ngôn ngữ chính | Đa ngôn ngữ cân nhắc Phase 2 |
| NFR-03 | Dữ liệu cá nhân (CCCD, SĐT) cần mã hoá khi lưu trữ & tuân thủ quy định bảo vệ dữ liệu cá nhân | |
| NFR-04 | Hoạt động ổn định với kết nối mạng yếu (khu trọ/vùng ven đô có thể mạng chậm) | |
| NFR-05 | Thời gian phản hồi tạo hoá đơn tự động < 2s cho 1 phòng | |
| NFR-06 | Khả năng mở rộng multi-tenant (nhiều chủ trọ, dữ liệu tách biệt an toàn) + phân quyền Manager theo phạm vi Nhà/Dãy trọ | Phù hợp mô hình SaaS đã chọn |
| NFR-07 | Sao lưu dữ liệu định kỳ, có khả năng khôi phục | |
| NFR-08 | Accessibility cơ bản (cỡ chữ, contrast) — xem [DESIGN](DESIGN.md) | |

---

## 4. Integration Requirements
| ID | Tích hợp | Trạng thái |
|---|---|---|
| INT-01 | Zalo ZNS (Zalo Notification Service) hoặc Zalo OA để gửi hoá đơn/thông báo cho Tenant | đang nghiên cứu chọn nhà cung cấp |
| INT-02 | SMS Brandname (qua eSMS, Speedsms, hoặc nhà mạng) | đang nghiên cứu chọn nhà cung cấp |
| INT-03 | OTP xác thực đăng ký/đăng nhập (Landlord/Manager) | dùng chung với INT-02, qua Supabase Auth Send SMS Hook |
| INT-04 | Push notification (Firebase Cloud Messaging / APNs) cho Landlord/Manager | Xác nhận lại ở [ARCHITECTURE](ARCHITECTURE.md) |
| INT-05 | Cổng thanh toán online (VNPay/Momo/ZaloPay) | Ngoài phạm vi Phase 1 |
| INT-06 | Lưu trữ ảnh (hồ sơ, CCCD, ảnh phòng) — Cloud storage (Supabase Storage) | |

---

## 5. Data Overview (sơ bộ — xem [DATABASE.md](DATABASE.md) cho schema đầy đủ)
Các thực thể chính: `LandlordAccount`, `OwnerProfile`, `ManagerAccount`, `ManagerHouseAccess`, `House`, `Room`, `Tenant`, `Contract`, `ContractVersion`, `Invoice`, `ContractSettlement`, `Notification` (Landlord/Manager only).

---

## 6. Ngoài phạm vi (Out of Scope cho Phase 1)
Xem chi tiết tại [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.2. Tóm tắt: **toàn bộ app/tài khoản Tenant** (đăng nhập, tìm phòng/marketplace, xem & tự thanh toán hoá đơn trong app, gửi yêu cầu sửa chữa), **Service Request Management**, **Revenue Report** riêng biệt (biểu đồ/xuất file), thanh toán online trong app, phân quyền Manager chi tiết hơn, chat trong app, e-signature, đa ngôn ngữ.

# Business Rules — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 2 **Last updated:** 2026-09-03
> **Thay đổi lớn:** Bỏ mục 3bis (Search/Listing — ngoài phạm vi Phase 1). Cập nhật mục 4 (Roles & Permissions) cho Landlord/Manager, bỏ vai trò Tenant trong app. Cập nhật mục 2 (Payment) — bỏ bước Tenant tự đánh dấu đã thanh toán, đổi trạng thái hoá đơn sang `Draft/Sent/Collected/Overdue`. Thêm mục 3ter (Contract Versioning). Xem [DECISIONS.md](DECISIONS.md) 2026-09-03.

---

## 1. Quy tắc tính Hoá đơn (Billing Calculation)

| ID | Quy tắc | Trạng thái |
|---|---|---|
| BR-BILL-01 | Hoá đơn hàng tháng = Tiền phòng (theo phiên bản hợp đồng — `contract_version.monthlyRent`) + Tiền điện + Tiền nước + Tổng phí định kỳ khác (`recurringFees`) | |
| BR-BILL-02 | Tiền điện = (Chỉ số mới − Chỉ số cũ) × Đơn giá điện (`contract_version.electricityUnitPrice`) | Đơn giá là snapshot theo phiên bản hợp đồng đang hiệu lực tại thời điểm tạo hoá đơn |
| BR-BILL-03 | Tiền nước = (Chỉ số mới − Chỉ số cũ) × Đơn giá nước (`contract_version.waterUnitPrice`) | Tính theo đồng hồ (m³) hay khoán theo đầu người tuỳ điều khoản hợp đồng, tự do điền khi tạo hợp đồng |
| BR-BILL-04 | Phí khác = tổng các khoản phí cấu hình theo `recurringFees` (tên + số tiền) — tuỳ điều khoản hợp đồng, snapshot vào hoá đơn tại thời điểm tạo | Danh mục mặc định giống điều khoản hợp đồng: ví dụ "tiền dịch vụ", "tiền vệ sinh", "tiền wifi"... và được tự nhập thêm hoặc sửa số tiền|
| BR-BILL-05 | Chỉ số điện/nước mới phải ≥ chỉ số cũ (validate chống nhập sai) | |
| BR-BILL-06 | Kỳ hoá đơn: theo tháng dương lịch (hoặc định kỳ khác theo hợp đồng), mốc bắt đầu (`periodStart`) neo theo ngày bắt đầu hợp đồng (`contract.createdAt`/ngày ký) | |
| BR-BILL-07 | Không làm tròn số tiền hoá đơn (chỉ bỏ số thập phân) | |

---

## 2. Quy tắc Thanh toán & Nhắc nhở (Payment & Reminders)

> **Thay đổi quan trọng (2026-09-03):** Vì Tenant không có app/tài khoản trong Phase 1, **bỏ hoàn toàn bước Tenant tự đánh dấu "Đã thanh toán" + đính ảnh chứng từ và trạng thái trung gian "Chờ xác nhận"**. Trạng thái hoá đơn nay chỉ do Landlord/Manager cập nhật thủ công dựa trên xác nhận thực tế (chuyển khoản, tiền mặt, Zalo báo...) ngoài app.

| ID | Quy tắc | Trạng thái |
|---|---|---|
| BR-PAY-01 | Hạn thanh toán mặc định = N ngày sau khi hoá đơn được gửi | Giá trị N theo nội dung hợp đồng, Landlord tuỳ chỉnh |
| BR-PAY-02 | Phương thức thanh toán Phase 1: Tenant chuyển khoản/tiền mặt **ngoài app** (không có bước xác nhận nào trong app từ phía Tenant) → Landlord/Manager tự đánh dấu hoá đơn "Đã thu tiền" (`Collected`) khi xác nhận đã nhận được tiền | **ĐÃ CHỐT (2026-09-03)** — thay thế hoàn toàn BR-PAY-02 cũ (Tenant tự đánh dấu, Landlord xác nhận lại) |
| BR-PAY-03 | Trạng thái hoá đơn (`invoice.status`): `Draft` (đang soạn, chưa gửi) → `Sent` (đã gửi cho Tenant qua SMS/Zalo, chưa thu tiền) → `Collected` (Landlord/Manager đã xác nhận thu tiền); nếu quá hạn mà vẫn `Sent` → hiển thị thêm cờ/derive trạng thái `Overdue` | Thay thế state machine `Chưa thanh toán → Chờ xác nhận → Đã thanh toán` của Version 1 |
| BR-PAY-04 | Lịch nhắc tự động: 3 ngày trước hạn, 1 ngày trước hạn, đúng hạn, 1 ngày sau hạn, 3 ngày sau hạn — gửi SMS/Zalo cho Tenant + Push cho Landlord/Manager khi hoá đơn còn `Sent` (chưa `Collected`) sau các mốc trên | Khớp [REQUIREMENTS](REQUIREMENTS.md) FR-BILL-07; xem [USER-FLOWS](USER-FLOWS.md) Flow C |
| BR-PAY-05 | Phí phạt trễ hạn (nếu có): công thức tính theo **điều khoản ghi trong phiên bản hợp đồng đang hiệu lực** (`contract_version.lateFeeTerms`, free text), không phải công thức cố định toàn hệ thống | Theo FR-BILL-08 (Could) |
| BR-PAY-06 | Landlord/Manager có thể **sửa lại trạng thái đã thu tiền** (VD: đánh dấu nhầm) — chuyển ngược từ `Collected` về `Sent` | Bổ sung 2026-09-03, thay thế nhu cầu "từ chối xác nhận" ở Version 1 (không còn ý nghĩa vì Tenant không tự đánh dấu nữa) |

---

## 3. Quy tắc Hợp đồng & Đặt cọc (Contract & Deposit)

| ID | Quy tắc | Trạng thái |
|---|---|---|
| BR-CTR-01 | Tiền cọc mặc định = X tháng tiền thuê, hoặc Landlord tự nhập số cụ thể | Landlord tự nhập, lưu trong `contract_version.depositAmount` |
| BR-CTR-02 | Khi trả phòng: Tiền cọc được hoàn lại trừ đi các khoản nợ chưa thanh toán (hoá đơn còn `Sent`/`Overdue`) và chi phí hư hỏng (nếu có) — ghi vào `contract_settlement` | Cần Landlord/Manager xác nhận số tiền hoàn cuối cùng |
| BR-CTR-03 | Chấm dứt hợp đồng trước hạn có thể phạt cọc | Có thể thương lượng với chủ trọ, ghi vào `damageDeduction` |
| BR-CTR-04 | 1 phòng chỉ có 1 hợp đồng `Active` tại 1 thời điểm; 1 hợp đồng chỉ có 1 Tenant đại diện (`tenantId`) | Ở ghép nhiều Tenant/hợp đồng ngoài phạm vi Phase 1 (FR-CTR-08) |
| BR-CTR-05 | Gia hạn hoặc sửa điều khoản hợp đồng **tạo bản ghi `contract_version` mới**, không ghi đè bản cũ | Xem mục 3ter — thay cho "thao tác thủ công, không lưu vết" ở Version 1 |
| BR-CTR-06 | Tenant có thể được đăng ký **độc lập** với hợp đồng, tồn tại ở trạng thái "Tenant Pool" chưa gắn phòng, cho tới khi được chọn khi tạo hợp đồng | |
| BR-CTR-07 | Chỉ số điện/nước được ghi & lưu **độc lập** với việc tạo hoá đơn — nhập trực tiếp khi tạo hoá đơn (Bill Management), không có màn ghi số riêng bắt buộc | Đơn giản hoá so với Version 1 (bỏ Flow #5 riêng — gộp vào Create Invoice) |
| BR-CTR-08 | Hồ sơ Tenant lưu ảnh CCCD/CMND (2 mặt) | |
| BR-CTR-09 | Thông tin môi giới/cò nhà (`realEstate`: tên, liên hệ, phí) là optional, lưu theo từng phiên bản hợp đồng | Mới bổ sung (2026-09-03), phục vụ theo dõi chi phí môi giới nếu có |

---

## 3ter. Lịch sử phiên bản Hợp đồng (Contract Versioning) — Mới (2026-09-03)

| ID | Quy tắc |
|---|---|
| BR-VER-01 | Khi tạo hợp đồng mới, hệ thống tạo `contract` (roomId, tenantId, status=Active) + `contract_version` #1 (changeReason=`New`) chứa toàn bộ điều khoản (ngày, tiền thuê, cọc, đơn giá điện/nước, phí, phạt trễ hạn, môi giới). |
| BR-VER-02 | Gia hạn hợp đồng → tạo `contract_version` mới với `changeReason=Renewal`, `versionNo` tăng dần, `startDate` mới nối tiếp `endDate` bản trước (hoặc theo Landlord chỉnh). |
| BR-VER-03 | Sửa điều khoản giữa kỳ (VD đổi đơn giá điện) → tạo `contract_version` mới với `changeReason=Amendment`. |
| BR-VER-04 | `contract.currentVersionId` luôn trỏ tới phiên bản mới nhất — dùng làm điều khoản áp dụng cho hoá đơn kế tiếp. |
| BR-VER-05 | Hoá đơn (`invoice`) lưu `contractVersionId` tại thời điểm tạo (snapshot) — sửa/gia hạn hợp đồng sau đó **không** làm thay đổi hoá đơn đã phát hành trước đó. |

---

## 4. Vai trò & Phân quyền (Roles & Permissions)

> Bỏ hoàn toàn cột `Tenant` (Phase 1 không có tài khoản/thao tác app phía Tenant). Thay `Tài khoản quản lý thứ cấp (Phase 2, chưa có chi tiết)` ở Version 1 bằng vai trò **Manager chính thức**, phạm vi giới hạn theo Nhà/Dãy trọ được cấp (`tb_manager_house_access`).

| Hành động | Landlord | Manager |
|---|---|---|
| Tạo/sửa/xoá Nhà/Dãy trọ | ✅ (tất cả) | ✅ (chỉ Nhà/Dãy trọ được cấp quyền) |
| Tạo/sửa/xoá Phòng | ✅ (tất cả) | ✅ (trong phạm vi được cấp) |
| Tạo hồ sơ Tenant (Tenant Pool) | ✅ | ✅ |
| Tạo/sửa Hợp đồng, gia hạn/sửa điều khoản | ✅ (tất cả) | ✅ (chỉ hợp đồng thuộc phòng trong phạm vi được cấp) |
| Kết thúc hợp đồng, đối soát cọc | ✅ | ✅ (trong phạm vi được cấp) |
| Tạo hoá đơn, xem trước, gửi qua SMS/Zalo | ✅ | ✅ (trong phạm vi được cấp) |
| Đánh dấu hoá đơn đã thu tiền | ✅ | ✅ (trong phạm vi được cấp) |
| Xem số liệu tổng/đã thu/chưa thu/quá hạn (trong Bill Management) | ✅ (toàn bộ) | ✅ (chỉ phạm vi được cấp) |
| Tạo/khoá tài khoản Manager, cấp/thu quyền theo Nhà/Dãy trọ | ✅ | ❌ |
| Sửa Hồ sơ Chủ nhà (Owner Profile) | ✅ | ❌ (Manager có hồ sơ tài khoản riêng, không sửa Owner Profile) |

---

## 5. Quy tắc Thông báo (Notification Rules)

| ID | Sự kiện | Kênh | Trạng thái |
|---|---|---|---|
| BR-NOTI-01 | Hoá đơn mới được tạo & gửi | Push (Landlord/Manager) + SMS/Zalo (Tenant) | Must |
| BR-NOTI-02 | Nhắc thanh toán (trước/đúng/sau hạn) | Push (Landlord/Manager) + SMS/Zalo (Tenant) | Must — xem BR-PAY-04 |
| BR-NOTI-03 | Landlord/Manager đánh dấu đã thu tiền | Push (nội bộ, cho các Manager khác cùng phạm vi nếu có) | Should |
| BR-NOTI-04 | Hợp đồng sắp hết hạn (nhắc gia hạn) | Push + có thể kèm SMS/Zalo | Could |
| ~~BR-NOTI cũ (yêu cầu mới, cập nhật trạng thái yêu cầu, lời mời Tenant vào app, yêu cầu liên hệ Search)~~ | | Removed | Gắn với Maintenance/Search — ngoài phạm vi Phase 1 |

---

## 6. Multi-tenancy & Cô lập dữ liệu (Data Isolation)

| ID | Quy tắc |
|---|---|
| BR-DATA-01 | Mỗi Landlord chỉ thấy dữ liệu (Nhà/Dãy trọ, Phòng, Tenant, Hợp đồng, Hoá đơn) thuộc tài khoản của mình. |
| BR-DATA-02 | Mỗi Manager chỉ thấy/thao tác dữ liệu thuộc **Nhà/Dãy trọ được Landlord cấp quyền** (`tb_manager_house_access`) — không mặc định thấy toàn bộ dữ liệu của Landlord tạo ra Manager đó. |
| BR-DATA-03 | Tenant **không có tài khoản đăng nhập** trong Phase 1 → không áp dụng RLS theo `auth.uid()` phía Tenant; dữ liệu Tenant chỉ được Landlord/Manager thuộc đúng phạm vi truy cập. |

---

## 7. Quyền riêng tư & Lưu trữ dữ liệu (Privacy & Data Retention)
- Thời gian lưu trữ dữ liệu sau khi hợp đồng kết thúc: 3 năm
- Chính sách xoá tài khoản/dữ liệu theo yêu cầu người dùng: có (phase 2)
- Có cần điều khoản sử dụng (Terms) & chính sách bảo mật (Privacy Policy) hiển thị khi onboarding: Có, bắt buộc

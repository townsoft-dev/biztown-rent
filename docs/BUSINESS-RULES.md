# Business Rules — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 3 **Last updated:** 2026-09-08
> **Thay đổi lớn so với Version 2:** Viết lại toàn bộ mục 1 (Billing) cho hợp đồng nhiều phòng + tự động hoá sâu hơn (chu kỳ tiền nhà cấu hình được, prorate, phí dịch vụ theo m², QR VietQR, tạo hàng loạt). Thêm mục 3 các quy tắc hợp đồng nhiều phòng. Thêm hẳn **mục 6 — Nghiệp vụ ghi chỉ số điện/nước** (thay đổi quan trọng nhất của V3). Viết lại toàn bộ **mục 4 — Vai trò & Phân quyền** (vai trò gắn theo từng nhà, không gắn tài khoản). Xem [DECISIONS.md](DECISIONS.md) 2026-09-08.
> **Cập nhật cùng ngày (sửa trực tiếp trong FigJam):** bỏ `unitPrice`/`totalAmount` khỏi 2 bảng chỉ số điện/nước; thêm rule **BR-METER-13** (cơ chế sửa chỉ số đã khoá qua `otherFees` hoá đơn kế tiếp) — xem mục 6; làm rõ `recurringFees` của `tb_house` chỉ là giá trị mặc định autofill cho `tb_room.recurringFees` lúc tạo phòng.

---

## 1. Quy tắc tính Hoá đơn (Billing Calculation)

| ID | Quy tắc | Trạng thái |
|---|---|---|
| BR-BILL-01 | Hoá đơn 1 kỳ = Tiền nhà (chỉ xuất hiện ở kỳ trùng chu kỳ thu tiền, xem BR-BILL-07) + tổng Tiền điện/nước theo từng phòng (`tb_invoice.utilityLines`) + Phí dịch vụ (`serviceFeeAmount`) + Phí định kỳ khác (`recurringFees`) + Phí phát sinh thêm (`otherFees`) | Thay hoàn toàn công thức 1 dòng điện + 1 dòng nước của Version 2 |
| BR-BILL-02 | Tiền điện mỗi PHÒNG = (Chỉ số mới − Chỉ số cũ, lấy từ `tb_electricity_reading`) × Đơn giá điện chính thức (`contract_version.electricityUnitPrice`); nếu `electricityBillingMethod = FLAT` → dùng thẳng `electricityFlatAmount` (khoán theo đầu người/phòng); nếu `= NOT_BILLED` → không có dòng điện trong hoá đơn | Đơn giá là snapshot theo phiên bản hợp đồng đang hiệu lực |
| BR-BILL-03 | Tiền nước tính tương tự BR-BILL-02, dùng `waterUnitPrice`/`waterFlatAmount`/`waterBillingMethod` | |
| BR-BILL-04 | Phí dịch vụ (quản lý phí) = `serviceFeeRatePerSqm × contractAreaSqm`, đã **chốt cứng vào hợp đồng** lúc tạo (`contract_version.serviceFeeAmount`) — thu theo **cùng nhịp điện/nước (hàng tháng)**, không phụ thuộc chu kỳ thu tiền nhà | Thay cho việc nhét vào `recurringFees` như Version 2 |
| BR-BILL-05 | Phí khác = tổng `recurringFees` (theo điều khoản hợp đồng) + `otherFees` (điều chỉnh/phát sinh thêm lúc tạo hoá đơn, tự nhập) — snapshot vào hoá đơn tại thời điểm tạo | |
| BR-BILL-06 | Chỉ số điện/nước mới phải ≥ chỉ số cũ (validate chống nhập sai) | Áp dụng ngay lúc ghi chỉ số (BR-READ-03), không phải lúc tạo hoá đơn như Version 2 |
| BR-BILL-07 | Kỳ hoá đơn: **điện/nước luôn tính theo tháng dương lịch**; **tiền nhà** tính theo chu kỳ cấu hình được trên hợp đồng (`rentCycleMonths`, neo theo `rentCycleAnchorYm` — VD 2 tháng/lần). Kỳ không rơi vào chu kỳ thu tiền nhà thì hoá đơn chỉ có điện/nước (+ phí dịch vụ + phí khác nếu có) | Khác biệt cốt lõi so với Version 2 (luôn hàng tháng cho mọi khoản) |
| BR-BILL-08 | Vào/ra giữa tháng: **tiền nhà** chia theo số ngày ở thực tế, áp dụng ở kỳ đầu (từ ngày ghi nhận `MOVE_IN`) và kỳ cuối (đến ngày ghi nhận `MOVE_OUT`). **Điện/nước không cần chia** — mốc chỉ số nhận/trả phòng đã phản ánh đúng lượng dùng thực tế của từng bên. **Phí dịch vụ (`serviceFeeAmount`) và phí định kỳ (`recurringFees`) KHÔNG chia theo ngày ở** — tính trọn 100% cho hợp đồng đang `Active` (đang có người ở) **tại thời điểm hệ thống tạo hoá đơn của kỳ đó**; hợp đồng vừa kết thúc trong kỳ (đã `Ended` trước thời điểm tạo hoá đơn) không bị tính khoản này ở hoá đơn cuối. Nếu phòng còn **trống** tại thời điểm tạo hoá đơn của kỳ đó (không có hợp đồng `Active` nào) → không phát sinh dòng phí này cho bất kỳ ai, chủ nhà tự chịu (không lên hoá đơn cho khách nào cả) | Mới, 09/09/2026 — thay thế cách hiểu "prorate mọi khoản theo ngày" ngầm định trước đó; xem [DECISIONS.md](DECISIONS.md) 2026-09-09 |
| BR-BILL-09 | Hạn thanh toán (`invoice.dueDate`) = ngày cố định trong tháng ghi trên hợp đồng (`contract_version.paymentDueDayOfMonth`); tháng không có ngày đó (VD ngày 31) thì lùi về ngày cuối cùng còn tồn tại trong tháng (28 hoặc 29 ở tháng 2) | Thay thế hoàn toàn quy tắc "N ngày sau khi gửi" của Version 2 — xem BR-PAY-01 |
| BR-BILL-10 | Mã QR thanh toán chuẩn **VietQR/NAPAS-247** được sinh tự động khi phát hành hoá đơn, từ `tb_house.bankBin` + số tài khoản + `totalAmount` — hiện trên hoá đơn và đính kèm tin nhắn Zalo/SMS | Mới — Version 2 chỉ in số tài khoản dạng text |
| BR-BILL-11 | **Tạo hoá đơn hàng loạt:** chọn 1 Nhà/Dãy trọ + 1 kỳ → hệ thống tạo hoá đơn cho **mọi hợp đồng `Active`** thuộc nhà đó trong kỳ. Hợp đồng có phòng **còn thiếu chỉ số của kỳ đó** thì **BỊ BỎ QUA hoàn toàn** (không tạo), màn hình liệt kê rõ phòng nào đang thiếu — hệ thống **không bao giờ tự ước lượng** chỉ số thay người dùng | Mới — Version 2 không có thao tác hàng loạt |
| BR-BILL-12 | Kỳ tương lai hiển thị dưới dạng chip **"Scheduled"** kèm bản xem trước dựng tạm trong Invoice List — **KHÔNG tạo hoá đơn thật** trước khi tới kỳ | Mới |
| BR-BILL-13 | Không làm tròn số tiền hoá đơn (chỉ bỏ số thập phân) | Kế thừa Version 2 |

---

## 2. Quy tắc Thanh toán & Nhắc nhở (Payment & Reminders)

> Vì Tenant không có app/tài khoản, giữ nguyên từ Version 2: **không có** bước Tenant tự đánh dấu "Đã thanh toán" trong app — trạng thái hoá đơn chỉ do Landlord/Manager (theo quyền trên từng nhà — xem mục 4) cập nhật thủ công dựa trên xác nhận thực tế ngoài app.

| ID | Quy tắc | Trạng thái |
|---|---|---|
| BR-PAY-01 | Hạn thanh toán = ngày cố định trong tháng ghi trên hợp đồng (`paymentDueDayOfMonth`) — xem BR-BILL-09 | **Thay thế** quy tắc "N ngày sau khi gửi hoá đơn" của Version 2 |
| BR-PAY-02 | Tenant chuyển khoản/tiền mặt **ngoài app** (không có bước xác nhận nào trong app từ phía Tenant) → Landlord/Manager tự đánh dấu hoá đơn "Đã thu tiền" (`Collected`) khi xác nhận đã nhận được tiền | Kế thừa Version 2 |
| BR-PAY-03 | Trạng thái hoá đơn (`invoice.status`): `Draft` (đang soạn, chưa gửi) → `Sent` (đã gửi cho Tenant qua SMS/Zalo, chưa thu tiền) → `Collected` (đã xác nhận thu tiền); nếu quá `dueDate` mà vẫn `Sent` → hiển thị thêm cờ/derive trạng thái `Overdue` (không lưu trong DB) | Kế thừa Version 2 |
| BR-PAY-04 | Lịch nhắc tự động: 3 ngày trước hạn, 1 ngày trước hạn, đúng hạn, 1 ngày sau hạn, 3 ngày sau hạn — gửi SMS/Zalo cho Tenant + Push cho người có quyền trên nhà đó khi hoá đơn còn `Sent` (chưa `Collected`) sau các mốc trên | Kế thừa Version 2 — xem [USER-FLOWS](USER-FLOWS.md) Flow C |
| BR-PAY-05 | Phí phạt trễ hạn (nếu có): công thức tính theo **điều khoản ghi trong phiên bản hợp đồng đang hiệu lực** (`contract_version.lateFeeTerms`, free text), không phải công thức cố định toàn hệ thống | Kế thừa Version 2 |
| BR-PAY-06 | Có thể **sửa lại trạng thái đã thu tiền** (VD: đánh dấu nhầm) — chuyển ngược từ `Collected` về `Sent` | Kế thừa Version 2 |

---

## 3. Quy tắc Hợp đồng, Đặt cọc & Nhiều phòng trên 1 Hợp đồng (Contract & Deposit)

> **Thay đổi lớn nhất mục này (2026-09-08):** Version 2 chỉ cho phép 1 hợp đồng ↔ 1 phòng. Version 3 cho phép **1 hợp đồng gồm nhiều phòng** (VD nhiều người thuê chung 1 tầng, 1 người đại diện đứng tên ký).

| ID | Quy tắc | Trạng thái |
|---|---|---|
| BR-CTR-01 | Tiền cọc tính theo **cả hợp đồng** (không theo từng phòng), mặc định = 1 tháng tiền nhà của cả hợp đồng hoặc Landlord/Manager tự nhập số cụ thể — lưu `contract_version.depositAmount` | Đổi từ "theo phòng" (V2) sang "theo hợp đồng" |
| BR-CTR-02 | Khi trả phòng: Tiền cọc được hoàn lại trừ đi các khoản nợ chưa thanh toán (hoá đơn còn `Sent`/`Overdue`) và chi phí hư hỏng (nếu có) — ghi vào các field settlement trên `tb_contract` (`unpaidInvoicesTotal`, `damageDeduction`, `refundAmount`) | Kế thừa Version 2 (đã gộp bảng `contract_settlement` vào `tb_contract` — xem [DATABASE.md](DATABASE.md)) |
| BR-CTR-03 | Chấm dứt hợp đồng trước hạn có thể phạt cọc — thương lượng với chủ trọ, ghi vào `damageDeduction` | Kế thừa Version 2 |
| BR-CTR-04 | 1 phòng chỉ có 1 hợp đồng `Active` tại 1 thời điểm (enforce bằng ràng buộc UNIQUE trên `tb_contract_room` — xem [DATABASE.md](DATABASE.md)); **1 hợp đồng có thể gồm NHIỀU phòng**, 1 hợp đồng chỉ có 1 Tenant đại diện (`tenantId`) | Nới lỏng so với Version 2 — ở ghép nhiều Tenant/hợp đồng vẫn ngoài phạm vi Phase 1 |
| BR-CTR-05 | Mọi phòng trong **cùng 1 hợp đồng** phải thuộc **cùng 1 Nhà/Dãy trọ** — vì hoá đơn in tên nhà và tài khoản nhận tiền theo nhà | Mới |
| BR-CTR-06 | Hoá đơn tách điện/nước theo **từng phòng** (mỗi phòng × mỗi loại tiện ích = 1 dòng trong `utilityLines`), nhưng **tiền nhà, phí dịch vụ, phí định kỳ chỉ 1 dòng cho cả hợp đồng** | Mới — hệ quả trực tiếp của BR-CTR-04 |
| BR-CTR-07 | Đổi danh sách phòng của 1 hợp đồng (thêm/bớt phòng) → phải tạo **phiên bản hợp đồng mới** (`changeReason=Amendment`); phòng bị loại ra khỏi hợp đồng cần ghi chỉ số **trả phòng (MOVE_OUT)** riêng cho đúng phòng đó trước khi loại | Mới |
| BR-CTR-08 | Gia hạn hoặc sửa điều khoản hợp đồng tạo bản ghi `contract_version` mới, không ghi đè bản cũ | Kế thừa Version 2 — xem mục 3ter |
| BR-CTR-09 | Tenant có thể được đăng ký **độc lập** với hợp đồng, tồn tại ở "Tenant Pool" chưa gắn phòng, cho tới khi được chọn khi tạo hợp đồng | Kế thừa Version 2 |
| BR-CTR-10 | Chỉ số điện/nước **bắt buộc** phải có tại 2 mốc: **nhận phòng** (`MOVE_IN`, chặn nút "Lưu hợp đồng" nếu thiếu) và **trả phòng** (`MOVE_OUT`, chặn việc tính thanh lý cọc nếu thiếu). Không áp dụng khi phòng/hợp đồng có `electricityBillingMethod`/`waterBillingMethod = NOT_BILLED` | **Thay thế hoàn toàn** BR-CTR-07 cũ của Version 2 ("chỉ số nhập trực tiếp lúc tạo hoá đơn, không có màn ghi số riêng") — xem mục 6 |
| BR-CTR-11 | Hồ sơ Tenant lưu ảnh CCCD/CMND (2 mặt) | Kế thừa Version 2 |
| BR-CTR-12 | Thông tin môi giới/cò nhà (`realEstate`: tên, liên hệ, phí) là optional, lưu theo từng phiên bản hợp đồng | Kế thừa Version 2 |
| BR-CTR-13 | Tenant được chọn làm đại diện hợp đồng **phải cùng `houseId`** với các phòng trong hợp đồng đang tạo — hệ quả trực tiếp của `houseId` bắt buộc trên `tb_tenant` (BR-DATA-05). Màn T-04 hỗ trợ **2 thứ tự chọn**: (a) chọn Nhà/phòng trước (mặc định) → Tenant Pool tự lọc chỉ hiện Tenant thuộc đúng nhà đó; Tenant Pool rỗng thì tạo nhanh Tenant mới (Nhà tự điền sẵn, ẩn field); (b) chọn Tenant trước (từ toàn bộ Tenant Pool đang có quyền) → danh sách Nhà/phòng tự lọc chỉ còn đúng Nhà của Tenant đã chọn. Dù chọn theo chiều nào, hệ thống validate lại ràng buộc cùng-nhà ngay trước khi cho lưu | Mới, 09/09/2026 (đợt 3) — xem `PHASE1GAPANALYSISV3.md` Phát hiện B |

---

## 3ter. Lịch sử phiên bản Hợp đồng (Contract Versioning)

| ID | Quy tắc |
|---|---|
| BR-VER-01 | Khi tạo hợp đồng mới, hệ thống tạo `tb_contract` (`tenantId`, `status=Active`) + 1 dòng `tb_contract_room` cho **mỗi phòng** được chọn + `tb_contract_version` #1 (`changeReason=New`) chứa toàn bộ điều khoản (ngày, tiền thuê, cọc, đơn giá/phương thức tính điện nước, chu kỳ thu tiền nhà, ngày đến hạn thanh toán, phí dịch vụ theo m², phí định kỳ, phạt trễ hạn, môi giới). |
| BR-VER-02 | Gia hạn hợp đồng → tạo `contract_version` mới với `changeReason=Renewal`, `versionNo` tăng dần, `startDate` mới nối tiếp `endDate` bản trước (hoặc theo Landlord/Manager chỉnh). Gia hạn với cùng Tenant/phòng thì **không đo lại chỉ số** — chuỗi `previousReadingId` tiếp tục liền mạch. |
| BR-VER-03 | Sửa điều khoản giữa kỳ (VD đổi đơn giá điện, đổi danh sách phòng) → tạo `contract_version` mới với `changeReason=Amendment`. |
| BR-VER-04 | `contract.currentVersionId` luôn trỏ tới phiên bản mới nhất — dùng làm điều khoản áp dụng cho hoá đơn kế tiếp. |
| BR-VER-05 | Hoá đơn (`invoice`) lưu `contractVersionId` tại thời điểm tạo (snapshot) — sửa/gia hạn hợp đồng sau đó **không** làm thay đổi hoá đơn đã phát hành trước đó. |
| BR-VER-06 | `contractAreaSqm` và `serviceFeeAmount` chỉ thay đổi khi tạo phiên bản `Amendment` mới có thay đổi danh sách phòng hoặc đơn giá — **không tự động tính lại** khi diện tích phòng gốc (`tb_room.areaSqm`) bị sửa sau đó. |

---

## 4. Vai trò & Phân quyền (Roles & Permissions)

> **Viết lại toàn bộ mục này (2026-09-08).** Version 2 gắn vai trò cứng vào loại tài khoản (`landlord_account` luôn là chủ, `manager_account` luôn là quản lý, do Landlord tạo). Version 3 bỏ hẳn cách này: **vai trò gắn theo từng Nhà/Dãy trọ**, không gắn vào tài khoản — cùng 1 tài khoản có thể vừa là chủ nhà A vừa là quản lý nhà B của một chủ trọ khác.

| ID | Quy tắc |
|---|---|
| BR-ROLE-01 | Vai trò (`owner` \| `manager`) lưu ở `tb_user_house_access.role`, theo **từng Nhà/Dãy trọ**. `tb_user` **không có cột `role`** — chỉ là danh tính (SĐT, họ tên, CCCD, trạng thái). |
| BR-ROLE-02 | Đăng ký: **một luồng duy nhất cho mọi người** — SĐT + OTP + tạo mật khẩu. **Bỏ hoàn toàn** luồng "chủ trọ nhập SĐT + mật khẩu ban đầu để tạo tài khoản Manager" của Version 2. |
| BR-ROLE-03 | Tạo Nhà/Dãy trọ mới → hệ thống tự sinh 1 dòng `tb_user_house_access` với `role=owner` cho chính người tạo. |
| BR-ROLE-04 | Mời quản lý: chủ nhà (người có `role=owner` trên nhà đó) nhập **số điện thoại** người muốn mời và chọn 1 hoặc nhiều nhà đang có quyền `owner` → hệ thống chỉ **ghi 1 dòng quyền/1 nhà** (`role=manager`, `grantedByUserId`=người mời). Ghi được ngay cả khi số điện thoại đó **chưa có tài khoản** (khoá theo SĐT, không phải `userId`) — dòng quyền tự có hiệu lực khi người đó đăng ký/đăng nhập lần đầu. **Không** tạo tài khoản hộ, **không** đặt mật khẩu hộ, **không** gọi Supabase Admin API. |
| BR-ROLE-05 | Thu quyền: chủ nhà chỉ được **xoá** những dòng quyền do chính mình đã cấp. **Không** dùng cờ vô hiệu hoá ở cấp tài khoản (`tb_user.status`) để chặn quyền do người khác cấp — tài khoản chỉ vô hiệu hoá khi không còn dòng quyền nào từ bất kỳ ai, và đó là việc của quản trị hệ thống, không phải thao tác của 1 chủ nhà. |
| BR-ROLE-06 | Riêng tư khi mời: nếu số điện thoại được mời **đã có tài khoản**, màn hình xác nhận chỉ hiển thị tên ở dạng che một phần (VD "Ng\*\*\* T\*\*\* H\*\*\* — đã có tài khoản, mời làm quản lý?") — không hiện đầy đủ họ tên, CCCD hay thông tin khác do chủ trọ khác đã nhập. |
| BR-ROLE-07 | Một tài khoản có thể đồng thời là `owner` ở 1 hoặc nhiều nhà và `manager` ở 1 hoặc nhiều nhà khác (kể cả nhà của chủ trọ khác) — hoàn toàn hợp lệ, không cần xử lý ngoại lệ; mỗi dòng `tb_user_house_access` độc lập với nhau. |
| **BR-ROLE-09** | **(Mới, 09/09)** Số điện thoại (`tb_user.phone`) là khoá chính và định danh đăng nhập duy nhất — **không cho đổi** sau khi đã tạo tài khoản (đổi hướng so với phương án "đổi SĐT kèm OTP" cân nhắc trước đó). Người dùng vẫn đổi được mật khẩu (P-04) và mọi thông tin cá nhân khác (họ tên, giới tính, ngày sinh, email, CCCD/CMND, avatar — P-02) bình thường. Loại bỏ hẳn nhu cầu cascade cập nhật các field "FK logic theo SĐT" (`tb_user_house_access.phone`, `recordedByUserId`, `grantedByUserId`) — không còn thao tác đổi SĐT nào để cascade theo. Đăng nhập vẫn có 2 đường độc lập (SĐT+mật khẩu hoặc SĐT+OTP — xem S-01), nên rủi ro chỉ thật sự xảy ra khi mất **đồng thời cả SIM lẫn mật khẩu**. **Chốt 09/09/2026 (đợt 3):** trường hợp này coi là **sơ suất của người dùng**, Phase 1 **không xử lý** — không có quy trình hỗ trợ thủ công/runbook nào trong phạm vi Phase 1, chấp nhận rủi ro khoá tài khoản vĩnh viễn cho ca hy hữu này. **Phase 2** dự kiến bổ sung kênh xác thực thứ 2 cho `FR-AUTH-05` (quên mật khẩu): gửi OTP tới **email đã đăng ký** thay vì chỉ SĐT — khi triển khai, `tb_user.email` chuyển từ optional sang **bắt buộc** lúc đăng ký/cập nhật hồ sơ. |
| BR-ROLE-08 | Bảng hành động theo `role` trên **từng nhà** (không phải theo loại tài khoản): |

| Hành động | `role = owner` (của nhà đang thao tác) | `role = manager` (của nhà đang thao tác) |
|---|---|---|
| Sửa thông tin Nhà/Dãy trọ, chủ sở hữu hiển thị, tài khoản nhận tiền, đơn giá mặc định (`serviceFeeRatePerSqm`) | ✅ | ❌ (chỉ xem) |
| Xoá Nhà/Dãy trọ | ✅ | ❌ |
| Tạo/sửa/xoá Phòng | ✅ | ✅ |
| Ghi chỉ số điện/nước (định kỳ, nhận phòng, trả phòng) | ✅ | ✅ |
| Tạo hồ sơ Tenant (Tenant Pool dùng chung theo nhà) | ✅ | ✅ |
| Tạo/sửa Hợp đồng, gia hạn/sửa điều khoản, kết thúc hợp đồng | ✅ | ✅ |
| Tạo hoá đơn (đơn lẻ hoặc hàng loạt), đánh dấu đã thu tiền | ✅ | ✅ |
| Mời/thu quyền quản lý cho nhà này | ✅ | ❌ |

---

## 5. Quy tắc Thông báo (Notification Rules)

| ID | Sự kiện | Kênh | Trạng thái |
|---|---|---|---|
| BR-NOTI-01 | Hoá đơn mới được tạo & gửi (đơn lẻ hoặc hàng loạt) | Push (người có quyền trên nhà đó) + SMS/Zalo (Tenant, kèm mã QR) | Must |
| BR-NOTI-02 | Nhắc thanh toán (trước/đúng/sau hạn) | Push + SMS/Zalo | Must — xem BR-PAY-04 |
| BR-NOTI-03 | Đánh dấu đã thu tiền | Push nội bộ (cho người khác cùng quyền trên nhà đó, nếu có) | Should |
| BR-NOTI-04 | Hợp đồng sắp hết hạn (nhắc gia hạn) | Push + có thể kèm SMS/Zalo | Could |
| BR-NOTI-05 | **Đến hạn ghi chỉ số điện/nước định kỳ hàng tháng** của 1 Nhà/Dãy trọ | Push (người có quyền trên nhà đó) | Must — điều hướng tới màn **Ghi chỉ số** (Home tab), không phải màn Tạo hoá đơn như cách hiểu tạm thời ở Version 2 (xem mục 6) |
| BR-NOTI-06 | Được mời làm quản lý 1 Nhà/Dãy trọ | Push (nếu đã có tài khoản); nếu chưa có tài khoản thì thông báo hiện khi đăng nhập lần đầu sau khi đăng ký | Should |
| BR-NOTI-07 | **Ngôn ngữ nội dung** SMS/Zalo gửi cho Tenant (hoá đơn, nhắc thanh toán) | Cố định cố định **tiếng Anh** và **tiếng Việt** ở Phase 1, tiếng việt bên trên tiếng anh bên dưới ở Phase 1 — **độc lập hoàn toàn** với ngôn ngữ hiển thị (English/Tiếng Việt/한국어) mà chủ nhà/quản lý đang chọn ở P-01 (`FR-MGR-05`); Tenant không có tài khoản/app nên không có lựa chọn ngôn ngữ riêng | Mới, 09/09/2026 (đợt 3) |

---

## 6. Nghiệp vụ ghi chỉ số điện/nước (Meter Reading) — Mới, thay đổi quan trọng nhất Version 3

> Chỉ đạo gốc (Mr. Han): *"검침은 1개 호실이 1개의 계량기를 갖는다는 전제하에 별도의 계량기 등록, 관리는 하지 않는다"* — 1 phòng = 1 công tơ, không đăng ký/quản lý công tơ riêng.
>
> **Cập nhật 09/08 (sửa trực tiếp trong FigJam):** bỏ `unitPrice`/`totalAmount` khỏi 2 bảng chỉ số (`tb_electricity_reading`/`tb_water_reading`, còn 17 field) — đơn giá dùng tính tiền luôn lấy từ `contract_version.electricityUnitPrice`/`waterUnitPrice` **tại thời điểm lên hoá đơn** (BR-BILL-02/03), không snapshot riêng trên bản ghi chỉ số nữa, tránh lệch nếu hợp đồng đổi đơn giá giữa lúc ghi số và lúc lên hoá đơn. Xem [DATABASE.md](DATABASE.md) mục `tb_electricity_reading`/`tb_water_reading`.

| ID | Quy tắc |
|---|---|
| BR-READ-01 | Chỉ số điện/nước gắn **trực tiếp vào PHÒNG** — không có bảng/thực thể công tơ riêng, không lưu số serial công tơ. |
| BR-READ-02 | Có **3 loại chỉ số**, nằm trong **CÙNG một bảng lịch sử** theo từng tiện ích (`tb_electricity_reading`/`tb_water_reading`) — mỗi bản ghi tham chiếu bản ghi ngay trước đó của cùng phòng (`previousReadingId`) để biết đúng "chỉ số cũ"; **không được tách rời 3 loại thành các luồng độc lập** vì sẽ làm đứt chuỗi: <br>• **Định kỳ (`PERIODIC`)** — ghi 1 lần/tháng theo 1 ngày cố định của cả Nhà/Dãy trọ, cho **MỌI phòng kể cả phòng trống**. Không gắn hợp đồng. <br>• **Lúc nhận phòng (`MOVE_IN`)** — ghi khi ký hợp đồng/khách nhận phòng. **BẮT BUỘC** — chặn nút "Lưu hợp đồng" nếu thiếu. <br>• **Lúc trả phòng (`MOVE_OUT`)** — ghi khi khách trả phòng. **BẮT BUỘC** — chặn việc tính thanh lý cọc nếu thiếu. |
| BR-READ-03 | Chỉ số mới phải ≥ chỉ số cũ (validate ngay lúc ghi — xem BR-BILL-06). |
| BR-READ-04 | `isLocked` là **derived, không phải cột lưu trong DB**: = TRUE nếu có **bất kỳ** hoá đơn non-Draft nào tham chiếu bản ghi chỉ số này ở vai trò **from HOẶC to** — rộng hơn chỉ mỗi `invoiceId` khác null, vì sửa 1 chỉ số cũng làm sai lệch hoá đơn kế tiếp (nơi chỉ số đó là "from"). Khi `isLocked=true` thì chỉ số đó **cấm sửa trực tiếp** — muốn điều chỉnh phải theo BR-METER-13. |
| BR-READ-05 | Không áp dụng nghiệp vụ ghi chỉ số cho phòng/hợp đồng có `electricityBillingMethod`/`waterBillingMethod = NOT_BILLED` (VD: căn hộ cho thuê nguyên căn, khách tự trả điện/nước trực tiếp cho toà nhà — không bắt buộc chỉ số nhận/trả phòng cho trường hợp này). **Phòng cấu hình `FLAT` (khoán) KHÔNG được miễn** — vẫn ghi chỉ số đầy đủ (định kỳ + nhận/trả phòng) như phòng `BY_READING`. Đây là chủ đích (09/09/2026), không phải thiếu sót: dữ liệu chỉ số của phòng `FLAT` không dùng để tính tiền (`BR-BILL-02` dùng thẳng `electricityFlatAmount`/`waterFlatAmount`), nhưng dùng làm căn cứ theo dõi mức tiêu thụ thực tế — hữu ích nếu sau này cân nhắc chuyển phòng đó sang tính theo chỉ số thật. |
| BR-READ-06 | Vì sao đặt `MOVE_IN`/`MOVE_OUT` là bước bắt buộc trong flow Hợp đồng, không đặt thành 3 nút tự do trong 1 menu ghi số riêng: nếu để tự do, hiện trường chắc chắn có lúc bỏ sót — và bỏ sót thì **mất dữ liệu vĩnh viễn, không sửa lại được** (không có "chỉ số cũ" nào khác để tra cứu lại). Đặt thành bước chặn nút lưu/kết thúc hợp đồng thì dữ liệu không thể thiếu. |
| BR-READ-07 | Nếu thiếu chỉ số `PERIODIC`/`MOVE_OUT` của kỳ cần lên hoá đơn hàng loạt (BR-BILL-11), hệ thống **bỏ qua hợp đồng đó** và liệt kê rõ phòng còn thiếu — không tự suy luận hay ước lượng chỉ số thay người dùng. |
| **BR-METER-13** | **(Mới, 09/08 — cơ chế sửa chỉ số đã khoá)** Chỉ số đã `isLocked=true` (xem BR-READ-04) không được sửa trực tiếp trên bản ghi chỉ số. Muốn điều chỉnh (VD phát hiện ghi sai sau khi đã lên hoá đơn), người dùng thêm 1 dòng điều chỉnh vào `tb_invoice.otherFees` của hoá đơn **kế tiếp** (hoá đơn nơi chỉ số đó đóng vai trò "from") — không tạo lại/ghi đè chỉ số gốc, không phát hành lại hoá đơn cũ. `previousReading` trên bảng chỉ số chỉ là **bản snapshot hiển thị**, KHÔNG phải nguồn sự thật — nguồn sự thật của chuỗi chỉ số luôn là `previousReadingId`; sửa `previousReading` một mình không có tác dụng gì lên số liệu tính hoá đơn. |
| **BR-METER-14** | **(Mới, 09/09 — sửa chỉ số MOVE_OUT sau khi đã thanh lý, `BR-METER-13` không áp dụng được)** Chỉ số **MOVE_OUT** luôn đóng vai trò "đóng kỳ (to)" của hoá đơn cuối cùng khách cũ, **không bao giờ** là "from" của bất kỳ hoá đơn nào (bản ghi kế tiếp trong chuỗi `previousReadingId` của phòng — `MOVE_IN` khách mới, hoặc `PERIODIC` nếu phòng bỏ trống — mới giữ vai trò "from") → không có "hoá đơn kế tiếp" nào để bám `otherFees` vào theo `BR-METER-13`. Nếu phát hiện chỉ số MOVE_OUT ghi sai **sau khi** hợp đồng đã `Ended` (`settlementConfirmedAt` đã chốt): **không** sửa/ghi đè chỉ số gốc, **không** phát hành lại hoá đơn cuối — điều chỉnh phần chênh lệch (quy đổi từ sai lệch chỉ số sang tiền, theo đơn giá đang hiệu lực lúc đó) vào `tb_contract.damageDeduction`, kèm `settlementNote` ghi rõ lý do (VD: "điều chỉnh do chỉ số trả phòng phòng X ghi sai, chênh lệch Y kWh"). |

> **Chú thích `invoiceId` trên bản ghi chỉ số:** `invoiceId` = hoá đơn nơi chỉ số này là chỉ số **ĐÓNG kỳ (to)** — quan hệ 1-tại-1-thời-điểm nên không mơ hồ. Chính chỉ số đó cũng là chỉ số **MỞ kỳ (from)** của hoá đơn kế tiếp, nhưng liên kết "from" này lưu ở `tb_invoice`, không lưu ở bảng chỉ số — đây là lý do `isLocked` (BR-READ-04) phải xét cả 2 chiều thay vì chỉ nhìn `invoiceId`.

---

## 7. Multi-tenancy & Cô lập dữ liệu (Data Isolation)

| ID | Quy tắc |
|---|---|
| BR-DATA-01 | Mọi bảng nghiệp vụ (`tb_house`, `tb_room`, `tb_tenant`, `tb_contract`, `tb_contract_room`, `tb_contract_version`, `tb_invoice`, `tb_electricity_reading`, `tb_water_reading`) áp RLS theo **một câu hỏi duy nhất**: tài khoản đang đăng nhập có dòng `tb_user_house_access` tới `houseId` liên quan không, và với `role` gì. |
| BR-DATA-02 | Vai trò **không được cache vào session** — vì 1 tài khoản có thể có `role` khác nhau ở từng nhà. Mọi màn hình phải biết "đang thao tác trên nhà nào" trước khi quyết định ẩn/hiện hành động (xem BR-ROLE-08). |
| BR-DATA-03 | Tenant **không có tài khoản đăng nhập** → không áp dụng RLS theo `auth.uid()` phía Tenant. |
| BR-DATA-04 | Hai chủ nhà độc lập hoàn toàn dù cùng mời chung 1 số điện thoại làm quản lý (VD A và C cùng mời B) — A không thấy nhà của C, không sửa/xoá được dòng quyền do C cấp, và ngược lại. |
| **BR-DATA-05** | **(Mới, 09/09)** `tb_tenant` mang `houseId` **trực tiếp** (không suy ra qua hợp đồng) — RLS áp thẳng theo cột này, kể cả với Tenant **chưa gắn phòng/hợp đồng nào** (đúng nghĩa "Tenant Pool"). Đã cân nhắc phương án dùng chung Tenant Pool theo **chủ sở hữu thật** (gộp nhiều nhà cùng 1 chủ) thay vì theo từng nhà — chốt **không làm** vì cần thêm định danh chủ sở hữu thật mà `tb_house` hiện chưa có (chỉ có `ownerFullName` dạng text tự do, không link `tb_user`); giữ nguyên theo `houseId` cho đơn giản, chấp nhận việc phải tạo lại hồ sơ Tenant riêng cho từng nhà dù cùng 1 chủ (xem [DECISIONS.md](DECISIONS.md) 2026-09-09). |

---

## 8. Quyền riêng tư & Lưu trữ dữ liệu (Privacy & Data Retention)
- Thời gian lưu trữ dữ liệu sau khi hợp đồng kết thúc: 3 năm
- Chính sách xoá tài khoản/dữ liệu theo yêu cầu người dùng: có (phase 2)
- Có cần điều khoản sử dụng (Terms) & chính sách bảo mật (Privacy Policy) hiển thị khi onboarding: Có, bắt buộc
- Khi mời quản lý bằng số điện thoại đã có tài khoản: chỉ hiển thị tên che một phần để xác nhận, không lộ hồ sơ đầy đủ do chủ trọ khác nhập — xem BR-ROLE-06

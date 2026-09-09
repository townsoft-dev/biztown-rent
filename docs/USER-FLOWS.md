# User Flows — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 3 **Last updated:** 2026-09-08
> Diagram dùng cú pháp **Mermaid** — hiển thị trực tiếp trên GitHub.
> **Thay đổi lớn:** Cấu trúc app đổi từ **5 menu → 4 tab** (Home, Tenant & Contract, Bills, Profile — xem [SCREEN-SPEC.md](SCREEN-SPEC.md) mục 1). Gộp luồng Đăng ký/Đăng nhập của Landlord và Manager thành **1 luồng duy nhất**; bỏ hẳn luồng "Landlord tạo tài khoản Manager", thay bằng **Mời quản lý bằng số điện thoại** (chỉ ghi quyền, không tạo tài khoản). Thêm flow **Ghi chỉ số điện/nước** (3 loại). Cập nhật flow Hợp đồng cho **nhiều phòng/hợp đồng** + chặn bằng chỉ số nhận phòng. Cập nhật flow Hoá đơn cho **tạo hàng loạt + mã QR**. Xem [DECISIONS.md](DECISIONS.md) 2026-09-08.

---

## 0. Danh sách flow trong file này

### 4 Core Flows (theo [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.1 — mỗi flow tương ứng 1 tab)

1. Home — Quản lý Nhà/Dãy trọ, Phòng & Ghi chỉ số điện/nước
2. Tenant & Contract — Quản lý Người thuê (Tenant Pool) + Hợp đồng (nhiều phòng, Version History)
3. Bills (core) — Tạo hàng loạt & gửi hoá đơn tự động (kèm mã QR), theo dõi thu tiền
4. Profile — Hồ sơ cá nhân, quản lý quyền truy cập theo Nhà/Dãy trọ, đăng nhập/đăng xuất

### Flow hỗ trợ (Supporting)

- **A1.** Đăng ký/Đăng nhập — dùng chung cho mọi người (không còn phân biệt vai trò lúc đăng ký)
- **A2.** Mời quản lý bằng số điện thoại (ghi quyền theo từng Nhà/Dãy trọ, không tạo tài khoản)
- **C.** Nhắc thanh toán quá hạn (hỗ trợ Flow #3)
- **Z.** Đăng xuất (Logout)

> ~~Flow #3 House/Room Search, Flow B (Tenant xem & thanh toán trong app), Flow #8 Service Request Management~~ → **Ngoài phạm vi Phase 1** — xem [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.2.

---

## A1. Đăng ký/Đăng nhập — dùng chung cho mọi người

```mermaid
flowchart TD
    A[Mở app lần đầu] --> B{Đã có tài khoản?}
    B -- Chưa --> C[Đăng ký: SĐT]
    C --> D[Xác thực OTP]
    D --> D2[Tạo mật khẩu]
    D2 --> F[Hoàn tất -> Home]
    F --> G{Có dòng quyền tb_user_house_access nào chưa?}
    G -- Không --> H[Home trống, CTA 'Thêm Nhà/Dãy trọ đầu tiên' hoặc chờ được mời]
    G -- Có (được mời trước khi có tài khoản) --> I[Home hiện sẵn các nhà đã được cấp quyền]
    B -- Rồi --> J[Đăng nhập bằng SĐT/OTP hoặc Mật khẩu]
    J --> K[Home — liệt kê mọi Nhà/Dãy trọ đang có quyền, nhóm theo chủ sở hữu]
```
Không còn bước chọn vai trò hay màn đăng ký riêng cho quản lý — **mọi người dùng cùng 1 luồng đăng ký/đăng nhập**. Vai trò (owner/manager) chỉ xuất hiện khi vào từng Nhà/Dãy trọ cụ thể (xem [BUSINESS-RULES](BUSINESS-RULES.md) BR-ROLE-01).

---

## A2. Mời quản lý bằng số điện thoại (Profile)

```mermaid
flowchart TD
    A[Profile] --> B[Người quản lý nhà - của 1 Nhà/Dãy trọ đang có role=owner]
    B --> C[Bấm 'Mời quản lý']
    C --> D[Nhập số điện thoại]
    D --> E{Số đã có tài khoản?}
    E -- Có --> F[Hiện tên che một phần để xác nhận đúng người]
    E -- Chưa --> G[Vẫn cho tiếp tục - dòng quyền sẽ tự có hiệu lực khi người đó đăng ký]
    F --> H[Chọn 1 hoặc nhiều Nhà/Dãy trọ đang có quyền owner để cấp]
    G --> H
    H --> I[Lưu -> ghi dòng tb_user_house_access role=manager cho từng nhà, KHÔNG tạo tài khoản]
    B --> J{Thu hồi quyền đã cấp?}
    J -- Có --> K[Xoá dòng quyền do CHÍNH MÌNH đã cấp - không đụng dòng do người khác cấp]
```
Không có Edge Function tạo tài khoản, không có Supabase Admin API — khác biệt lớn nhất so với Version 2 ("Landlord tạo tài khoản Manager"). Một số điện thoại có thể được nhiều chủ nhà khác nhau mời làm quản lý cho nhà của họ, độc lập hoàn toàn với nhau (xem [BUSINESS-RULES](BUSINESS-RULES.md) BR-DATA-04).

---

## 1. Home — Nhà/Dãy trọ, Phòng & Ghi chỉ số điện/nước — CORE FLOW

```mermaid
flowchart TD
    A[Home] --> B[Danh sách Nhà/Dãy trọ - nhóm theo chủ sở hữu]
    B --> C{Hành động}
    C -- Thêm Nhà/Dãy trọ mới --> D[Đăng ký nhà: tên, địa chỉ, mô tả, ảnh, loại nhà, chủ sở hữu hiển thị, tài khoản ngân hàng, đơn giá phí dịch vụ/m2 mặc định]
    D --> E[Lưu -> tb_house + tự sinh dòng quyền role=owner cho người tạo]
    E --> B
    C -- Chọn Nhà/Dãy trọ có sẵn --> F[Room List trong nhà đó]
    F --> G{Hành động}
    G -- Thêm phòng mới --> H[Room Detail Create/Edit: số phòng, DIỆN TÍCH m2 - bắt buộc, giá tham khảo, tiện ích, phí định kỳ, ảnh]
    H --> I[Lưu -> tb_room, trạng thái = Empty]
    I --> F
    G -- Chọn phòng có sẵn --> J[Room Detail - View]
    G -- Ghi chỉ số định kỳ cho cả nhà --> K[Chọn kỳ - theo ngày cấu hình sẵn của nhà]
    K --> L[Nhập chỉ số MỚI cho từng phòng - kể cả phòng trống]
    L --> M{Chỉ số mới >= chỉ số cũ?}
    M -- Không --> L
    M -- Có --> N[Lưu -> tb_electricity_reading/tb_water_reading readingType=PERIODIC, previousReadingId nối chuỗi theo phòng]
    J --> O{Sửa, Xoá hay Xem lịch sử chỉ số?}
    O -- Sửa --> H
    O -- Xem lịch sử chỉ số --> P[Detail view - cùng màn H-06: Timeline 3 loại chỉ số của phòng - PERIODIC/MOVE_IN/MOVE_OUT theo previousReadingId]
    P --> P1{Tap 1 dòng: isLocked?}
    P1 -- false, chưa lên hoá đơn --> P2[Sửa ngay tại chỗ - chỉ số mới, ảnh, ghi chú lý do]
    P2 --> P3[Lưu -> cập nhật usageAmount] --> P
    P1 -- true, đã lên hoá đơn --> P4["Chỉ xem, không cho sửa - điều chỉnh qua otherFees của hoá đơn kế tiếp (BR-METER-13)"]
    O -- Xoá --> Q{Phòng có hợp đồng Active?}
    Q -- Có --> R[Chặn xoá, hiển thị cảnh báo]
    Q -- Không --> S[Xoá phòng thành công]
```
1 phòng = 1 công tơ, không đăng ký/quản lý công tơ riêng. Ghi chỉ số định kỳ áp dụng cho MỌI phòng của nhà kể cả phòng trống, vào 1 ngày cố định/tháng — hệ thống nhắc trước 1 ngày (BR-NOTI-05). Không áp dụng cho phòng/hợp đồng cấu hình `NOT_BILLED` (VD căn hộ nguyên căn). Chỉ số lúc nhận/trả phòng (`MOVE_IN`/`MOVE_OUT`) được ghi trực tiếp trong Flow #2 (Tenant & Contract), không phải ở đây — xem BR-READ-06 về lý do đặt 2 loại này thành bước chặn trong flow hợp đồng.

> **Cập nhật 09/08 (sửa trực tiếp trong FigJam):** entry (K/L/N), detail view (P) và edit tại chỗ (P2) nay dồn về **1 màn duy nhất — H-06 Record Monthly Reading (PERIODIC)** trong [SCREEN-SPEC.md](SCREEN-SPEC.md), thay vì 3 màn tách rời Reading Entry/History/Correction ở bản trước. Sửa chỉ số chỉ khả dụng ngay trong detail view khi `isLocked=false`; khi đã khoá thì không có đường sửa trực tiếp nào — mọi điều chỉnh đi qua dòng `otherFees` của hoá đơn kế tiếp (BR-METER-13).

---

## 2. Tenant & Contract — CORE FLOW

```mermaid
flowchart TD
    A[Tab Tenant & Contract] --> B{Segmented control}
    B -- Tenant --> C[Tenant Pool List]
    C --> D[Bấm 'Thêm người thuê']
    D --> E[Tenant Profile: chọn Nhà Dãy trọ bắt buộc, họ tên, SĐT, giới tính, ngày sinh, email, CCCD CMND + ảnh 2 mặt, ghi chú]
    E --> F[Lưu -> tb_tenant kèm houseId, CHƯA gắn phòng/hợp đồng]
    F --> C
    B -- Contract --> G[Contract List]
    G --> H[Bấm 'Tạo hợp đồng']
    H --> H2{Chọn theo chiều nào - mới 09/09/2026, xem BR-CTR-13}
    H2 -- Nhà/phòng trước, mặc định --> I[Chọn 1 hoặc NHIỀU phòng đang Empty - PHẢI cùng 1 Nhà/Dãy trọ]
    H2 -- Tenant trước --> L2[Chọn Tenant từ TOÀN BỘ Tenant Pool đang có quyền truy cập]
    L2 --> I2[Danh sách Nhà/phòng tự lọc chỉ còn đúng Nhà của Tenant đã chọn]
    I2 --> I
    I --> J{Đã có đủ chỉ số MOVE_IN cho từng phòng chưa?}
    J -- Chưa --> K[Bắt buộc ghi chỉ số nhận phòng cho từng phòng - trừ phòng NOT_BILLED]
    K --> J
    J -- Đủ --> L{Đã chọn Tenant ở bước trước chưa?}
    L -- Chưa, chọn ở đây --> M[Chọn Tenant - Tenant Pool tự lọc chỉ hiện Tenant đúng Nhà đã chọn]
    L -- Pool rỗng/thêm mới --> N[Nhập nhanh hồ sơ Tenant - Nhà tự điền sẵn, ẩn field]
    L -- Rồi, đã chọn ở H2 --> O2[Dùng Tenant đã chọn]
    M --> O[Nhập điều khoản: ngày bắt đầu, kỳ hạn, tiền cọc theo cả hợp đồng, tiền thuê/tháng, phương thức + đơn giá điện/nước, chu kỳ thu tiền nhà, ngày cố định hạn thanh toán, phí dịch vụ tự tính theo tổng m2, phí định kỳ, phạt trễ hạn - optional, môi giới - optional]
    N --> O
    O2 --> O
    O --> P[Lưu -> tb_contract + tb_contract_room 1 dòng/phòng + tb_contract_version #1 changeReason=New]
    P --> Q[Mọi phòng trong hợp đồng chuyển 'Occupied']
    Q --> R[Contract Detail]
    R --> S{Hành động sau này}
    S -- Gia hạn --> T[contract_version mới changeReason=Renewal - không đo lại chỉ số]
    T --> R
    S -- Sửa điều khoản/đổi danh sách phòng --> U[contract_version mới changeReason=Amendment]
    U --> U2{Có phòng bị loại khỏi hợp đồng?}
    U2 -- Có --> U3[Bắt buộc ghi chỉ số MOVE_OUT riêng cho phòng bị loại]
    U2 -- Không --> R
    U3 --> R
    S -- Xem lịch sử --> V[Version History]
    S -- Kết thúc hợp đồng --> W{Đã có đủ chỉ số MOVE_OUT cho từng phòng chưa?}
    W -- Chưa --> X[Bắt buộc ghi chỉ số trả phòng cho từng phòng - trừ phòng NOT_BILLED]
    X --> W
    W -- Đủ --> Y[Tổng kết công nợ: hoá đơn chưa Collected + damageDeduction -> tính refundAmount]
    Y --> Z2[Xác nhận -> ghi settlement vào tb_contract, status=Ended]
    Z2 --> AA[Mọi phòng trong hợp đồng chuyển lại 'Empty']
```
1 phòng chỉ 1 hợp đồng Active tại 1 thời điểm (ràng buộc UNIQUE trên `tb_contract_room`); 1 hợp đồng có thể gồm NHIỀU phòng nhưng chỉ 1 Tenant đại diện. Hoá đơn sẽ tách điện/nước theo từng phòng nhưng gộp 1 dòng tiền nhà/phí dịch vụ cho cả hợp đồng (xem Flow #3).

---

## 3. Bills — CORE FLOW (chức năng quan trọng nhất Phase 1)

```mermaid
flowchart TD
    A[Invoice List - nhóm theo Nhà -> theo Hợp đồng] --> B{Hành động}
    B -- Tạo hàng loạt --> C[Chọn 1 Nhà/Dãy trọ + 1 kỳ]
    C --> D[Hệ thống đọc lại chỉ số đã ghi cho mọi hợp đồng Active thuộc nhà đó]
    D --> E{Hợp đồng/phòng nào thiếu chỉ số kỳ này?}
    E -- Có --> F[Bỏ qua hợp đồng đó, liệt kê rõ phòng còn thiếu - KHÔNG ước lượng]
    E -- Đủ --> G[Tự tính: điện nước theo từng phòng; tiền nhà nếu đúng chu kỳ - chia theo ngày ở nếu có MOVE IN hoặc MOVE OUT trong kỳ; phí dịch vụ theo m2 và phí định kỳ - tính trọn cho hợp đồng đang Active lúc tạo hoá đơn, không chia theo ngày]
    B -- Tạo đơn lẻ --> C
    F --> H[Preview hàng loạt - Draft]
    G --> H
    H --> I{Xác nhận gửi?}
    I -- Sửa --> C
    I -- Gửi --> J[Sinh mã QR VietQR/NAPAS-247 cho từng hoá đơn]
    J --> K[Chọn kênh: SMS / Zalo / Cả hai]
    K --> L[Hệ thống tự động gửi hàng loạt cho từng Tenant]
    L --> M[Hoá đơn lưu, trạng thái 'Sent', hạn thanh toán = ngày cố định trong tháng theo hợp đồng]
    M --> N[Invoice List cập nhật - kỳ tương lai hiện chip 'Scheduled' preview, chưa tạo thật]
    N --> O{Landlord/Manager xác nhận đã thu tiền ngoài app?}
    O -- Có --> P[Đánh dấu 'Collected' trong Invoice Detail]
    O -- Chưa, quá hạn --> Q[Hệ thống tự hiển thị 'Overdue' theo dueDate - không lưu DB, kích hoạt Flow C]
```
Không còn bước Tenant tự đánh dấu "đã chuyển khoản". Điện/nước luôn tính theo tháng; tiền nhà chỉ xuất hiện đúng chu kỳ cấu hình trên hợp đồng (VD 2 tháng/lần) — kỳ không thu tiền nhà thì hoá đơn chỉ có điện/nước + phí dịch vụ + phí khác. **Cập nhật 09/09/2026 (`BR-BILL-08`):** khi đổi khách giữa tháng, chỉ **tiền nhà** chia theo số ngày ở; **phí dịch vụ và phí định kỳ không chia** — tính trọn cho hợp đồng đang có người ở tại thời điểm tạo hoá đơn của kỳ đó, phòng còn trống lúc đó thì không tính khoản này cho ai (chủ nhà tự chịu).

---

## 4. Profile — CORE FLOW

```mermaid
flowchart TD
    A[Tab Profile] --> B[Hồ sơ cá nhân - Detail/Edit]
    B --> C[Sửa: họ tên, giới tính, ngày sinh, email, CCCD/CMND, avatar - SĐT chỉ xem không sửa]
    A --> D[Người quản lý nhà - theo từng Nhà/Dãy trọ đang có role=owner]
    D --> E[Xem A2 - Mời/Thu hồi quyền theo Nhà/Dãy trọ]
    A --> F[Tài khoản ngân hàng nhận tiền - theo từng nhà]
    A --> G[Đổi mật khẩu]
    A -. dòng inline, cùng màn .-> J[Ngôn ngữ - chọn 1/3: English / Tiếng Việt / 한국어, ngôn ngữ khác để Phase 2 - sửa 09/09/2026, không phải màn riêng]
    A --> H[Login/Logout]
    H --> I[Xem Flow Z]
```

---

## C. Nhắc thanh toán quá hạn (Supporting — hỗ trợ Flow #3)

```mermaid
flowchart TD
    A[Hệ thống kiểm tra hoá đơn theo hạn thanh toán - dueDate] --> B{Còn trạng thái 'Sent' sau hạn?}
    B -- Không --> C[Không làm gì]
    B -- Có --> D[Gửi nhắc tự động cho Tenant qua SMS/Zalo, kèm mã QR]
    D --> E[Push cho người có quyền trên nhà đó: hoá đơn X đang 'Overdue']
    E --> F{Muốn nhắc thêm?}
    F -- Có --> G[Gửi nhắc thủ công / gọi điện trực tiếp ngoài app]
    F -- Không --> H[Chờ chu kỳ nhắc tiếp theo]
```
Tần suất nhắc: 3 ngày trước hạn, 1 ngày trước hạn, đúng hạn, 1 ngày sau hạn, 3 ngày sau hạn — xem BR-PAY-04.

---

## Z. Đăng xuất (Logout) — Supporting

```mermaid
flowchart TD
    A[Profile] --> B[Bấm 'Đăng xuất']
    B --> C[Hộp thoại xác nhận: 'Bạn có chắc muốn đăng xuất?']
    C -- Huỷ --> A
    C -- Xác nhận --> D[Xoá session/token trên máy]
    D --> E[Điều hướng về màn hình Đăng nhập]
```

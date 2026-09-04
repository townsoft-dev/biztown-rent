# User Flows — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 2 **Last updated:** 2026-09-03
> Diagram dùng cú pháp **Mermaid** — hiển thị trực tiếp trên GitHub.
> **Thay đổi lớn:** Viết lại toàn bộ theo cấu trúc **5 menu chính** cho Landlord + Manager (bỏ app Tenant). Bỏ Flow Search (#3 cũ), Flow Service Request (#8 cũ), Flow B (Tenant xem & thanh toán trong app). Thêm flow Manager onboarding, Contract Versioning, End Contract/Settlement. Xem [DECISIONS.md](DECISIONS.md) 2026-09-03.

---

## 0. Danh sách flow trong file này

### 5 Core Flows (theo [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.1 — mỗi flow tương ứng 1 menu bottom-nav)

1. House/Room Management — Quản lý Nhà/Dãy trọ & Phòng
2. Tenant Management — Quản lý Người thuê (Tenant Pool)
3. Contract Management — Tạo/Xem/Gia hạn/Kết thúc Hợp đồng (kèm Version History)
4. Bill Management (core) — Tạo & gửi hoá đơn tự động, theo dõi thu tiền
5. User Setting — Hồ sơ Chủ nhà, quản lý tài khoản Manager, đăng nhập/đăng xuất

### Flow hỗ trợ (Supporting)

- **A1.** Đăng nhập/Đăng ký — Landlord
- **A2.** Landlord tạo tài khoản Manager & cấp quyền theo Nhà/Dãy trọ
- **A3.** Đăng nhập — Manager
- **C.** Nhắc thanh toán quá hạn (hỗ trợ Flow #4)
- **Z.** Đăng xuất (Logout)

> ~~Flow #3 House/Room Search, Flow B (Tenant xem & thanh toán trong app), Flow #8 Service Request Management~~ → **Ngoài phạm vi Phase 1** (yêu cầu Tenant có app) — xem [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.2.

---

## A1. Đăng nhập/Đăng ký — Landlord

```mermaid
flowchart TD
    A[Mở app lần đầu] --> B{Đã có tài khoản?}
    B -- Chưa --> C[Đăng ký: SĐT]
    C --> D[Xác thực OTP]
    D --> D2[Tạo mật khẩu]
    D2 --> F[Hoàn tất onboarding -> Trang chủ Landlord trống]
    F --> G[Bắt đầu House/Room Management]
    B -- Rồi --> H[Đăng nhập bằng SĐT/OTP hoặc Mật khẩu]
    H --> I[Trang chủ Landlord]
```
Landlord là vai trò duy nhất tự đăng ký tài khoản trong Phase 1.

---

## A2. Landlord tạo tài khoản Manager & cấp quyền theo Nhà/Dãy trọ

```mermaid
flowchart TD
    A[User Setting] --> B[Quản lý Manager]
    B --> C[Bấm 'Thêm Manager']
    C --> D[Nhập SĐT, họ tên, mật khẩu ban đầu]
    D --> E[Chọn 1 hoặc nhiều Nhà/Dãy trọ để cấp quyền]
    E --> F[Lưu -> tạo tb_manager_account + tb_manager_house_access]
    F --> G[Manager có thể đăng nhập ngay bằng SĐT + mật khẩu được cấp]
    B --> H{Sửa Manager có sẵn?}
    H -- Có --> I[Thêm/bớt Nhà-Dãy trọ được cấp quyền, hoặc khoá tài khoản]
```
Manager không tự đăng ký — tài khoản và quyền truy cập hoàn toàn do Landlord khởi tạo/quản lý.

---

## A3. Đăng nhập — Manager

```mermaid
flowchart TD
    A[Mở app] --> B[Nhập SĐT + Mật khẩu được Landlord cấp]
    B --> C{Đúng thông tin?}
    C -- Có --> D[Vào Trang chủ Manager - chỉ thấy Nhà/Dãy trọ được cấp quyền]
    C -- Không --> B
    D --> E{Tài khoản bị khoá?}
    E -- Có --> F[Chặn đăng nhập, hiện thông báo liên hệ Landlord]
```

---

## 1. House/Room Management — CORE FLOW

```mermaid
flowchart TD
    A[Trang chủ] --> B[House List]
    B --> C{Hành động}
    C -- Thêm Nhà/Dãy trọ mới --> D[House Registration: tên, địa chỉ, mô tả, ảnh]
    D --> E[Lưu -> tb_house]
    E --> B
    C -- Chọn Nhà/Dãy trọ có sẵn --> F[Room List trong nhà đó]
    F --> G{Hành động}
    G -- Thêm phòng mới --> H[Room Detail Create/Edit: số phòng, diện tích, giá tham khảo, tiện ích, phí định kỳ, ảnh]
    H --> I[Lưu -> tb_room, trạng thái = Empty]
    I --> F
    G -- Chọn phòng có sẵn --> J[Room Detail]
    J --> K{Sửa hay Xoá?}
    K -- Sửa --> H
    K -- Xoá --> L{Phòng có hợp đồng Active?}
    L -- Có --> M[Chặn xoá, hiển thị cảnh báo]
    L -- Không --> N[Xoá phòng thành công]
```
Không giới hạn số lượng phòng đăng ký trong Phase 1. Trùng tên phòng trong cùng dãy trọ → cảnh báo, không chặn.
Manager chỉ thấy House List giới hạn theo Nhà/Dãy trọ được cấp quyền (`tb_manager_house_access`).

---

## 2. Tenant Management — CORE FLOW

```mermaid
flowchart TD
    A[Trang chủ] --> B[Tenant Pool List]
    B --> C[Bấm 'Thêm người thuê']
    C --> D[Tenant Profile Create/Edit: họ tên, SĐT, giới tính, ngày sinh, email, CCCD/CMND + ảnh 2 mặt, ghi chú]
    D --> E[Lưu -> tb_tenant, CHƯA gắn phòng/hợp đồng]
    E --> B
    B --> F{Gắn vào phòng ngay?}
    F -- Có --> G[Chuyển sang Contract Management: Create Contract]
    F -- Chưa, để sau --> H[Vẫn nằm trong Tenant Pool]
```
Tenant Pool dùng chung cho toàn bộ Landlord (và các Manager được cấp quyền tương ứng). Có thể tạo hồ sơ Tenant ngay trong lúc tạo hợp đồng (không bắt buộc tạo trước).

---

## 3. Contract Management — CORE FLOW

```mermaid
flowchart TD
    A[Room Detail - trạng thái Empty] --> B[Create Contract]
    B --> C{Chọn người thuê}
    C -- Từ Tenant Pool có sẵn --> D[Chọn Tenant]
    C -- Thêm mới ngay tại đây --> E[Nhập nhanh hồ sơ Tenant]
    D --> F[Nhập điều khoản: ngày bắt đầu, kỳ hạn, tiền cọc, tiền thuê/tháng, đơn giá điện/nước, phí định kỳ, phạt trễ hạn - optional, thông tin môi giới - optional]
    E --> F
    F --> G[Lưu -> tạo tb_contract + tb_contract_version #1 changeReason=New]
    G --> H[Trạng thái phòng chuyển 'Occupied']
    H --> I[Contract Detail]
    I --> J{Hành động sau này}
    J -- Gia hạn --> K[Tạo tb_contract_version mới changeReason=Renewal]
    K --> I
    J -- Sửa điều khoản giữa kỳ --> K2[Tạo tb_contract_version mới changeReason=Amendment]
    K2 --> I
    J -- Xem lịch sử --> L[Version History - toàn bộ tb_contract_version theo thời gian]
    J -- Kết thúc hợp đồng --> M[End Contract]
    M --> N[Tổng kết công nợ: hoá đơn chưa Collected + damageDeduction -> tính refundAmount]
    N --> O[Xác nhận -> tạo tb_contract_settlement, contract.status=Ended]
    O --> P[Trạng thái phòng chuyển lại 'Empty']
```
1 phòng chỉ 1 hợp đồng Active tại 1 thời điểm; 1 hợp đồng chỉ 1 Tenant đại diện (fixed representative). Danh sách hợp đồng (Contract List) hỗ trợ filter theo "sắp hết hạn".

---

## 4. Bill Management — CORE FLOW (chức năng quan trọng nhất Phase 1)

```mermaid
flowchart TD
    A[Invoice List] --> B[Create Invoice]
    B --> C[Chọn phòng/hợp đồng đang Active]
    C --> D[Nhập chỉ số điện/nước mới - so với chỉ số cũ]
    D --> E{Chỉ số mới >= chỉ số cũ?}
    E -- Không hợp lệ --> D
    E -- Hợp lệ --> F[App tự tính: điện/nước tiêu thụ, tiền phòng theo contract_version hiệu lực, phí định kỳ]
    F --> G[Preview hoá đơn - Draft]
    G --> H{Xác nhận gửi?}
    H -- Sửa --> D
    H -- Gửi --> I[Chọn kênh: SMS / Zalo / Cả hai]
    I --> J[Hệ thống tự động gửi cho Tenant]
    J --> K[Hoá đơn lưu, trạng thái 'Sent']
    K --> L[Invoice List cập nhật, filter/sort theo trạng thái Draft/Sent/Collected/Overdue và theo tháng]
    L --> M{Landlord/Manager xác nhận đã thu tiền ngoài app?}
    M -- Có --> N[Đánh dấu 'Collected' trong Invoice Detail]
    M -- Chưa, quá hạn --> O[Hệ thống tự đánh dấu hiển thị 'Overdue', kích hoạt Flow C]
```
Không còn bước Tenant tự đánh dấu "đã chuyển khoản" hay trạng thái "Chờ xác nhận" — Landlord/Manager là bên duy nhất cập nhật trạng thái thu tiền, dựa trên xác nhận thực tế ngoài app (chuyển khoản, tiền mặt, báo qua Zalo cá nhân...). "Phí khác" theo điều khoản hợp đồng, snapshot vào hoá đơn tại thời điểm tạo.

---

## 5. User Setting — CORE FLOW

```mermaid
flowchart TD
    A[Trang chủ] --> B[User Setting]
    B --> C[Owner Profile - Detail/Create]
    C --> D[Sửa: họ tên, SĐT, giới tính, ngày sinh, email, CCCD/CMND, mã số thuế, số tài khoản ngân hàng, avatar]
    B --> E[Manager Management]
    E --> F[Xem A2 - Tạo/Sửa Manager & quyền theo Nhà/Dãy trọ]
    B --> G[Login/Logout]
    G --> H[Xem Flow Z]
```

---

## C. Nhắc thanh toán quá hạn (Supporting — hỗ trợ Flow #4)

```mermaid
flowchart TD
    A[Hệ thống kiểm tra hoá đơn theo hạn thanh toán] --> B{Còn trạng thái 'Sent' sau hạn?}
    B -- Không --> C[Không làm gì]
    B -- Có --> D[Gửi nhắc tự động cho Tenant qua SMS/Zalo]
    D --> E[Push cho Landlord/Manager: hoá đơn X đang 'Overdue']
    E --> F{Landlord/Manager muốn nhắc thêm?}
    F -- Có --> G[Gửi nhắc thủ công / gọi điện trực tiếp ngoài app]
    F -- Không --> H[Chờ chu kỳ nhắc tiếp theo]
```
Tần suất nhắc: 3 ngày trước hạn, 1 ngày trước hạn, đúng hạn, 1 ngày sau hạn, 3 ngày sau hạn — xem BR-PAY-04.

---

## Z. Đăng xuất (Logout) — Supporting, cả Landlord & Manager

```mermaid
flowchart TD
    A[User Setting] --> B[Bấm 'Đăng xuất']
    B --> C[Hộp thoại xác nhận: 'Bạn có chắc muốn đăng xuất?']
    C -- Huỷ --> A
    C -- Xác nhận --> D[Xoá session/token trên máy]
    D --> E[Điều hướng về màn hình Đăng nhập]
```

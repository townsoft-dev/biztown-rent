# User Flows — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 1  **Last updated:** 2026-08-28
> Diagram dùng cú pháp **Mermaid** — hiển thị trực tiếp trên GitHub.

---

## 0. Danh sách flow trong file này

### 8 Core Flows (theo [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.1, bản cập nhật 2026-08-28 — đây là các flow xương sống của MVP, cần polish kỹ nhất, thứ tự 1→8 cũng là thứ tự ưu tiên UX)

1. House/Room Registration — Đăng ký Nhà/Dãy trọ & Phòng
2. Tenant Registration — Đăng ký Người thuê
3. House/Room Search — Tìm kiếm & xem nhà/phòng cho thuê 
4. Lease Contract Creation — Tạo Hợp đồng thuê
5. Periodic Meter Reading — Ghi chỉ số điện/nước định kỳ
6. Create Bills & Send via SMS/Zalo — Tạo hoá đơn & gửi tự động
7. Revenue Report — Báo cáo doanh thu
8. Service Request Management — Tạo & xử lý yêu cầu của người thuê (sửa chữa/bảo trì/đăng ký lưu trú...)

### Flow hỗ trợ (Supporting — cần thiết để có hành trình đầy đủ login→logout, không phải trọng tâm polish nhưng vẫn phải có trong Figma)

- **A1.** Đăng nhập/Đăng ký — Chủ trọ (Landlord)
- **A2.** Đăng nhập/Đăng ký — Người thuê (Tenant), qua lời mời
- **B.** Người thuê xem hoá đơn & thanh toán *(là "mặt sau" của Flow #6)*
- **C.** Nhắc thanh toán quá hạn *(hỗ trợ Flow #6)*
- **Z.** Đăng xuất (Logout)

---

## A1. Đăng nhập/Đăng ký — Chủ trọ (Landlord)

```mermaid
flowchart TD
    A[Mở app lần đầu] --> B{Đã có tài khoản?}
    B -- Chưa --> C[Đăng ký: SĐT]
    C --> D[Xác thực OTP - Firebase Phone Auth]
    D --> D2[Tạo mật khẩu]
    D2 --> E[Chọn vai trò: Chủ trọ]
    E --> F[Hoàn tất onboarding -> Trang chủ Chủ trọ trống]
    F --> G[Bắt đầu Flow #1: House/Room Registration]
    B -- Rồi --> H[Đăng nhập bằng SĐT/OTP hoặc Mật khẩu]
    H --> I[Trang chủ Chủ trọ]
```
Chủ trọ không bắt buộc phải đăng ký phòng ngay khi đăng ký tài khoả, tách biệt 2 flow riêng biệt
---

## A2. Đăng nhập/Đăng ký — Người thuê (Tenant), qua lời mời

```mermaid
flowchart TD
    A[Chủ trọ hoàn tất Flow #4 - Tạo hợp đồng] --> B[Hệ thống gửi lời mời qua SMS/Zalo kèm link/mã]
    B --> C[Người thuê bấm link / nhập mã mời trong app]
    C --> D{Đã cài app chưa?}
    D -- Chưa --> E[Tải app -> mở link -> vào thẳng màn hình xác nhận mời]
    D -- Rồi --> F[Mở app -> đăng nhập/đăng ký bằng SĐT/OTP]
    E --> G[Xác nhận thông tin cá nhân]
    F --> G
    G --> H[Xác nhận đã vào đúng phòng/hợp đồng]
    H --> I[Hoàn tất -> Trang chủ Người thuê: xem hợp đồng + hoá đơn]
```
Người thuê should cài đặt app
Nội dung mẫu tin nhắn mời :
"Hi! 👋
I just created a lease agreement for your room on Town Rental app. Please check out this link to view the details and confirm:
[Link/Code]
Everything will be easier through the app - payments, receipts, maintenance requests... all in one place.
Let me know if you need any help! 😊"

---

## 1. House/Room Registration (Chủ trọ) — CORE FLOW

```mermaid
flowchart TD
    A[Trang chủ Chủ trọ] --> B[Danh sách Nhà/Dãy trọ]
    B --> C{Hành động}
    C -- Thêm dãy trọ mới --> D[Nhập thông tin: tên, địa chỉ, mô tả, ảnh]
    D --> E[Lưu dãy trọ]
    E --> B
    C -- Chọn dãy trọ có sẵn --> F[Danh sách Phòng trong dãy trọ này]
    F --> G{Hành động}
    G -- Thêm phòng mới --> H[Nhập thông tin phòng: số phòng, diện tích, giá thuê, tiện ích, ảnh, đơn giá điện/nước]
    H --> I[Lưu phòng -> Trạng thái = Trống]
    I --> F
    G -- Chọn phòng có sẵn --> J[Chi tiết Phòng]
    J --> K{Sửa hay Xoá?}
    K -- Sửa --> H
    K -- Xoá --> L{Phòng có hợp đồng active?}
    L -- Có --> M[Chặn xoá, hiển thị cảnh báo]
    L -- Không --> N[Xoá phòng thành công]
```
phase 1 không giới hạn số lượng phòng đăng ký
trong cùng 1 dãy trọ thì check trùng > cảnh báo

---

## 2. Tenant Registration (Chủ trọ) — CORE FLOW

```mermaid
flowchart TD
    A[Trang chủ Chủ trọ] --> B[Danh sách Người thuê - Tenant Pool]
    B --> C[Bấm 'Thêm người thuê']
    C --> D[Nhập thông tin: họ tên, SĐT, CMND/CCCD, ảnh giấy tờ]
    D --> E[Lưu hồ sơ người thuê -> vào 'Tenant Pool', CHƯA gắn phòng/hợp đồng]
    E --> B
    B --> F{Gắn vào phòng ngay?}
    F -- Có --> G[Chuyển sang Flow #4: Lease Contract Creation]
    F -- Chưa, để sau --> H[Người thuê vẫn nằm trong Tenant Pool, chưa active]
```
Chỉ mời người thuê dùng app khi số điện thoại chưa có tài khoản và đã ký hợp đồng

---

## 3. House/Room Search — Tìm kiếm & xem nhà/phòng cho thuê — CORE FLOW
### 3a. Người thuê (Tenant) — Tìm kiếm & gửi yêu cầu liên hệ

```mermaid
flowchart TD
    A[Trang chủ Người thuê] --> B[Bấm tab/mục 'Tìm phòng']
    B --> C[Màn hình Tìm kiếm - danh sách phòng đang mở public]
    C --> D{Dùng bộ lọc?}
    D -- Có --> E[Lọc theo: khu vực/quận, khoảng giá, loại phòng]
    E --> C
    D -- Không --> F[Cuộn xem danh sách mặc định - sắp xếp mới nhất/gần nhất]
    F --> G[Chọn 1 phòng -> Xem Chi tiết Phòng - public view]
    G --> H[Xem ảnh, giá, tiện ích, khu vực, mô tả]
    H --> I{Quan tâm?}
    I -- Có --> J[Bấm 'Gửi yêu cầu liên hệ']
    J --> K[Xác nhận SĐT liên hệ - lấy từ hồ sơ, cho sửa nếu cần]
    K --> L[Gửi yêu cầu -> Chủ trọ nhận thông báo]
    L --> M[Màn hình xác nhận: 'Đã gửi yêu cầu, Chủ trọ sẽ liên hệ lại']
    I -- Không --> C
```
Người thuê đã có hợp đồng active ở nơi khác có được dùng tính năng tìm phòng


### 3b. Chủ trọ — Quản lý hiển thị Public Listing & Yêu cầu liên hệ

```mermaid
flowchart TD
    A[Chi tiết Phòng - L-06, trạng thái Trống] --> B{Bật toggle 'Đăng tìm người thuê'?}
    B -- Bật --> C[Phòng xuất hiện trong kết quả Tìm kiếm của Tenant]
    C --> D[Chủ trọ nhận thông báo khi có Yêu cầu liên hệ mới]
    D --> E[Vào danh sách 'Yêu cầu liên hệ' - L-19]
    E --> F[Xem chi tiết người quan tâm: tên, SĐT, thời gian gửi]
    F --> G{Hành động}
    G -- Liên hệ lại --> H[Gọi điện / nhắn Zalo ngoài app]
    H --> I{Chốt thuê?}
    I -- Có --> J[Chuyển sang Flow #2: Tenant Registration -> Flow #4: Lease Contract Creation]
    I -- Không --> K[Đánh dấu yêu cầu 'Đã liên hệ / Không chốt']
    G -- Bỏ qua --> K
    B -- Tắt --> L[Phòng không hiển thị trong Tìm kiếm]
    J --> M[Phòng có hợp đồng -> tự động tắt toggle Public listing, trạng thái phòng 'Đã thuê']
```

Phase 1 không giới hạn số phòng được đăng public 
Yêu cầu liên hệ tự xóa khi phòng không còn trống
---

## 4. Lease Contract Creation (Chủ trọ) — CORE FLOW

```mermaid
flowchart TD
    A[Chi tiết Phòng - trạng thái Trống] --> B[Bấm 'Tạo hợp đồng']
    B --> C{Chọn người thuê}
    C -- Từ Tenant Pool có sẵn --> D[Chọn người thuê từ danh sách - Flow #2, hoặc từ Yêu cầu liên hệ - Flow #3]
    C -- Thêm mới ngay tại đây --> E[Nhập nhanh thông tin người thuê - shortcut của Flow #2]
    D --> F[Nhập điều khoản hợp đồng: ngày bắt đầu, kỳ hạn, tiền cọc, tiền thuê/tháng]
    E --> F
    F --> G[Lưu hợp đồng -> Trạng thái phòng chuyển 'Đã thuê']
    G --> H[Hệ thống gửi lời mời cho người thuê qua SMS/Zalo - Flow A2]
    H --> I[Chi tiết Hợp đồng]
    I --> J{Gia hạn hoặc kết thúc hợp đồng sau này?}
    J -- Gia hạn --> J2[Gia hạn hợp đồng - xem BUSINESS-RULES.md BR-CTR-05]
    J2 --> I
    J -- Kết thúc --> K[Xử lý trả phòng: hoàn/trừ cọc, chốt công nợ]
    K --> L[Trạng thái phòng chuyển lại 'Trống']
```

---

## 5. Periodic Meter Reading — Ghi chỉ số điện/nước định kỳ (Chủ trọ) — CORE FLOW

```mermaid
flowchart TD
    A[Đến kỳ ghi số hàng tháng - nhắc tự động từ hệ thống] --> B[Chọn Dãy trọ]
    B --> C[Danh sách Phòng - hiển thị ngày ghi số gần nhất từng phòng]
    C --> D[Chọn phòng cần ghi số]
    D --> E[Nhập chỉ số điện mới]
    E --> F[Nhập chỉ số nước mới]
    F --> G{Chỉ số mới >= chỉ số cũ?}
    G -- Không hợp lệ --> E
    G -- Hợp lệ --> H[Lưu chỉ số -> lưu vào lịch sử ghi số]
    H --> I{Còn phòng nào chưa ghi?}
    I -- Còn --> D
    I -- Hết --> J[Quay lại Trang chủ / hoặc tiếp tục sang Flow #6: Tạo hoá đơn]
```
Hệ thống should nhắc ngày ghi chỉ số, theo lịch cố định mà landlord setting

---

## 6. Create Bills & Send via SMS/Zalo — Tạo hoá đơn & gửi tự động (Chủ trọ) — CORE FLOW

```mermaid
flowchart TD
    A[Phòng đã có chỉ số điện/nước mới - từ Flow #5] --> B[Chủ trọ chọn phòng cần tạo hoá đơn]
    B --> C[App tự tính: số điện/nước tiêu thụ = chỉ số mới - chỉ số cũ]
    C --> D[App tự tính hoá đơn = Tiền phòng + Tiền điện + Tiền nước + Phí khác]
    D --> E[Xem trước hoá đơn - preview]
    E --> F{Xác nhận gửi?}
    F -- Sửa --> C
    F -- Gửi từng phòng --> G[Chọn kênh gửi: SMS / Zalo / Cả hai]
    F -- Gửi hàng loạt nhiều phòng --> G2[Chọn kênh gửi chung cho tất cả]
    G --> H[Hệ thống tự động gửi hoá đơn tới người thuê]
    G2 --> H
    H --> I[Hoá đơn lưu vào lịch sử, trạng thái 'Chưa thanh toán']
    I --> J[Trang chủ Chủ trọ cập nhật: tổng cần thu tháng này]
    J --> K[Chuyển sang Flow B: Người thuê xem & thanh toán]
```
"Phí khác" bao gồm nhiều loại được tính theo điều khoản hợp đồng, được landlord nhập vào hệ hợp đồng thuê
đơn gia theo nội dung hợp đồng, được landlord điền hoặc tự động hiển thị theo hợp đồng

---

## 7. Revenue Report — Báo cáo doanh thu (Chủ trọ) — CORE FLOW

```mermaid
flowchart TD
    A[Trang chủ Chủ trọ] --> B[Vào mục Báo cáo]
    B --> C[Chọn khoảng thời gian: tháng / quý / tuỳ chọn]
    C --> D[Chọn phạm vi: tất cả dãy trọ / 1 dãy / 1 phòng]
    D --> E[Xem tổng quan: Tổng doanh thu, Đã thu, Chưa thu, Quá hạn]
    E --> F[Xem chi tiết theo từng phòng/hợp đồng]
    F --> G[Xuất báo cáo PDF/Excel]
```
---

## 8. Service Request Management — Yêu cầu của Người thuê — CORE FLOW

```mermaid
flowchart TD
    A[Người thuê có nhu cầu - sửa chữa, bảo trì, đăng ký lưu trú, khác] --> B[Mở app -> Tạo yêu cầu]
    B --> C[Chọn loại yêu cầu: Sửa chữa / Bảo trì / Đăng ký lưu trú / Khác]
    C --> D[Nhập mô tả + đính kèm ảnh/tài liệu nếu cần]
    D --> E[Gửi yêu cầu -> Chủ trọ nhận thông báo]
    E --> F{Chủ trọ xử lý}
    F -- Tiếp nhận --> G[Cập nhật trạng thái: 'Đang xử lý']
    G --> H[Chủ trọ hoàn tất xử lý]
    H --> I[Cập nhật trạng thái: 'Đã xử lý']
    I --> J[Người thuê nhận thông báo hoàn tất -> có thể phản hồi - optional]
    F -- Từ chối/Cần trao đổi thêm --> K[Ghi chú phản hồi cho người thuê]
    E --> L[Chủ trọ xem toàn bộ danh sách yêu cầu, lọc theo trạng thái/loại]
```
"loại yêu cầu khác" bao gồm Sửa chữa/Bảo trì/Đăng ký lưu trú/Khác. Chọn "Khác" sẽ có input để nhập
nếu phát sinh chi phí thì landlord phản hồi trong ghi chú và giải quyết thủ công không qua app

---

## B. Người thuê xem hoá đơn & thanh toán (Supporting — "mặt sau" của Flow #6)

```mermaid
flowchart TD
    A[Người thuê nhận SMS/Zalo báo hoá đơn mới] --> B[Mở app -> Trang chủ Người thuê]
    B --> C[Xem chi tiết hoá đơn tháng này]
    C --> D[Xem thông tin STK chủ trọ / mã QR]
    D --> E[Người thuê chuyển khoản bên ngoài app]
    E --> F[Người thuê bấm 'Đã thanh toán' -> đính kèm ảnh chứng từ - optional]
    F --> G[Trạng thái hoá đơn: 'Chờ xác nhận']
    G --> H[Chủ trọ xác nhận đã nhận tiền]
    H --> I[Trạng thái hoá đơn: 'Đã thanh toán']
```
---

## C. Nhắc thanh toán quá hạn (Supporting — hỗ trợ Flow #6)

```mermaid
flowchart TD
    A[Hệ thống kiểm tra hoá đơn theo hạn thanh toán] --> B{Còn 'Chưa thanh toán' sau hạn?}
    B -- Không --> C[Không làm gì]
    B -- Có --> D[Gửi nhắc nhở tự động cho người thuê qua SMS/Zalo/Push]
    D --> E[Cập nhật trạng thái hiển thị cho Chủ trọ: 'Quá hạn']
    E --> F{Chủ trọ muốn nhắc thêm?}
    F -- Có --> G[Gửi nhắc thủ công / gọi điện trực tiếp từ app]
    F -- Không --> H[Chờ chu kỳ nhắc tiếp theo]
```
tần suất nhắc: 3 ngày trước hạn, 1 ngày trước hạn, đúng hạn, 1 ngày sau hạn, 3 ngày sau hạn

---

## Z. Đăng xuất (Logout) — Supporting, cả 2 vai trò

```mermaid
flowchart TD
    A[Màn hình Hồ sơ cá nhân / Cài đặt] --> B[Bấm 'Đăng xuất']
    B --> C[Hộp thoại xác nhận: 'Bạn có chắc muốn đăng xuất?']
    C -- Huỷ --> A
    C -- Xác nhận --> D[Xoá session/token trên máy]
    D --> E[Điều hướng về màn hình Đăng nhập]
```


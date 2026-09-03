# Product Overview — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 1  **Last updated:** 2026-08-28

---

## 1. Tóm tắt sản phẩm (Executive Summary)
**Tên thương hiệu:** BizTown
**Tên sản phẩm:** Rent-Manager
**Nền tảng**: Mobile app - Flutter (mobile app, iOS/Android) + Supabase (Postgres DB, Auth, Storage, Edge Functions)

**Description:** BizTown Rent-Manager là ứng dụng quản lý cho thuê toàn diện — giúp chủ trọ quản lý hợp đồng, hoá đơn, sửa chữa và thu tiền; đồng thời cho người thuê tìm kiếm, đặt lịch xem, thanh toán và gửi yêu cầu — tất cả trong một app, dễ dàng và minh bạch.

## 2. Vấn đề cần giải quyết (Problem Statement)
- Chủ trọ hiện quản lý phòng/khách thuê thủ công qua Excel, sổ tay, hoặc nhóm Zalo — dễ sai sót khi tính tiền điện nước, quên nhắc thu tiền, khó theo dõi dòng tiền tổng thể khi có nhiều phòng/nhiều dãy trọ.
- Người thuê không có kênh minh bạch để xem lại hoá đơn, lịch sử thanh toán, hoặc gửi yêu cầu sửa chữa — phải nhắn tin/gọi điện trực tiếp.
- Các phần mềm hiện có trên thị trường (Smartos, iTro/Khutro, DigiStay...) thường thiên về **web-based cho chủ trọ**, chưa tối ưu trải nghiệm mobile 2 chiều đơn giản cho cả chủ và khách thuê. (Chưa có số liệu phân tích thị trường, research thực tế)

## 3. Đối tượng người dùng (Target Users)
Sản phẩm 2 chiều dành cho cả chủ trọ và người thuê, nhiều chủ trọ với nhiều quy mô cho thuê khác nhau và người thuê trợ có các nhu cầu sử dụng nhà/phòng trọ khác nhau.

### 3.1 Vai trò chính (Roles)
| Vai trò | Mô tả | Ghi chú |
|---|---|---|
| **Chủ trọ (Landlord)** | Chủ sở hữu/quản lý nhà và phòng cho thuê. Tạo tài khoản, đăng ký nhà và phòng, quản lý phòng và người thuê, tạo hợp đồng, kiểm tra thông số tiêu dùng điện nước,.. định kỳ, tạo hóa đơn, gửi hóa đơn và thu tiền, quản lý tiếp nhận và xử lý yêu cầu của người thuê (sửa chữa, đăng ký cư trú,...)| Quy mô đa dạng: phòng lẻ, nhà riêng, dãy trọ, chung cư mini,... |
| **Người thuê (Tenant)** | Người thuê phòng. Xem hợp đồng, hóa đơn, lịch sử thanh toán, thanh toán hóa đơn, gửi yêu cầu sửa chữa,..| Nhu cầu thuê đa dạng: sinh viên, người đi làm, gia đình, ngắn hạn dài hạn |

### 3.2 Persona sơ bộ
- **Persona A — Chủ trọ nhỏ lẻ:** quản lý 1 dãy trọ (5-10 phòng), tự làm mọi việc, chưa dùng phần mềm quản lý nào trước đó. Độ tuổi khoảng 50 trở lên, thiết bị chính là smartphone , kênh liên lạc quen dùng là Zalo
- **Persona B — Chủ trọ/chủ đầu tư quy mô vừa:** quản lý nhiều dãy trọ hoặc chung cư mini, cần báo cáo doanh thu tổng hợp. Độ tuổi khoảng 30 trở lên, thiêt bị chính là smartphone, kênh liên lạc quen dùng là Zalo
- **Persona C — Người thuê sinh viên/người đi làm:** quan tâm chính đến xem hoá đơn rõ ràng, thanh toán nhanh, báo sửa chữa dễ dàng. Thuộc nhiều lứa tuổi trên 18, thiết bị chính là smartphone, kênh liên lạc quen dùng là email, zalo, sms

## 4. Giá trị cốt lõi (Value Proposition)
| Đối tượng | Giá trị mang lại |
|---|---|
| Chủ trọ | Quản lý phòng/hợp đồng/người thuê tập trung trên điện thoại; tự động tính hoá đơn điện nước; gửi hoá đơn tự động qua SMS/Zalo; nhắc thu tiền; báo cáo doanh thu theo phòng/theo tháng. Quản lý tiếp nhận và xử lý yêu cầu của người |
| Người thuê | Minh bạch hoá đơn & lịch sử thanh toán; nhận thông báo tự động; gửi yêu cầu sửa chữa và theo dõi tiến độ xử lý. |

## 5. Phạm vi sản phẩm (Product Scope)

### 5.1 MVP — 8 Core Flows 
8 flow nghiệp vụ chính sau là xương sống tại Phase 1 MVP (đây là các flow cần pplish UX kỹ nhất, và cũng là cơ sở cho toàn bộ wireframe Figma), xem chi tiết [USER-FLOWS.md](USER-FLOWS.md) để có flowchart chi tiết từng flow:

1. **House/Room Registration** — Đăng ký Nhà/Dãy trọ (tên, địa chỉ, mô tả, hình ảnh...) & Phòng (Chi tiết number, diện tích, giá cả, tiện ích, hình ảnh, ...) - tạo/sửa/xoá phòng, trạng thái trống/đã thuê.
2. **Tenant Registration** — Đăng ký hồ sơ Người thuê, **độc lập** với việc gắn vào phòng cụ thể (mô hình "Tenant Pool" — xem [USER-FLOWS.md](USER-FLOWS.md) Flow #2).
3. **House/Room Search** - Người thuê tìm kiếm nhà, phòng trọ phù hợp nhau cầu, tạo yêu cầu xem nhà, liên lạc chủ trọ. Chủ trọ có thể chủ động bật tắt hiển thị phòng nếu phòng đang trống. người thuê phải có tài khoản mới xem được danh sách phòng.
4. **Lease Contract Creation** — Tạo Hợp đồng thuê: gắn Người thuê (từ Tenant Pool hoặc tạo mới) vào Phòng, nhập điều khoản (ngày vào/ra, tiền cọc, kỳ hạn).
5. **Periodic Meter Reading** — Ghi chỉ số điện/nước định kỳ hàng tháng cho từng phòng, lưu lịch sử chỉ số.
6. **Create Bills & Send via SMS/Zalo** — Hệ thống tự tính hoá đơn (tiền phòng + điện + nước + phí khác) từ chỉ số đã ghi, và **tự động gửi hoá đơn qua SMS hoặc Zalo**.
7. **Revenue Report** — Báo cáo doanh thu theo tháng/phòng/dãy trọ (tổng, đã thu, chưa thu, quá hạn).
8. **Service Request Management** — Người thuê tạo yêu cầu sửa chữa/bảo trì, chủ trọ tiếp nhận và xử lý yêu cầu

Ngoài 8 core flow trên, Phase 1 MVP còn cần các flow hỗ trợ để có hành trình đầy đủ: Đăng nhập/Đăng ký (Login/Signup), Người thuê xem & thanh toán hoá đơn, Nhắc thanh toán quá hạn, và Đăng xuất (Logout) — xem chi tiết ở [USER-FLOWS.md](USER-FLOWS.md).

### 5.2 Ngoài phạm vi MVP (Later / Phase 2+)
- Thêm user có phân quyền quản lý phòng trọ (tài khoản quản lý thứ cấp)
- chat trong app giữa chủ trọ và người thuê
- nhắc nhở lịch hạn hợp đồng, thời hạn xử lý yêu cầu,..
- đa ngôn ngữ

## 6. Business model
- Phase 1 hoàn toàn miễn phí
- Phase 2+ sẽ cân nhắc Freemium hoặc trả tiền theo quy mô cho thuê

## 7. Bối cảnh cạnh tranh (Competitive Landscape)
Tham khảo nhanh các sản phẩm cùng phân khúc tại Việt Nam (quản lý nhà trọ/phòng trọ cho thuê):

| Sản phẩm | Điểm mạnh quan sát được | Ghi chú |
|---|---|---|
| **Smartos** | Phần mềm/PMS quản lý BĐS cho thuê, có bản web + app, tính năng khá đầy đủ (quản lý phòng, hợp đồng, hoá đơn, báo cáo). | Nguồn: smartos.space — `NEEDS INPUT`: dùng thử thực tế để so sánh UX. |
| **iTro (Khutro)** | Phần mềm quản lý nhà trọ phổ biến tại VN. | chưa có dữ liệu chi tiết, đang khảo sát thêm tính năng cụ thểm. |
| **DigiStay** |chưa có dữ liệu chi tiết,  khảo sát thêm tính năng cụ thể. | | 

**Định hướng khác biệt hoá đề xuất**:
- Trải nghiệm **mobile-first, 2 chiều** (landlord + tenant cùng 1 app) thay vì chủ yếu web cho chủ trọ.
- Flow đơn giản, tối thiểu số bước, không ôm nhiều tính năng phức tạp ngay từ đầu.
- Tự động hoá gửi hoá đơn qua kênh người Việt hay dùng (SMS/Zalo) thay vì chỉ email/in-app.

## 8. Success Metrics (KPIs) 
- Xây dựng được MVP hoàn chỉnh phase 1 trong vòng 1 tháng
- Có user đăng ký dùng app và feedback

## 9. Giả định & Rủi ro (Assumptions & Risks)

- **Giả định:** Chủ trọ và người thuê đều sẵn sàng cài app mới (thay vì chỉ dùng Zalo/SMS như hiện tại). 
- **Giả định:** Việc ghi chỉ số điện/nước là nhập tay bởi chủ trọ (chưa có tích hợp IoT/đồng hồ thông minh) 
- **Rủi ro:** Người thuê có thể không chủ động cài app nếu không bị bắt buộc — cần cơ chế mời/onboard đơn giản (link, QR, SMS mời).
- **Rủi ro:** Gửi SMS/Zalo tự động cần tích hợp bên thứ 3 (Zalo) — có chi phí & cần pháp lý ( [BUSINESS-RULES](BUSINESS-RULES.md) sẽ ghi chi tiết).

## 10. Tài liệu liên quan
- [USER-FLOWS](USER-FLOWS.md) - flow nghiệp vụ chính
- [REQUIREMENTS](REQUIREMENTS.md) - yêu cầu chức năng/phi chức năng
- [BUSINESS-RULES](BUSINESS-RULES.md) - quy tắc nghiệp vụ
- [SCREEN-SPEC](SCREEN-SPEC.md) - mô tả màn hình
- [DESIGN](DESIGN.md) - hệ thống thiết kế
- [CLAUDE](CLAUDE.md) - hướng dẫn cho dev/Claude Code khi phát triển 
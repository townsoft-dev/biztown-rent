# Product Overview — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 2 **Last updated:** 2026-09-03
> **Thay đổi lớn so với Version 1:** Phase 1 **thu hẹp phạm vi** lại chỉ còn đối tượng **Landlord (Chủ trọ) + Manager (tài khoản quản lý phụ do Landlord tạo)** — **bỏ hẳn app/tài khoản Tenant** ở giai đoạn này. Xem quyết định đầy đủ tại [DECISIONS.md](DECISIONS.md) (2026-09-03).

---

## 1. Tóm tắt sản phẩm (Executive Summary)
**Tên thương hiệu:** BizTown
**Tên sản phẩm:** Rent-Manager
**Nền tảng**: Mobile app - Flutter (mobile app, iOS/Android) + Supabase (Postgres DB, Auth, Storage, Edge Functions)

**Description:** BizTown Rent-Manager (Phase 1) là công cụ nội bộ dành cho Chủ trọ (Landlord) và người quản lý được Chủ trọ uỷ quyền (Manager) để quản lý nhà/phòng, người thuê, hợp đồng, và **tự động tạo & gửi hoá đơn điện nước hàng tháng**. Người thuê (Tenant) trong Phase 1 **không cài app, không có tài khoản** — chỉ là hồ sơ dữ liệu trong hệ thống và là người nhận hoá đơn/nhắc thanh toán qua SMS/Zalo.

## 2. Vấn đề cần giải quyết (Problem Statement)
- Chủ trọ hiện quản lý phòng/khách thuê thủ công qua Excel, sổ tay, hoặc nhóm Zalo — dễ sai sót khi tính tiền điện nước, quên nhắc thu tiền, khó theo dõi dòng tiền tổng thể khi có nhiều phòng/nhiều dãy trọ.
- Chủ trọ quản lý nhiều dãy trọ thường cần người phụ giúp (quản lý/nhân viên) theo dõi từng dãy trọ cụ thể, nhưng không có cơ chế phân quyền rõ ràng, dễ rủi ro khi chia sẻ chung 1 tài khoản.
- Việc tính hoá đơn điện nước hàng tháng và gửi cho người thuê tốn nhiều thời gian thủ công, dễ sai số, dễ quên gửi/quên nhắc thanh toán.
- Các phần mềm hiện có trên thị trường (Smartos, iTro/Khutro, DigiStay...) thường thiên về **web-based cho chủ trọ**, chưa tối ưu cho việc quản lý nhanh trên điện thoại. (Chưa có số liệu phân tích thị trường, research thực tế)

> **Ghi chú phạm vi:** Bài toán "người thuê cần kênh minh bạch xem hoá đơn/gửi yêu cầu trong app" (từng là 1 phần vấn đề ở Version 1) được **dời sang Phase 2+** — xem mục 5.2.

## 3. Đối tượng người dùng (Target Users)
Phase 1 phục vụ **nội bộ phía chủ trọ**: nhiều Landlord, mỗi Landlord có thể tạo thêm các tài khoản Manager để chia việc quản lý.

### 3.1 Vai trò chính (Roles)
| Vai trò | Mô tả | Ghi chú |
|---|---|---|
| **Chủ trọ (Landlord)** | Chủ tài khoản gốc. Tạo tài khoản, đăng ký Nhà/Phòng, quản lý Người thuê (hồ sơ), tạo/quản lý Hợp đồng, tạo & gửi hoá đơn, tạo và cấp quyền cho tài khoản Manager. | Toàn quyền trên toàn bộ dữ liệu của mình. |
| **Quản lý (Manager)** | Tài khoản phụ **do Landlord tạo** (không tự đăng ký), được cấp quyền truy cập theo **từng Nhà/Dãy trọ cụ thể** (không mặc định thấy toàn bộ dữ liệu của Landlord). Thực hiện các nghiệp vụ vận hành hàng ngày: đăng ký/quản lý phòng, đăng ký/quản lý người thuê, tạo/quản lý hợp đồng, tạo/quản lý hoá đơn trong phạm vi được cấp. | Không tự tạo Manager khác, không quản lý tài khoản Landlord. |
| **Người thuê (Tenant)** | **Không phải người dùng app trong Phase 1** — chỉ là hồ sơ dữ liệu (tên, SĐT, CCCD/CMND...) do Landlord/Manager tạo và gắn vào hợp đồng. Nhận hoá đơn & nhắc thanh toán qua SMS/Zalo (một chiều, ngoài app), thanh toán/trao đổi trực tiếp với Landlord ngoài app. | Có thể trở thành người dùng app ở Phase 2 (xem mục 5.2). |

### 3.2 Persona sơ bộ
- **Persona A — Chủ trọ nhỏ lẻ:** quản lý 1 dãy trọ (5-10 phòng), tự làm mọi việc, chưa dùng phần mềm quản lý nào trước đó. Độ tuổi khoảng 50 trở lên, thiết bị chính là smartphone, kênh liên lạc quen dùng là Zalo. Không cần tạo Manager.
- **Persona B — Chủ trọ/chủ đầu tư quy mô vừa:** quản lý nhiều dãy trọ hoặc chung cư mini, cần chia việc cho người quản lý riêng từng dãy trọ (con/nhân viên) qua tài khoản Manager, cần báo cáo doanh thu tổng hợp. Độ tuổi khoảng 40 trở lên.
- **Persona C — Manager (nhân viên/người thân được uỷ quyền):** được Landlord cấp tài khoản để quản lý vận hành 1 hoặc vài dãy trọ cụ thể (ghi số điện nước, tạo hoá đơn, theo dõi thu tiền) mà không cần thấy toàn bộ dữ liệu kinh doanh của Landlord.
- ~~Persona người thuê~~ — không còn là người dùng trực tiếp của app trong Phase 1.

## 4. Giá trị cốt lõi (Value Proposition)
| Đối tượng | Giá trị mang lại |
|---|---|
| Chủ trọ | Quản lý phòng/hợp đồng/người thuê tập trung trên điện thoại; **tự động tính & gửi hoá đơn điện nước hàng tháng qua SMS/Zalo** (chức năng cốt lõi); nhắc đo chỉ số điện nước định kỳ, thu tiền tự động; chia việc an toàn cho Manager theo từng dãy trọ; lưu lịch sử thay đổi hợp đồng (version history) để tránh tranh chấp điều khoản. |
| Manager | Công cụ vận hành gọn nhẹ, chỉ thấy đúng phạm vi (nhà/dãy trọ) được Landlord cấp quyền — không cần truy cập số liệu kinh doanh tổng thể. |
| Người thuê | Nhận hoá đơn rõ ràng, đúng hạn qua SMS/Zalo (không cần cài thêm app trong Phase 1). |

## 5. Phạm vi sản phẩm (Product Scope)

### 5.1 Phase 1 — Cấu trúc app: 5 menu chính (Bottom Navigation)

Phase 1 tổ chức toàn bộ nghiệp vụ quanh **5 menu chính** dành cho Landlord + Manager, thay cho mô hình "8 core flows 2 chiều" ở Version 1. Chức năng quan trọng nhất (core) là **Bill Management — tự động tạo và gửi hoá đơn hàng tháng**. Xem chi tiết luồng ở [USER-FLOWS.md](USER-FLOWS.md) và đặc tả màn hình ở [SCREEN-SPEC.md](SCREEN-SPEC.md).

1. **House/Room Management** — Quản lý Nhà/Dãy trọ (tên, địa chỉ, mô tả, ảnh) & Phòng (số phòng, diện tích, giá tham khảo, tiện ích, phí định kỳ mặc định, ảnh, trạng thái Trống/Đã thuê/Đang sửa chữa).
2. **Tenant Management** — Quản lý "kho" Người thuê (Tenant Pool) dùng chung cho cả Landlord: hồ sơ tên, SĐT, giới tính, ngày sinh, email, CCCD/CMND (2 mặt), ghi chú. Có thể tạo mới ngay trong lúc tạo hợp đồng (không bắt buộc tạo hồ sơ trước).
3. **Contract Management** — Danh sách hợp đồng (filter theo tên nhà, số phòng, tên người thuê, sort tên nhà, số phòng, sắp hết hạn), tạo hợp đồng mới, xem chi tiết hợp đồng kèm **lịch sử phiên bản điều khoản (version history: New/Renewal/Amendment)**, kết thúc hợp đồng kèm đối soát cọc/công nợ (settlement).
4. **Bill Management (core)** — Danh sách hoá đơn (filter/sort theo trạng thái Draft/Sent/Collected/Overdue và theo tháng hoặc kỳ quy định trong hợp đồng), tạo hoá đơn từ chỉ số điện/nước mới nhập và chi phí cố định khác như tiền thuê, tiền dịch vụ,..., xem chi tiết, **tự động gửi hoá đơn cho người thuê qua SMS/Zalo**.
5. **User Setting** — Hồ sơ Chủ nhà (thông tin cá nhân, CCCD, mã số thuế, số tài khoản ngân hàng), quản lý tài khoản Manager (tạo, cấp/thu quyền theo từng Nhà/Dãy trọ), đăng nhập/đăng xuất.

> Xem diagram tóm tắt (entity + luồng theo từng menu): FigJam board `PAuYWdSon7WcPKdRQStoPR` (link nội bộ do Dream chia sẻ, 2026-09-03).

### 5.2 Ngoài phạm vi Phase 1 (Later / Phase 2+)

So với Version 1, danh sách "ngoài phạm vi" mở rộng đáng kể do thu hẹp scope:

- **App/tài khoản Tenant** — đăng nhập, tìm phòng (House/Room Search/Discovery), xem & tự thanh toán hoá đơn trong app, gửi yêu cầu sửa chữa trong app. Trong Phase 1, mọi tương tác với Tenant diễn ra **một chiều qua SMS/Zalo** (gửi hoá đơn, nhắc hạn) hoặc trực tiếp ngoài app.
- **Service Request Management** (yêu cầu sửa chữa/bảo trì/đăng ký lưu trú qua app) — không còn trong 5 menu Phase 1, vì đối tượng gửi yêu cầu (Tenant) không có app.
- **Revenue Report** (báo cáo doanh thu tổng hợp riêng biệt) — không phải 1 trong 5 menu Phase 1; số liệu tổng/đã thu/chưa thu có thể xem tạm qua filter/sort trong Bill Management, báo cáo trực quan đầy đủ dời sang Phase 2.
- Thêm phân quyền chi tiết hơn 2 cấp Landlord/Manager (VD: Manager chỉ xem không sửa).
- Chat trong app giữa các bên.
- Đa ngôn ngữ, cổng thanh toán online (VNPay/Momo/ZaloPay), e-signature.
- Marketplace tìm phòng công khai/SEO/quảng cáo trả phí.

> ✅ **Đã chốt lại (2026-09-03):** Đây là thay đổi phạm vi lớn nhất kể từ khi bắt đầu — Dream đã trao đổi với sếp và quyết định thu hẹp Phase 1 để tập trung làm chắc phần lõi (quản lý + hoá đơn tự động) trước, mở rộng sang Tenant app/Service Request/Revenue Report ở Phase 2 sau khi Phase 1 vận hành ổn định. Xem đầy đủ rationale tại [DECISIONS.md](DECISIONS.md).

## 6. Business model
- Phase 1 hoàn toàn miễn phí
- Phase 2+ sẽ cân nhắc Freemium hoặc trả tiền theo quy mô cho thuê

## 7. Bối cảnh cạnh tranh (Competitive Landscape)
Tham khảo nhanh các sản phẩm cùng phân khúc tại Việt Nam (quản lý nhà trọ/phòng trọ cho thuê):

| Sản phẩm | Điểm mạnh quan sát được | Ghi chú |
|---|---|---|
| **Smartos** | Phần mềm/PMS quản lý BĐS cho thuê, có bản web + app, tính năng khá đầy đủ (quản lý phòng, hợp đồng, hoá đơn, báo cáo). | Nguồn: smartos.space — `NEEDS INPUT`: dùng thử thực tế để so sánh UX. |
| **iTro (Khutro)** | Phần mềm quản lý nhà trọ phổ biến tại VN. | chưa có dữ liệu chi tiết, đang khảo sát thêm tính năng cụ thể. |
| **DigiStay** | chưa có dữ liệu chi tiết, khảo sát thêm tính năng cụ thể. | |

**Định hướng khác biệt hoá đề xuất**:
- Tập trung làm chắc phần lõi: quản lý phòng/hợp đồng + **tự động hoá tạo & gửi hoá đơn** qua kênh người Việt hay dùng (SMS/Zalo), thay vì dàn trải nhiều tính năng 2 chiều ngay từ đầu.
- Phân quyền Manager theo từng dãy trọ — phù hợp chủ trọ quy mô vừa có người phụ quản lý.
- Flow đơn giản, tối thiểu số bước.

## 8. Success Metrics (KPIs)
- Xây dựng được MVP Phase 1 (5 menu) hoàn chỉnh trong thời gian  1 tháng
- Landlord có thể tự vận hành trọn vẹn 1 chu kỳ: đăng ký nhà/phòng → tạo hợp đồng → ghi chỉ số → tạo & gửi hoá đơn → đánh dấu đã thu tiền, không cần hỗ trợ thủ công.

## 9. Giả định & Rủi ro (Assumptions & Risks)

- **Giả định:** Chủ trọ và Manager sẵn sàng cài app; Người thuê **không cần cài app** trong Phase 1 — giảm rủi ro về tỉ lệ tenant chịu cài app đã ghi nhận ở Version 1.
- **Giả định:** Việc ghi chỉ số điện/nước là nhập tay bởi Landlord/Manager (chưa có tích hợp IoT/đồng hồ thông minh).
- **Rủi ro:** Vì Tenant không có app/tài khoản, mọi xác nhận thanh toán phụ thuộc hoàn toàn vào Landlord/Manager tự đánh dấu thủ công — cần UX rõ ràng để tránh quên xác nhận/nhầm trạng thái hoá đơn.
- **Rủi ro:** Gửi SMS/Zalo tự động cần tích hợp bên thứ 3 (Zalo/SMS brandname) — có chi phí & cần pháp lý (xem [BUSINESS-RULES.md](BUSINESS-RULES.md)).
- **Rủi ro:** Phân quyền Manager theo từng Nhà/Dãy trọ cần thiết kế RLS (Row Level Security) cẩn thận để tránh Manager truy cập ngoài phạm vi được cấp.

## 10. Tài liệu liên quan
- [USER-FLOWS](USER-FLOWS.md) - flow nghiệp vụ chính (5 menu)
- [REQUIREMENTS](REQUIREMENTS.md) - yêu cầu chức năng/phi chức năng
- [BUSINESS-RULES](BUSINESS-RULES.md) - quy tắc nghiệp vụ
- [SCREEN-SPEC](SCREEN-SPEC.md) - mô tả màn hình
- [DESIGN](DESIGN.md) - hệ thống thiết kế
- [DECISIONS](DECISIONS.md) - lịch sử quyết định
- [CLAUDE](CLAUDE.md) - hướng dẫn cho dev/Claude Code khi phát triển

# Product Overview — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 3 **Last updated:** 2026-09-08
> **Thay đổi lớn so với Version 2:** Cấu trúc app đổi từ **5 menu → 4 tab**. Vai trò **Chủ nhà (owner)/Quản lý (manager) không còn gắn vào loại tài khoản** — mọi người dùng 1 luồng đăng ký duy nhất, vai trò xác định theo **từng Nhà/Dãy trọ**. Thêm nghiệp vụ ghi chỉ số điện/nước (3 loại), hợp đồng nhiều phòng, và tự động hoá hoá đơn sâu hơn (chu kỳ tiền nhà, phí dịch vụ theo m², mã QR VietQR). Xem [DECISIONS.md](DECISIONS.md) 2026-09-08.

---

## 1. Tóm tắt sản phẩm (Executive Summary)
**Tên thương hiệu:** BizTown
**Tên sản phẩm:** Rent-Manager
**Nền tảng**: Mobile app - Flutter (mobile app, iOS/Android) + Supabase (Postgres DB, Auth, Storage, Edge Functions)

**Description:** BizTown Rent-Manager (Phase 1) là công cụ quản lý nhà cho thuê dành cho người đứng tên (chủ nhà) và người được uỷ quyền vận hành hộ (quản lý) — quản lý nhà/phòng, ghi chỉ số điện nước, người thuê, hợp đồng (kể cả hợp đồng nhiều phòng), và **tự động tạo & gửi hoá đơn điện nước hàng tháng kèm mã QR thanh toán**. Người thuê (Tenant) trong Phase 1 **không cài app, không có tài khoản** — chỉ là hồ sơ dữ liệu trong hệ thống và là người nhận hoá đơn/nhắc thanh toán qua SMS/Zalo.

## 2. Vấn đề cần giải quyết (Problem Statement)
- Chủ nhà hiện quản lý phòng/khách thuê thủ công qua Excel, sổ tay, hoặc nhóm Zalo — dễ sai sót khi tính tiền điện nước, quên nhắc thu tiền, khó theo dõi dòng tiền tổng thể khi có nhiều phòng/nhiều dãy trọ.
- **Ghi chỉ số điện/nước và tính hoá đơn là 2 việc tách rời nhau về thời gian trong thực tế** (đi ghi số cả nhà một lượt, tính hoá đơn sau) — công cụ nhập chỉ số ngay lúc tạo hoá đơn (như Version 2) không khớp cách làm thật, và khi đổi khách giữa tháng dễ tính nhầm tiền điện/nước của khách cũ sang khách mới nếu không có đủ 3 loại chỉ số (định kỳ, nhận phòng, trả phòng) nối liền nhau.
- Chủ nhà quản lý nhiều dãy trọ, đôi khi đứng tên người khác trong gia đình (vợ, con), thường cần người phụ giúp theo dõi, nhưng mô hình "1 tài khoản = 1 vai trò cố định" không biểu diễn được ca một người vừa là chủ ở nhà này vừa là người quản lý hộ ở nhà khác.
- Việc tính hoá đơn điện nước hàng tháng, thu tiền theo tầng/phòng ghép, và gửi cho người thuê tốn nhiều thời gian thủ công, dễ sai số.
- Các phần mềm hiện có trên thị trường (Smartos, iTro/Khutro, DigiStay...) thường thiên về web-based cho chủ trọ, chưa tối ưu cho việc quản lý nhanh trên điện thoại. (Chưa có số liệu phân tích thị trường, research thực tế)

> **Ghi chú phạm vi:** Bài toán "người thuê cần kênh minh bạch xem hoá đơn/gửi yêu cầu trong app" được **dời sang Phase 2+** — xem mục 5.2.

## 3. Đối tượng người dùng (Target Users)

### 3.1 Vai trò chính (Roles) — vai trò gắn theo TỪNG Nhà/Dãy trọ, không gắn vào tài khoản

Phase 1 chỉ có **1 loại tài khoản** (`tb_user`), đăng ký qua 1 luồng SĐT + OTP duy nhất. Vai trò **Chủ nhà (owner)** hay **Quản lý (manager)** được xác định **riêng cho từng Nhà/Dãy trọ** (`tb_user_house_access`) — cùng 1 tài khoản có thể vừa là chủ ở nhà mình tự tạo, vừa là quản lý ở nhà của một chủ trọ khác (kể cả không quen biết), xem [BUSINESS-RULES](BUSINESS-RULES.md) mục 4.

| Vai trò (theo từng nhà) | Mô tả | Ghi chú |
|---|---|---|
| **Chủ nhà (`owner`)** | Tự động có được khi tạo 1 Nhà/Dãy trọ mới. Toàn quyền trên nhà đó: sửa thông tin nhà/chủ sở hữu hiển thị/tài khoản nhận tiền, mời/thu hồi quyền quản lý, và mọi nghiệp vụ vận hành. | 1 tài khoản có thể là owner của nhiều nhà. |
| **Quản lý (`manager`)** | Được 1 chủ nhà mời bằng số điện thoại vào 1 hoặc nhiều nhà cụ thể. Thực hiện nghiệp vụ vận hành hàng ngày (phòng, người thuê, hợp đồng, ghi chỉ số, hoá đơn) trong phạm vi được cấp — không sửa được thông tin chủ sở hữu/tài khoản nhận tiền, không mời/thu hồi quyền của người khác. | Không tự tạo quyền quản lý cho ai khác. |
| **Người thuê (Tenant)** | **Không phải người dùng app** — chỉ là hồ sơ dữ liệu (tên, SĐT, CCCD/CMND...) do người có quyền (owner/manager) tạo và gắn vào hợp đồng. Nhận hoá đơn (kèm mã QR) & nhắc thanh toán qua SMS/Zalo (một chiều, ngoài app). | Có thể trở thành người dùng app ở Phase 2. |

### 3.2 Persona sơ bộ
- **Persona A — Chủ nhà nhỏ lẻ:** quản lý 1 dãy trọ (5-10 phòng), tự làm mọi việc với vai trò `owner`. Độ tuổi khoảng 50 trở lên, thiết bị chính là smartphone, kênh liên lạc quen dùng là Zalo. Không cần mời ai làm quản lý.
- **Persona B — Chủ nhà quy mô vừa, đứng tên nhiều nhà khác nhau trong gia đình:** ví dụ đứng tên 1 nhà, vợ đứng tên 1 nhà, con gái đứng tên 1 nhà — nhưng cùng 1 người quản lý vận hành (con gái) được mời làm `manager` ở cả 3 nhà dù mỗi nhà có "chủ sở hữu hiển thị" khác nhau. Độ tuổi khoảng 40 trở lên.
- **Persona C — Người quản lý (con/nhân viên/người thân được uỷ quyền):** được 1 hoặc nhiều chủ nhà mời làm `manager` cho 1 vài nhà cụ thể — có thể đồng thời là `manager` cho những chủ nhà hoàn toàn không liên quan tới nhau, và cũng có thể tự đứng ra làm `owner` một nhà của riêng mình bằng cùng 1 tài khoản.
- ~~Persona người thuê~~ — không còn là người dùng trực tiếp của app trong Phase 1.

## 4. Giá trị cốt lõi (Value Proposition)
| Đối tượng | Giá trị mang lại |
|---|---|
| Chủ nhà | Quản lý phòng/hợp đồng/người thuê tập trung trên điện thoại; ghi chỉ số điện nước tách biệt khỏi lúc tạo hoá đơn, đúng thực tế vận hành; hợp đồng gộp nhiều phòng cho 1 người đại diện thuê chung tầng; **tự động tính & gửi hoá đơn kèm mã QR chuyển khoản qua SMS/Zalo hàng tháng** (chức năng cốt lõi); chu kỳ thu tiền nhà cấu hình linh hoạt (VD 2 tháng/lần) độc lập với chu kỳ điện nước; mời người quản lý bằng số điện thoại mà không cần tạo tài khoản hộ; lưu lịch sử thay đổi hợp đồng để tránh tranh chấp điều khoản. |
| Quản lý | Công cụ vận hành gọn nhẹ, chỉ thấy đúng phạm vi nhà được cấp quyền — có thể nhận nhiều lời mời từ nhiều chủ nhà không liên quan tới nhau bằng cùng 1 tài khoản duy nhất. |
| Người thuê | Nhận hoá đơn rõ ràng, đúng hạn qua SMS/Zalo kèm mã QR chuyển khoản sẵn sàng quét, không cần cài thêm app. |

## 5. Phạm vi sản phẩm (Product Scope)

### 5.1 Phase 1 — Cấu trúc app: 4 tab chính (Bottom Navigation)

Version 3 đổi cấu trúc từ "5 menu" (Version 2) sang **4 tab**, giảm số lần bấm và đưa Hoá đơn thành 1 tab riêng vì đây là chức năng cốt lõi. Xem chi tiết luồng ở [USER-FLOWS.md](USER-FLOWS.md) và đặc tả màn hình ở [SCREEN-SPEC.md](SCREEN-SPEC.md).

1. **Home** — Quản lý Nhà/Dãy trọ & Phòng (tên, địa chỉ, loại nhà, ảnh, chủ sở hữu hiển thị, tài khoản nhận tiền; số phòng, diện tích m², giá tham khảo, tiện ích, trạng thái) **+ nghiệp vụ ghi chỉ số điện/nước định kỳ hàng tháng** cho mọi phòng.
2. **Tenant & Contract** — Chuyển qua lại bằng segmented control giữa "kho" Người thuê (Tenant Pool) và Hợp đồng: tạo hợp đồng **gồm 1 hoặc nhiều phòng** (chặn bằng chỉ số nhận phòng bắt buộc), gia hạn/sửa điều khoản (2 màn tách riêng), lịch sử phiên bản, xem trước lịch hoá đơn sắp tới, kết thúc hợp đồng (chặn bằng chỉ số trả phòng bắt buộc, đối soát cọc/công nợ).
3. **Bills (core)** — Tạo hoá đơn **đơn lẻ hoặc hàng loạt** (theo cả 1 Nhà/Dãy trọ + 1 kỳ), tự động đọc lại chỉ số đã ghi, tự tính tiền nhà theo chu kỳ cấu hình được, phí dịch vụ theo m², sinh **mã QR VietQR/NAPAS-247**, gửi qua SMS/Zalo, danh sách hoá đơn nhóm theo nhà → hợp đồng với chip kỳ tương lai "Scheduled".
4. **Profile** — Hồ sơ cá nhân, tài khoản ngân hàng nhận tiền theo từng nhà, đổi mật khẩu, mời/thu hồi quyền quản lý theo từng Nhà/Dãy trọ bằng số điện thoại (không tạo tài khoản hộ), đăng nhập/đăng xuất.

> Xem diagram tóm tắt (entity + luồng theo cấu trúc mới): FigJam board `PAuYWdSon7WcPKdRQStoPR`, khu vực "Version 3 — CURRENT" (Dream, cập nhật 07-08/09/2026).

### 5.2 Ngoài phạm vi Phase 1 (Later / Phase 2+)

- **App/tài khoản Tenant** — đăng nhập, tìm phòng (House/Room Search/Discovery), xem & tự thanh toán hoá đơn trong app, gửi yêu cầu sửa chữa trong app. Mọi tương tác với Tenant diễn ra **một chiều qua SMS/Zalo** hoặc trực tiếp ngoài app.
- **Service Request Management** (yêu cầu sửa chữa/bảo trì qua app).
- **Revenue Report** (báo cáo doanh thu tổng hợp riêng biệt, biểu đồ/xuất file) — số liệu tổng/đã thu/chưa thu xem tạm qua filter trong Bills.
- **Thanh toán online trong app** — Phase 1 chỉ sinh mã QR chuyển khoản tĩnh (VietQR/NAPAS-247), không xử lý giao dịch thật trong app.
- **Đăng ký/quản lý công tơ dạng thiết bị, đọc số tự động qua IoT** — Phase 1 chỉ nhập tay, 1 phòng = 1 công tơ ảo gắn trực tiếp vào phòng.
- Nhiều Tenant đại diện trên 1 hợp đồng (ở ghép nhiều người cùng đứng tên).
- **Đổi danh sách phòng của 1 hợp đồng đang Active** (thêm/bớt phòng qua Amendment) — bỏ khỏi Phase 1, 09/09/2026 (khớp thực tế Figma, không có UI cho việc này). Đổi phòng thuê xử lý bằng kết thúc hợp đồng cũ + tạo hợp đồng mới. Xem `BR-CTR-07`.
- Chat trong app giữa các bên.
- e-signature.
- Marketplace tìm phòng công khai/SEO/quảng cáo trả phí.
- ~~Đa ngôn ngữ~~ — **đổi hướng 09/09/2026: không còn ngoài phạm vi**, app hỗ trợ 3 ngôn ngữ (English / Tiếng Việt / 한국어) ngay từ Phase 1, chọn ngay tại màn Profile (P-01, inline picker) — ngôn ngữ khác để Phase 2. Xem `NFR-02`/`FR-MGR-05` trong [REQUIREMENTS](REQUIREMENTS.md). Bản thiết kế Figma vẫn dựng bằng tiếng Anh làm chuẩn.

## 6. Business model
- Phase 1 hoàn toàn miễn phí
- Phase 2+ sẽ cân nhắc Freemium hoặc trả tiền theo quy mô cho thuê

## 7. Bối cảnh cạnh tranh (Competitive Landscape)
Tham khảo nhanh các sản phẩm cùng phân khúc tại Việt Nam (quản lý nhà trọ/phòng trọ cho thuê):

| Sản phẩm | Điểm mạnh quan sát được | Ghi chú |
|---|---|---|
| **Smartos** | Phần mềm/PMS quản lý BĐS cho thuê, có bản web + app, tính năng khá đầy đủ. | Nguồn: smartos.space — `NEEDS INPUT`: dùng thử thực tế để so sánh UX. |
| **iTro (Khutro)** | Phần mềm quản lý nhà trọ phổ biến tại VN. | chưa có dữ liệu chi tiết. |
| **DigiStay** | chưa có dữ liệu chi tiết. | |

**Định hướng khác biệt hoá đề xuất**:
- Tập trung làm chắc phần lõi: quản lý phòng/hợp đồng + **tự động hoá tạo & gửi hoá đơn kèm QR** qua kênh người Việt hay dùng (SMS/Zalo).
- Mô hình phân quyền theo TỪNG nhà (không phải theo tài khoản) — phù hợp thực tế nhiều chủ trọ đứng tên khác nhau trong gia đình nhưng dùng chung 1 người vận hành.
- Ghi chỉ số điện/nước tách biệt khỏi tạo hoá đơn, đúng quy trình vận hành thật ngoài đời — chặn được lỗi tính tiền gấp đôi khi đổi khách giữa tháng.
- Flow đơn giản, tối thiểu số bước.

## 8. Success Metrics (KPIs)
- Xây dựng được MVP Phase 1 (4 tab, 32 màn — chọn ngôn ngữ inline tại P-01, không thêm màn riêng, cập nhật 09/09/2026) hoàn chỉnh trong thời gian hợp lý.
- Chủ nhà có thể tự vận hành trọn vẹn 1 chu kỳ: đăng ký nhà/phòng → ghi chỉ số định kỳ → tạo hợp đồng (kể cả nhiều phòng) → tạo & gửi hoá đơn hàng loạt kèm QR → đánh dấu đã thu tiền, không cần hỗ trợ thủ công.
- Đổi khách giữa tháng không phát sinh lỗi tính tiền điện/nước gấp đôi (kiểm chứng bằng kịch bản Mr. Han — xem [`시뮬레이션 케이스 (Mr.Han).md`](시뮬레이션%20케이스%20(Mr.Han).md)).

## 9. Giả định & Rủi ro (Assumptions & Risks)

- **Giả định:** Chủ nhà và người quản lý sẵn sàng cài app; Người thuê **không cần cài app** trong Phase 1.
- **Giả định:** Việc ghi chỉ số điện/nước là nhập tay (chưa có tích hợp IoT/đồng hồ thông minh).
- **Rủi ro:** Vì Tenant không có app/tài khoản, mọi xác nhận thanh toán phụ thuộc hoàn toàn vào người có quyền tự đánh dấu thủ công.
- **Rủi ro:** Gửi SMS/Zalo tự động cần tích hợp bên thứ 3 (Zalo/SMS brandname) — có chi phí & cần pháp lý.
- **Rủi ro:** Mô hình phân quyền theo từng nhà (không cache vai trò vào session) đòi hỏi mọi màn hình phải luôn biết "đang thao tác trên nhà nào" — dễ làm sai nếu dev không nắm rõ, cần RLS (Row Level Security) thiết kế cẩn thận (xem [BUSINESS-RULES.md](BUSINESS-RULES.md) mục 7).
- **Rủi ro:** Nghiệp vụ ghi chỉ số bắt buộc tại 2 mốc hợp đồng (nhận/trả phòng) có thể bị người dùng cảm thấy vướng nếu UX không rõ ràng lý do — cần giải thích ngay tại chỗ (không chỉ chặn nút mà không rõ nguyên nhân).

## 10. Tài liệu liên quan
- [USER-FLOWS](USER-FLOWS.md) - flow nghiệp vụ chính (4 tab)
- [REQUIREMENTS](REQUIREMENTS.md) - yêu cầu chức năng/phi chức năng
- [BUSINESS-RULES](BUSINESS-RULES.md) - quy tắc nghiệp vụ
- [SCREEN-SPEC](SCREEN-SPEC.md) - mô tả màn hình (32 màn)
- [DATABASE](DATABASE.md) - schema dữ liệu (12 bảng, tiền tố `tb_`)
- [DESIGN](DESIGN.md) - hệ thống thiết kế
- [DECISIONS](DECISIONS.md) - lịch sử quyết định
- [CLAUDE](CLAUDE.md) - hướng dẫn cho dev/Claude Code khi phát triển

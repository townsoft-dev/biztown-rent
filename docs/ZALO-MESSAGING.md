# ZALO-MESSAGING.md — Gửi tin nhắn Zalo OA (Tenant + xác thực tài khoản)

> **Trạng thái tài liệu:** Version 3 — **Last updated:** 2026-09-16 (Dream, qua Claude/Cowork)
> Tài liệu này gộp 3 luồng dùng chung hạ tầng Zalo OA (`_shared/zalo.ts`, `tb_zalo_token`):
> - **Luồng A (chào mừng hợp đồng, gửi Tenant)** — template đã duyệt, có thể code. Vẫn phụ thuộc câu hỏi rộng hơn "có tiếp tục dùng Zalo OA hay không" — xem ghi chú Luồng C.
> - **Luồng B (hoá đơn hàng tháng, gửi Tenant)** — **CHƯA CHỐT phương án**, đang nghiên cứu.
> - **Luồng C (OTP xác thực tài khoản — đăng ký/quên mật khẩu, gửi App user)** — **⏸️ TẠM HOÃN (16/09/2026, đảo lại quyết định "ĐÃ CHỐT" ngày 2026-09-15):** ZBS xác nhận rẻ hơn eSMS, nhưng Dream đang cân nhắc lại có nên tiếp tục dùng Zalo OA cho hệ thống hay không — chưa chốt. **Cho tới khi có quyết định về OA: kênh gửi OTP (tạo tài khoản + quên mật khẩu) tiếp tục ưu tiên SMS qua eSMS như hiện tại, không đổi.** Xem Đợt 50 trong `DECISIONS.md`.
>
> Tài liệu nghiên cứu chi tiết hơn cho Luồng B (bảng giá, chính sách Zalo, so sánh chi phí từng phương án) nằm ở Claude Project brainstorm riêng của Dream ("BizTown - Rent-Manager / Brainstorm"), KHÔNG nằm trong repo này: `zalo-feasibility-review.md`. Tài liệu ở đây trích lại các điểm liên quan trực tiếp tới việc code, không lặp lại toàn bộ.

## 0. Hạ tầng Zalo đã có trong repo

- `supabase/functions/_shared/zalo.ts` — `sendZns()` + tự làm mới access token qua refresh token. **Đã dựng sẵn hạ tầng, CHƯA gọi ở đâu trong app** (cần `templateId` thật — nay Luồng A và Luồng C đã có, xem mục 1 và 3).
- Migration `20260915100000_tb_zalo_token.sql` — bảng `tb_zalo_token` (1 dòng `id='default'`) lưu access/refresh token, đã seed token thật (xem `DECISIONS.md` Đợt 41).
- `supabase/functions/send-notification/index.ts` — hiện chỉ gửi Tenant qua SMS (eSMS), nhánh Zalo còn để `// TODO`.
- 3 secret tĩnh đã set qua `supabase secrets set`: `ZALO_OA_ID`, `ZALO_APP_ID`, `ZALO_APP_SECRET`.
- ⚠️ **Cần verify trước khi dùng cho Luồng A/C:** endpoint hiện tại trong `sendZns()` là `https://business.openapi.zalo.me/message/template`. Ưu đãi giá UID so với SĐT chỉ áp dụng cho hệ **ZBS Template Message** (không áp dụng cho ZNS cổ điển). Cả 2 template (636121, 636478) đều là **ZBS**. Cần xác nhận endpoint/payload hiện tại đúng chuẩn ZBS trước khi bật thật.
- ⚠️ **Type mismatch cần sửa (Luồng A):** `sendZns()` khai báo `templateData: Record<string, string>` (mọi giá trị đều là string). Nhưng template 636121 có 2 tham số kiểu **number** (`han_thanh_toan`, `tien_thue`) — xem ví dụ code ở mục 1.4 dùng số nguyên không có dấu ngoặc kép (`"tien_thue": 100`). Cần kiểm tra thực tế Zalo API có bắt buộc đúng kiểu JSON theo từng tham số hay chấp nhận string cho tất cả — nếu bắt buộc đúng kiểu, phải sửa lại signature `sendZns()` (ví dụ `templateData: Record<string, string | number>`). Template 636478 (Luồng C) chỉ có tham số string — không bị lỗi này.
- `sendZns()` hiện chỉ nhận `phone`, chưa có tham số gửi qua `uid`. Luồng B (khi đã có UID) sẽ cần mở rộng hàm này — chưa làm ở đợt này.
- **Định dạng số điện thoại truyền vào `sendZns()`:** comment trong `zalo.ts` ghi "dạng 84xxxxxxxxx". Supabase Auth Hook (Luồng C) trả SĐT dạng E.164 có dấu `+` (`+84xxxxxxxxx`) — cần cắt dấu `+` (không cắt cả `+84` như `toLocalVnPhone()` của eSMS, vì Zalo cần giữ lại `84`) trước khi gọi `sendZns()`. Kiểm tra đúng format này ở mọi luồng trước khi code, tránh copy nhầm hàm `toLocalVnPhone()` của eSMS (hàm đó ra số dạng `0xxxxxxxxx`, SAI cho Zalo).

---

## 1. Luồng A — Tin chào mừng hợp đồng mới (mời quan tâm OA)

### 1.1 Mục đích & khi nào gửi

Gửi 1 lần ngay sau khi 1 hợp đồng mới được tạo thành công (phiên bản đầu tiên, `change_reason = 'New'`), tới **số điện thoại Tenant** lấy từ hợp đồng/hồ sơ Tenant. Mục đích kép:

1. Báo Tenant hợp đồng đã khởi tạo, kèm thông tin chính (phòng, tiền thuê, ngày hiệu lực...).
2. **Mời Tenant quan tâm trang OA chính thức** (nút CTA cuối tin) — vì đây là điều kiện để các tin sau này (đặc biệt Luồng B — hoá đơn hàng tháng) có thể gửi qua **UID** thay vì SĐT, giảm chi phí mỗi tin từ ~300đ xuống ~210đ (giá niêm yết trực tiếp trên mẫu, xem mục 1.2).

### 1.2 Template đã duyệt

| Trường | Giá trị |
|---|---|
| Tên mẫu | BizTown Rent-Manager : Chúc mừng hợp đồng |
| **ID mẫu ZBS** | **636121** |
| Loại mẫu | Mẫu tuỳ chỉnh (ZBS Template Message) |
| OA gửi | Townsoft Vina - BizTown |
| Ứng dụng | BizTown Rent Manager |
| Trạng thái | Đã duyệt |
| Mục đích gửi | Giao dịch |
| Đơn giá gửi qua SĐT | 300 đ/tin |
| Đơn giá gửi qua UID | 210 đ/tin |
| Ztime(s) | 7200 |

### 1.3 Nội dung hiển thị (đã duyệt — không tự sửa chữ, sửa phải submit duyệt lại)

**Tiêu đề:** "Hợp đồng phòng \<ten_phong> đã khởi tạo thành công"

**Văn bản:** "Chào \<ten_nguoi_thue>, hợp đồng thuê phòng tại \<ten_nha_tro> đã được tạo thành công. Thông tin chi tiết ở bảng bên dưới. Để tự động nhận hoá đơn hàng tháng và các thông báo khác, vui lòng kết nối với ứng dụng của chúng tôi."

**Bảng:**

| Nhãn (chữ cố định) | Nội dung (tham số) |
|---|---|
| Mã hợp đồng | `<ma_hop_dong>` |
| Phòng | `<ten_phong>` |
| Nhà | `<ten_nha_tro>` |
| Ngày bắt đầu | `<ngay_bat_dau>` |
| Ngày kết thúc | `<ngay_ket_thuc>` |
| Tiền thuê hàng tháng | `<tien_thue>` VND |
| Ngày thanh toán | Ngày `<han_thanh_toan>` hàng tháng |

**Nút:** 1 nút CTA duy nhất — "OA Townsoft Vina - BizTown" (dẫn tới trang OA để Tenant tự bấm "Quan tâm").

### 1.4 Bảng tham số — mapping với database thực tế của app

**Nguồn Tenant/Contract:** `tb_contract.tenant_id → tb_tenant`; version hiện hành qua `tb_contract.current_version_id → tb_contract_version`; phòng/nhà qua `tb_contract_room → tb_room → tb_house` (nhà là duy nhất cho 1 hợp đồng, đảm bảo bởi `BR-CTR-13`: `tenant.house_id` phải khớp `house_id` của mọi phòng trong hợp đồng).

| Tham số (đã duyệt) | Kiểu Zalo | Field DB thực tế | Ghi chú / việc cần chốt trước khi code |
|---|---|---|---|
| `<ten_nguoi_thue>` | string (30) | `tb_tenant.full_name` | OK, có sẵn |
| `<ten_phong>` | string (30) | `tb_room.room_no` (qua `tb_contract_room`) | ⚠️ **1 hợp đồng có thể gồm NHIỀU phòng** (`tb_contract_room` là bảng N-N). Mẫu chỉ có 1 ô `<ten_phong>` cho 1 phòng. **NEEDS INPUT:** ghép danh sách (`"203, 204"`) hay chỉ gửi tin này khi hợp đồng 1 phòng, hay lấy phòng đầu tiên? Chưa có quy tắc — không tự quyết khi code. |
| `<ten_nha_tro>` | string (30) | `tb_house.name` | OK, có sẵn |
| `<ma_hop_dong>` | string (30), vd `HD-20260915-001` | **Không có field tương ứng** | ⚠️ **Gap thật:** `tb_contract` chỉ có `id` (uuid), không có mã hiển thị dạng `HD-...`. **NEEDS INPUT — cần Dream/dungtv chốt:** (a) thêm cột mới (vd `tb_contract.display_code text`) + quy tắc sinh mã (theo ví dụ Zalo duyệt: `HD-YYYYMMDD-NNN` — theo ngày tạo + số thứ tự, cần chốt phạm vi đếm: toàn hệ thống hay theo từng Nhà?), hay (b) dùng tạm 8 ký tự đầu của `id` (uuid) làm mã. Không tự chọn — đụng tới schema/migration mới. |
| `<ngay_bat_dau>` | date (20), `dd/mm/yyyy` | `tb_contract_version.start_date` (version hiện hành) | OK, có sẵn — format lại theo `dd/mm/yyyy` giống `formatDdMmYyyy()` trong `_shared/invoice_message.ts` |
| `<ngay_ket_thuc>` | date (20), `dd/mm/yyyy` | `tb_contract_version.end_date` (version hiện hành) | OK, có sẵn |
| `<tien_thue>` | number (20) | `tb_contract_version.monthly_rent` | OK, có sẵn — đây là **tiền thuê nguyên hợp đồng**, không chia theo phòng |
| `<han_thanh_toan>` | number (20), giá trị 1–31 | `tb_contract_version.payment_due_day_of_month` | OK, có sẵn |

**Ví dụ `template_data` gửi API** (theo đúng kiểu dữ liệu Zalo yêu cầu — 2 field number KHÔNG bọc chuỗi):

```json
{
  "ten_phong": "Phòng 203",
  "ten_nguoi_thue": "Nguyễn Văn A",
  "ten_nha_tro": "Nhà trọ 28/144 Mai Dịch",
  "ma_hop_dong": "HD-20260915-001",
  "ngay_bat_dau": "15/09/2026",
  "ngay_ket_thuc": "14/09/2027",
  "tien_thue": 5200000,
  "han_thanh_toan": 5
}
```

### 1.5 Kênh gửi & số điện thoại

- Luôn gửi qua **SĐT** (`tb_tenant.phone`) — đây là tin đầu tiên, Tenant chắc chắn chưa có UID.
- Lấy số điện thoại theo đúng pattern đã dùng ở nơi khác trong code (`InvoiceRepository.sendSms()`: `invoice.contractId → contract.tenantId → tenant.phone`) — không có sẵn `phone` snapshot trên `tb_contract`.
- Format số điện thoại: xem lưu ý chung ở mục 0 (khác convention `toLocalVnPhone()` của eSMS).

### 1.6 Gap cần chốt để tối ưu chi phí Luồng B sau này

Mục đích Dream nêu ("mời quan tâm để sau đó đổi từ SĐT sang UID, giảm chi phí") **chưa thể tự động hoá được** vì DB hiện **không có chỗ lưu UID hay thời điểm Tenant follow/tương tác OA gần nhất** — không tìm thấy field nào trong `tb_tenant` hay bảng khác. Cần bổ sung (đề xuất, **NEEDS INPUT** — chưa quyết):

- `tb_tenant.zalo_uid` (text, null) — UID Zalo của Tenant, có sau khi follow.
- `tb_tenant.zalo_followed_at` hoặc `zalo_last_interaction_at` (timestamptz, null).
- Cách cập nhật 2 field trên: cần xác nhận Zalo có API tra UID theo SĐT sau khi Tenant follow, hay chỉ nhận được qua webhook "user follow OA" — **chưa có nghiên cứu**, cần làm trước khi code phần chọn kênh gửi (UID ưu tiên, fallback SĐT) cho Luồng B.

### 1.7 Việc cần làm để bật thật (tóm tắt)

- [ ] Xác nhận endpoint/kiểu dữ liệu ZBS đúng chuẩn (mục 0) trước khi gọi `sendZns()`.
- [ ] Chốt cách lấy `<ma_hop_dong>` (mục 1.4) — cần quyết định schema trước.
- [ ] Chốt cách xử lý `<ten_phong>` khi hợp đồng nhiều phòng (mục 1.4).
- [ ] Chốt kiến trúc: gọi `sendZns()` ở đâu trong luồng tạo hợp đồng (Edge Function riêng hay thêm nhánh `channel: "zalo"` vào `send-notification`) — theo đúng tinh thần `CLAUDE.md` ("không tự chọn kiến trúc lớn khi `ARCHITECTURE.md` chưa có").
- [ ] Bổ sung field lưu UID/tương tác Tenant (mục 1.6) nếu muốn tối ưu chi phí Luồng B về sau.
- [ ] Sau khi chốt các mục trên, ghi quyết định vào `DECISIONS.md` + cập nhật `BUSINESS-RULES.md` (thêm rule `BR-NOTI` mới cho tin chào mừng hợp đồng — hiện mục 5 chưa có rule nào mô tả luồng này).

---

## 2. Luồng B — Thông báo hoá đơn hàng tháng: vướng mắc hiện tại & phương án đang cân nhắc

> ⚠️ **CHƯA CHỐT.** Mục này chỉ ghi lại hiện trạng vướng mắc và các phương án Dream đang nghiên cứu (2026-09-15) — **không code theo mục này** cho tới khi có quyết định rõ ràng + entry mới trong `DECISIONS.md`. `BUSINESS-RULES.md` `BR-NOTI-01` hiện đang ghi "SMS/Zalo (Tenant, kèm mã QR)" — câu này **đã lỗi thời/chưa phản ánh đúng vướng mắc dưới đây**, cần rà lại sau khi Luồng B được chốt.

### 2.1 Vướng mắc hiện tại (theo Dream, 2026-09-15)

1. **Template ZBS không hỗ trợ mã QR động** (thay đổi theo từng lần gửi, mỗi hoá đơn 1 QR khác nhau). Bổ sung từ nghiên cứu trước (`zalo-feasibility-review.md`): đây thực chất là vấn đề **chính sách**, không phải giới hạn kỹ thuật — Zalo cấm hẳn QR/Barcode trong khối hình ảnh của mẫu ZNS/ZBS Template (API Upload ảnh vẫn chạy được, nhưng nội dung không qua được duyệt / rủi ro bị khoá mẫu-tài khoản nếu lọt qua).
2. **Không hỗ trợ gửi tới/qua tài khoản không thuộc sở hữu của chủ OA** — theo Dream nêu. Khớp với 1 điểm đã research trước: các loại nút CTA "mở URL" của ZBS chỉ được tính phí ưu đãi (hoặc được duyệt dễ hơn) khi tài sản đích (tên miền, Mini App) **đứng tên/thuộc sở hữu chính doanh nghiệp đã xác thực OA** — nếu khác chủ sở hữu (tên miền không khớp tên OA, ứng dụng không phải của doanh nghiệp) sẽ bị xếp nhóm phí cao hơn hoặc khó duyệt hơn.
3. **Tin tư vấn** cho phép gửi kèm hình ảnh (không bị cấm QR) nhưng chỉ gửi được khi còn trong **cửa sổ tương tác 7 ngày gần nhất** giữa Tenant và OA — trong khi hoá đơn gửi **định kỳ 1 tháng/lần**, nên phần lớn Tenant sẽ không có tương tác hợp lệ đúng lúc hệ thống cần gửi.
4. **Các mẫu ZBS thử tạo (có gắn QR) đều bị Zalo từ chối duyệt** trên thực tế — khớp đúng với vướng mắc #1.

### 2.2 Các phương án đang cân nhắc (Dream đề xuất, chưa chốt)

**Phương án 1 — Tách 2 bước: mẫu ZBS (số tiền/tên phòng, CTA "Chi tiết") → tin tư vấn tự động (kèm QR) khi Tenant bấm.**

- Ưu điểm: tin mẫu rẻ, không cần hạ tầng ngoài Zalo.
- Nhược điểm (Dream đã nêu): Tenant không bấm "Chi tiết" → không nhận được QR.
- ⚠️ Rủi ro kỹ thuật bổ sung (từ `zalo-feasibility-review.md`): **chưa có xác nhận chính thức từ Zalo** rằng bấm nút trong tin ZBS có tính là "tương tác" hợp lệ để mở lại cửa sổ 7 ngày cho tin tư vấn. Nếu giả định này sai, kể cả khi Tenant bấm "Chi tiết" hệ thống vẫn có thể không gửi được tin tư vấn — cần test thật (gửi thử cho chính số của mình, bấm nút, thử gọi tin tư vấn ngay sau) trước khi chọn phương án này làm chính.

**Phương án 2 — CTA điều hướng sang URL Mini App trong Zalo — không tính thêm phí, nhưng phải xây thêm 1 Mini App.**

- Ưu điểm: theo bảng giá đã research trước, nút "Đến Mini App của chính doanh nghiệp" không có phụ phí riêng — rẻ nhất về lâu dài trong các phương án dùng CTA mở URL.
- Nhược điểm (Dream đã nêu): tốn công/chi phí xây Mini App ban đầu.
- Điều kiện: Mini App phải đứng tên/thuộc sở hữu chính OA — khớp với vướng mắc #2 ở trên.

**Phương án 3 — CTA điều hướng sang URL tên miền khác — chi phí cao, chưa chắc tạo được ảnh QR riêng từng Tenant (đang lưu URL tĩnh).**

- Ưu điểm: không cần xây Mini App, chỉ cần 1 trang web.
- Nhược điểm (Dream đã nêu): phí cao hơn nếu tên miền khác tên OA; đang lưu URL tĩnh nên chưa chắc hiển thị đúng QR/số tiền riêng từng Tenant.
- Gợi ý cần thử trước khi chọn phương án này (từ research trước): Zalo hỗ trợ **truyền tham số vào URL của nút CTA** (khai báo dạng `<mã_hoá_đơn>` giống tham số Tiêu đề/Bảng) — nếu dùng URL có tham số trỏ tới trang do BizTown tự dựng (tự sinh QR theo từng hoá đơn) thay vì URL tĩnh cố định, sẽ giải quyết được vướng mắc "chưa chắc tạo được QR riêng từng người". Cũng nên thử loại CTA "Đến trang tra cứu hoá đơn điện tử" (nếu Zalo còn cung cấp loại này) trước khi chọn loại "Đến trang web/Mini App khác" — đúng use case hơn và có thể rẻ hơn.

**Phương án 4 — Đổi hướng từ OA sang chatbot cá nhân.**

- Theo đánh giá của Dream: cách làm cá nhân, không phù hợp sản phẩm thương mại — loại bỏ, ghi lại để không cân nhắc lại về sau.

### 2.3 Phương án khác đã có trong nghiên cứu trước (tham khảo thêm, không phải đề xuất thay thế 4 phương án trên)

Từ `zalo-feasibility-review.md`: bỏ hẳn QR dạng ảnh, chỉ giữ thông tin chuyển khoản dạng **chữ** (tên ngân hàng/STK/tên chủ tài khoản) trong bảng của mẫu ZBS — không vi phạm chính sách gì, rẻ nhất, không phụ thuộc tương tác 7 ngày hay quyền sở hữu URL. Đổi lại kém tiện hơn (Tenant tự nhập STK vào app ngân hàng thay vì quét QR). Nêu lại để Dream cân nhắc khi so sánh — không tự thêm thành "phương án 5" chính thức.

### 2.4 Trạng thái & việc cần làm tiếp

- [ ] **Chưa chốt phương án nào** — không code Luồng B tới khi có quyết định.
- [ ] Nếu vẫn cân nhắc Phương án 1: test thật giả thuyết "bấm nút ZBS có mở cửa sổ tin tư vấn 7 ngày không".
- [ ] Nếu chọn Phương án 2 hoặc 3: cần quyết định kiến trúc trang/Mini App hiển thị QR (ngoài phạm vi tài liệu này) + đổi URL tĩnh hiện có sang URL có tham số động theo từng hoá đơn.
- [ ] Sau khi chốt: cập nhật `BUSINESS-RULES.md` (rule mới hoặc sửa `BR-NOTI-01` cho khớp thực tế) và thêm entry quyết định vào `DECISIONS.md`.

---

## 3. Luồng C — OTP xác thực tài khoản (đăng ký / quên mật khẩu)

> ⏸️ **TẠM HOÃN (Dream, 16/09/2026, Đợt 50) — đảo lại quyết định "ĐÃ CHỐT" ngày 2026-09-15:** kênh gửi OTP xác thực tài khoản (đăng ký tài khoản + quên mật khẩu, cho **App user** — Landlord/Manager) **tiếp tục dùng eSMS như hiện tại, KHÔNG đổi sang Zalo ZBS** cho tới khi có quyết định rõ ràng. Lý do đảo lại: ZBS đã xác nhận rẻ hơn eSMS (xem mục 3.2), nhưng Dream đang cân nhắc lại câu hỏi rộng hơn — có nên tiếp tục dùng Zalo OA cho hệ thống này hay không (ảnh hưởng cả Luồng A/B, không riêng OTP) — nên chưa muốn chốt riêng cho Luồng C trước khi có câu trả lời chung đó. Toàn bộ nội dung mục 3 bên dưới (template 636478, tham số, checklist code) **vẫn giữ nguyên làm tài liệu tham khảo** — không xoá gì, chỉ đổi trạng thái quyết định, để khi nào chốt xong việc dùng OA thì áp dụng lại ngay, không phải nghiên cứu lại từ đầu. **Không có gì cần sửa trong code** — `send-otp-sms/index.ts` trên thực tế chưa từng được đổi sang gọi `sendZns()` (Đợt 47/48 chỉ là quyết định ghi trên tài liệu, chưa code), nên hiện trạng code đã đúng sẵn với quyết định mới này.

### 3.1 Hiện trạng trước khi đổi

Đăng ký tài khoản (S-02) và Quên mật khẩu (S-04) dùng Supabase Auth Phone+OTP, gửi mã qua **Send SMS Hook** — Edge Function `supabase/functions/send-otp-sms/index.ts`, hiện gọi **eSMS.vn** (`DECISIONS.md` Đợt 14):

- Đang dùng Brandname **demo dùng chung "Baotrixemay"** của eSMS — nội dung tin nhắn KHÔNG được nhắc gì tới BizTown, chỉ hợp lệ để test, **không dùng được cho user thật**.
- Trước khi lên production phải đăng ký Brandname CSKH thật qua eSMS và chờ duyệt — một quy trình phê duyệt riêng, chưa có mốc trong repo.
- Chi phí Brandname CSKH thật của eSMS **chưa được ghi lại trong repo** — cần Dream xác nhận số thật nếu muốn so sánh chính xác với giá ZBS ở mục 3.2. Việc chốt đổi sang ZBS không phụ thuộc vào con số này — lợi ích loại bỏ phụ thuộc đăng ký Brandname CSKH đã đủ để quyết định.

Send SMS Hook của Supabase Auth **không ràng buộc kênh gửi thật là gì** — chỉ cần Edge Function verify đúng chữ ký webhook và trả đúng format response. Vì vậy đổi nhà cung cấp **không cần đổi cấu hình hook trên Supabase Dashboard**, chỉ cần đổi phần thân hàm gửi bên trong `send-otp-sms/index.ts`.

### 3.2 Template đã duyệt

| Trường | Giá trị |
|---|---|
| Tên mẫu | BizTown Rent-Manager : xác nhận |
| **ID mẫu ZBS** | **636478** |
| Loại mẫu | Mẫu OTP |
| OA gửi | Townsoft Vina - BizTown |
| Ứng dụng | BizTown Rent Manager |
| Trạng thái | Đã duyệt |
| Ghi chú kiểm duyệt (Zalo) | "mẫu otp xác thực khi tạo tài khoản, đổi mật khẩu, không quảng cáo" |
| Mục đích gửi | Giao dịch |
| Đơn giá gửi qua SĐT | 400 đ/tin |
| Đơn giá gửi qua UID | 280 đ/tin |
| Ztime(s) | 15 (ghi lại nguyên trạng — ý nghĩa chưa rõ, khác với "hiệu lực 5 phút" ghi trong nội dung mẫu, không tự suy diễn) |

### 3.3 Nội dung hiển thị (đã duyệt)

"Mã xác minh của bạn là **\<otp>**. Tuyệt đối KHÔNG chia sẻ mã xác minh cho bất kỳ ai dưới bất kỳ hình thức nào. Mã xác minh có hiệu lực trong 5 phút." — kèm nút "Sao chép mã".

**Tham số:** chỉ 1 tham số duy nhất — `<otp>`, kiểu **string**, cài đặt "OTP (10)".

```json
{ "otp": "415477" }
```

→ Không có mismatch kiểu dữ liệu như Luồng A (`sendZns()` nhận `Record<string, string>`, tham số `otp` cũng là string — khớp sẵn).

### 3.4 Việc cần đổi trong code hiện có

`send-otp-sms/index.ts` (giữ nguyên phần verify chữ ký webhook, chỉ đổi phần gửi):

- Thêm nhánh gọi `sendZns(supabaseAdmin, { phone, templateId: "636478", templateData: { otp: payload.sms.otp } })` (từ `_shared/zalo.ts`) thay cho `sendViaEsms()` — LƯU Ý format số điện thoại khác nhau giữa 2 API (xem mục 0: Zalo cần `84xxxxxxxxx`, không cắt như `toLocalVnPhone()` hiện có cho eSMS).
- `sendZns()` hiện dùng `supabaseAdmin` để tự đọc/làm mới token trong `tb_zalo_token` — cần truyền đúng `ctx.supabaseAdmin` từ `withSupabase`, hàm hook hiện tại (`auth: ["none"]`) có gọi `withSupabase` nhưng chưa dùng `ctx` — cần kiểm tra lại chữ ký hàm khi nối.
- Cân nhắc: giữ `sendViaEsms()` làm fallback khi Zalo lỗi (vd số điện thoại không dùng Zalo), hay bỏ hẳn eSMS cho OTP — **NEEDS INPUT** (đây là chi tiết triển khai còn mở, khác với việc kênh chính đã chốt là ZBS). Nếu giữ fallback, cần rule rõ ràng khi nào fallback (Zalo trả lỗi cụ thể gì) để tránh im lặng gửi trùng 2 lần.
- Endpoint/kiểu ZBS cần verify giống lưu ý ở mục 0 (dùng chung `sendZns()` với Luồng A).

### 3.5 Nội dung/tính năng liên quan đã phát triển trước đó — cần rà lại cho khớp

Các chỗ đã code trước đây (S-02 Đăng ký, S-04 Quên mật khẩu) có thể đang giả định kênh "SMS" cụ thể — cần đổi cho khớp quy tắc mới (kênh có thể không còn là SMS):

- [ ] Rà copy/UI 2 màn S-02/S-04 (Flutter, khu vực nhập OTP dùng `pin_code_fields`) xem có chữ nào nhắc "SMS" cứng (vd "Mã đã gửi qua SMS tới số...") — đổi thành cách nói trung tính kênh (vd "Mã xác minh đã gửi tới số...").
- [ ] `docs/REQUIREMENTS.md` INT-02/INT-03 — đã cập nhật trạng thái ngay trong đợt này (xem mục 3.6 dưới), phản ánh đúng hướng ZBS.
- [ ] `docs/ARCHITECTURE.md` mục nhắc "Auth Hook tuỳ chỉnh (Send SMS) để gửi OTP qua nhà cung cấp SMS Việt Nam" — cần cập nhật lại tên nhà cung cấp khi code xong.
- [ ] Cảnh báo Brandname demo ở đầu `send-otp-sms/index.ts` (dòng 14-17) không còn đúng nếu bỏ hẳn eSMS — cần xoá/sửa lại comment khi code xong.
- [ ] Test OTP number cấu hình sẵn trong Supabase Auth (`0356123970` → mã cố định) đi qua đường riêng của Supabase (bỏ qua hook hoàn toàn) — không bị ảnh hưởng bởi thay đổi này, không cần sửa.

### 3.6 Lịch sử cập nhật trạng thái quyết định

- 2026-09-15 (Đợt 47/48): `docs/REQUIREMENTS.md` INT-02/INT-03 được sửa để ghi "ĐÃ CHỐT: đổi sang ZBS".
- 2026-09-16 (Đợt 50): **đảo lại** — INT-03 nay ghi "tạm hoãn, giữ eSMS, chờ quyết định OA" — xem `docs/REQUIREMENTS.md` INT-03 và `docs/DECISIONS.md` Đợt 50.

### 3.7 Giới hạn tối ưu chi phí UID cho luồng này

Giống Luồng A/B, tối ưu SĐT→UID cần biết UID của người nhận — ở đây là **App user** (`tb_user`), không phải Tenant. Hiện DB cũng **không có field lưu UID/tương tác OA của `tb_user`** (tương tự gap đã nêu ở mục 1.6 cho `tb_tenant`). Vì phần lớn lượt gửi OTP (đăng ký tài khoản lần đầu) xảy ra **trước khi** user có khả năng đã follow OA, thực tế gần như toàn bộ sẽ đi qua kênh SĐT (400đ/tin) — khoản tiết kiệm UID cho luồng này không phải trọng tâm, khác với Luồng A/B (nơi Tenant được chủ động mời follow trước).

### 3.8 Việc cần làm để bật thật (tóm tắt)

- [ ] Verify endpoint/kiểu dữ liệu ZBS (mục 0) — dùng chung hạ tầng với Luồng A.
- [ ] Sửa `send-otp-sms/index.ts` theo mục 3.4, đặc biệt đúng format SĐT cho Zalo (khác eSMS).
- [ ] Chốt có giữ eSMS làm fallback hay bỏ hẳn (mục 3.4 — chi tiết triển khai, không phải hướng đi chính).
- [ ] Rà + cập nhật các nội dung liên quan đã phát triển trước đó (mục 3.5).
- [ ] Test thật với số điện thoại thật (không phải Test OTP number) trước khi coi là xong.
- [ ] Sau khi xong, ghi kết quả test vào `DECISIONS.md` và cập nhật `changelog/YYYY-MM-DD.md`.

---

## 4. Tham chiếu

- `supabase/functions/_shared/zalo.ts`, `tb_zalo_token` (migration `20260915100000_tb_zalo_token.sql`)
- `supabase/functions/send-otp-sms/index.ts`, `supabase/functions/_shared/esms.ts` (Luồng C)
- `docs/DECISIONS.md` Đợt 14 (chọn eSMS cho OTP), Đợt 41 (hạ tầng Zalo), Đợt 46 (Luồng A/B), Đợt 47 (Luồng C — đổi sang ZBS), Đợt 48 (sửa lại nội dung mục 3), Đợt 50 (đảo lại quyết định Luồng C — tạm hoãn, quay về eSMS)
- `docs/REQUIREMENTS.md` INT-02/INT-03
- Project brainstorm của Dream (ngoài repo, research chi tiết cho Luồng B): `zalo-feasibility-review.md`

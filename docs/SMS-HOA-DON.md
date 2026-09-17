# SMS-HOA-DON.md — Gửi thông báo hoá đơn hàng tháng cho Tenant qua eSMS

> **Trạng thái:** ✅ Đang dùng cho Phase 1 (từ 16/09/2026, Đợt 51 — xem [DECISIONS.md](DECISIONS.md)). Thay thế hoàn toàn "Luồng B" của [ZALO-MESSAGING.md](ZALO-MESSAGING.md) (nay tạm ngưng). Áp dụng cho `BR-NOTI-01`/`BR-NOTI-02` (BUSINESS-RULES.md) và `FR-NOTI-02`/`INT-02` (REQUIREMENTS.md).
>
> **Bối cảnh:** Zalo OA bị bỏ hẳn cho Phase 1 vì cơ chế vận hành phức tạp hơn cần thiết (đăng ký/xác thực doanh nghiệp, chờ duyệt mẫu, cửa sổ tương tác 7 ngày, cấm QR trong khối hình ảnh mẫu). Hướng thay thế: **1 SMS ngắn (qua eSMS, kênh đã tích hợp sẵn) + 1 link ảnh do hệ thống tự tạo riêng cho từng hoá đơn**, ảnh chứa đầy đủ bảng chi phí chi tiết và mã QR chuyển khoản.

---

## 1. Nguyên tắc tối ưu chi phí SMS

SMS tính phí theo **đoạn** (segment), không phải theo tin:

| Mã hoá | Điều kiện | Giới hạn ký tự/đoạn (1 đoạn / nhiều đoạn nối) |
|---|---|---|
| GSM-7 | Toàn bộ ký tự không dấu (chữ Latin cơ bản, số, dấu câu thường) | 160 / 153 |
| UCS-2 | Có bất kỳ ký tự Unicode nào (dấu tiếng Việt: ă, â, đ, ơ, ư...) | 70 / 67 |

→ Cùng 1 nội dung, viết **có dấu** thường tốn gấp đôi số đoạn (do rơi vào UCS-2 với giới hạn thấp hơn nhiều) so với viết **không dấu** (giữ được GSM-7). Test thực tế với đúng 1 nội dung mẫu:

| Phiên bản | Số ký tự | Mã hoá | Số đoạn tính phí |
|---|---|---|---|
| Có dấu đầy đủ | 114 | UCS-2 (giới hạn 67/đoạn) | **2 đoạn** |
| Không dấu | 97–122 | GSM-7 (giới hạn 160/đoạn) | **1 đoạn** |

**Quyết định áp dụng:** nội dung SMS hoá đơn viết **không dấu**, và dùng **link rút gọn** (domain ngắn riêng, không dán thẳng URL Supabase Storage/signed token dài hàng trăm ký tự) để giữ toàn bộ tin trong 1 đoạn.

---

## 2. Mẫu nội dung SMS gửi Tenant (không dấu, 1 đoạn ≤ 160 ký tự)

> **Cập nhật 16/09/2026 (Đợt 52):** Dream tự sửa trực tiếp trong Figma, gộp SMS xác nhận hợp đồng mới (mục 2.1) và SMS hoá đơn hàng tháng (mục 2.2) vào **chung 1 luồng hội thoại SMS** với Tenant (cùng 1 đầu số gửi, 2 loại tin xuất hiện nối tiếp nhau theo thời gian trong cùng 1 thread nhắn tin trên điện thoại Tenant). Mục 2.1 là kênh thay thế chính thức cho "Luồng A — Tin chào mừng hợp đồng mới" từng để ngỏ ở Đợt 51 — xem `docs/ZALO-MESSAGING.md` (banner đầu tài liệu, cập nhật cùng đợt này) và `docs/DECISIONS.md` Đợt 52. Không liên quan tới OTP (Luồng C) — OTP gửi cho người dùng App (Landlord/Manager), khác đối tượng nhận với 2 tin này (gửi Tenant), vẫn theo eSMS như Đợt 50, không đổi.

### 2.1 SMS xác nhận hợp đồng mới (gửi 1 lần khi hợp đồng được tạo)

```
BizTown: HD thue phong {ten_phong} - {ten_nha_tro} da tao. Bat dau {ngay_bat_dau}, tien thue {tien_thue}d/thang, han TT ngay {han_tt} hang thang.
```

**Ví dụ với dữ liệu thật (khớp mockup Figma):**
```
BizTown: HD thue phong 203 - Minh Tam da tao. Bat dau 15/09/2026, tien thue 2.500.000d/thang, han TT ngay 25 hang thang.
```
(114 ký tự — 1 đoạn GSM-7, không dấu)

**Quy tắc dựng chuỗi:** cùng nguyên tắc bỏ dấu như mục 2.2 bên dưới. `ngay_bat_dau` lấy ngày bắt đầu hợp đồng/phiên bản hợp đồng hiện hành, định dạng `dd/mm/yyyy`. `tien_thue` là tiền thuê phòng theo phiên bản hợp đồng hiện hành (chưa gồm điện/nước/phí khác — các khoản đó chỉ phát sinh theo từng kỳ hoá đơn, xem mục 2.2). `han_tt` chỉ lấy số ngày trong tháng (không kèm tháng/năm vì lặp lại hàng tháng). Nếu hợp đồng gồm nhiều phòng: áp dụng cùng quy tắc ghép/cắt tên phòng như mục 2.2.

### 2.2 SMS hoá đơn hàng tháng (gửi định kỳ mỗi kỳ hoá đơn)

```
BizTown: HD P{ten_phong}-{ten_nha_tro} ky {ky_hoa_don}. Tong {tong_tien}d, han {han_thanh_toan}. Chi tiet: {link_anh_chi_tiet}
```

**Ví dụ với dữ liệu thật:**
```
BizTown: HD P203-Minh Tam ky 09/2026. Tong 2.937.500d, han 25/09. Chi tiet: https://btr.vn/i/aB3xZ9
```
(97 ký tự — 1 đoạn GSM-7)

> **Cập nhật 16/09/2026 (Đợt 52):** đổi caption link từ "QR + CTK:" (Đợt 51) sang "Chi tiet:" theo bản Dream tự sửa trực tiếp trong Figma — không đổi độ dài/số đoạn tính phí (vẫn 97 ký tự, 1 đoạn GSM-7). Lý do: "Chi tiet" mô tả đúng nội dung ảnh hơn (ảnh không chỉ có QR mà còn cả bảng chi phí chi tiết).

**Quy tắc dựng chuỗi (bỏ dấu tự động từ dữ liệu có dấu trong DB):**
- `ten_phong`/`ten_nha_tro`: bỏ dấu, viết liền hoặc cách bằng khoảng trắng, KHÔNG viết hoa toàn bộ.
- `tong_tien`: định dạng số có dấu chấm phân cách nghìn, hậu tố `d` (không phải `đ` — giữ GSM-7).
- `han_thanh_toan`: rút gọn `dd/mm` (bỏ năm) nếu cùng năm hiện tại, để tiết kiệm ký tự; ghi đủ `dd/mm/yyyy` nếu khác năm.
- `link_anh_chi_tiet`: link rút gọn duy nhất cho hoá đơn đó (xem mục 4).
- Nếu 1 hợp đồng có nhiều phòng: ghép tên phòng cách nhau bằng dấu phẩy, cắt bớt + thêm "..." nếu vượt quá 20 ký tự cho phần này (chi tiết đầy đủ luôns có trong ảnh).

---

## 3. Thiết kế ảnh chi tiết + QR

Ảnh là 1 file PNG được **Edge Function tự sinh riêng cho từng hoá đơn** tại thời điểm gửi (không phải ảnh tĩnh dùng chung), gồm các khối theo thứ tự từ trên xuống:

1. **Banner đầu trang** — logo đầy đủ màu thương hiệu BizTown Rent Manager (biểu tượng cột + wordmark), căn trái, trên nền navy `#1E2A55`. Dùng bản logo tách nền (không phủ filter/đổi màu) để giữ đúng màu icon (xám/trắng/cam) — tránh làm phẳng logo thành 1 màu.
2. **Tiêu đề** — "Hoá đơn tiền trọ", tên Nhà/Dãy trọ · tên Phòng · kỳ hoá đơn, kèm badge trạng thái ("Chưa thanh toán"/"Quá hạn"/"Đã thanh toán").
3. **Thông tin phụ** — tên Người thuê, **Mã hợp đồng** (dòng riêng, đứng trước), rồi **Mã hoá đơn**.
4. **Bảng chi phí chi tiết** — từng dòng: tiền phòng, tiền điện (kèm số kWh), tiền nước (kèm số m³); riêng **"Phí khác" viết chi tiết theo từng khoản**, thụt đầu dòng dưới 1 nhãn "Phí khác" (không gộp thành 1 số duy nhất) — ví dụ: Phí dịch vụ, Phí wifi. Số dòng/nội dung tuỳ theo `otherFees` thực tế của hoá đơn đó (có thể nhiều hơn 2 khoản, hoặc không có khoản nào thì ẩn cả mục này).
5. **Khối tổng cộng** — nổi bật (nền cam nhạt, số tiền lớn, đậm).
6. **Hạn thanh toán** — nổi bật màu cảnh báo.
7. **Khối QR** — khung viền nét đứt, chứa:
   - Tiêu đề "Quét mã để thanh toán qua VietQR"
   - Ảnh mã QR VietQR/NAPAS-247 (sinh từ `_shared/vietqr.ts`, đã có sẵn logic)
   - Bảng thông tin chuyển khoản dạng chữ (dự phòng khi không quét QR được): Ngân hàng, Số tài khoản, Chủ tài khoản, Nội dung chuyển khoản.
8. **Ghi chú cuối trang** — nguyên văn: *"Quý khách vui lòng chuyển khoản đúng số tiền, đúng hạn để tránh phí trễ hạn. Sau khi chuyển khoản, vui lòng thông báo cho chủ nhà qua Zalo/SMS."* (ghi chú này chỉ là hướng dẫn cho Tenant tự nhắn lại chủ nhà qua kênh cá nhân của họ — không phải hệ thống gửi qua Zalo OA, không mâu thuẫn với quyết định bỏ OA ở Đợt 51).
9. **Footer** — tên thương hiệu.

Mockup trực quan (kích thước ~390px chiều ngang, tối ưu xem trên điện thoại) đã được dựng và gửi cho Dream xem qua Claude/Cowork (bản mới nhất đã áp dụng đủ 9 khối trên) — dùng làm tham chiếu bố cục khi code thật.

---

## 4. Bảng ánh xạ dữ liệu (field trong ảnh + SMS ↔ field trong hệ thống)

| Vị trí hiển thị | Field hệ thống |
|---|---|
| Tên Nhà/Dãy trọ | `tb_house.name` |
| Tên phòng (1 hoặc nhiều, ghép theo `tb_contract_room`) | `tb_room.name` |
| Tên Người thuê | `tb_tenant.fullName` |
| Mã hợp đồng | `tb_contract.id` / mã hiển thị rút gọn (cần chốt cách sinh — xem mục 5) |
| Mã hoá đơn | `tb_invoice.id` / mã hiển thị rút gọn (cần chốt cách sinh — xem mục 5) |
| Kỳ hoá đơn | `tb_invoice.period` |
| Tiền phòng | `tb_invoice.roomFee` |
| Tiền điện + số kWh | `tb_invoice.electricityFee` / `tb_invoice.electricityUsage` |
| Tiền nước + số m³ | `tb_invoice.waterFee` / `tb_invoice.waterUsage` |
| Phí khác (từng dòng: Phí dịch vụ, Phí wifi...) | `tb_invoice.otherFees` — **mảng** `{label, amount}[]`, không phải 1 số duy nhất (khớp cách `otherFees` đã dùng để ghi "dòng điều chỉnh" ở `BR-METER-13`/Đợt 8) — mỗi phần tử render thành 1 dòng thụt đầu dòng trong ảnh |
| Tổng cộng | `tb_invoice.totalAmount` |
| Hạn thanh toán | `tb_invoice.dueDate` |
| Ngân hàng | `tb_house.ownerBankName` |
| Số tài khoản | `tb_house.ownerBankAccount` |
| Chủ tài khoản | `tb_house.ownerAccountName` |
| Nội dung chuyển khoản (trong QR + bảng chữ) | Sinh từ mã hoá đơn/phòng/kỳ, ví dụ `HD P203 09/2026` |
| Số điện thoại nhận SMS | `tb_tenant.phone` |
| Ngày bắt đầu hợp đồng (SMS xác nhận hợp đồng mới, mục 2.1) | `tb_contract.startDate` / `tb_contract_version.startDate` (bản mới nhất) |
| Tiền thuê/tháng (SMS xác nhận hợp đồng mới, mục 2.1) | `tb_contract_version.rentFee` |
| Hạn thanh toán hàng tháng — số ngày trong tháng (SMS xác nhận hợp đồng mới, mục 2.1) | `tb_contract_version.paymentDueDayOfMonth` |

---

## 5. Việc cần làm để bật thật (chưa code — thuần thiết kế/tài liệu ở đợt này)

- [ ] Chốt domain/dịch vụ rút gọn link (`btr.vn/i/<code>` là ví dụ minh hoạ, chưa phải domain thật) — cần đăng ký domain ngắn hoặc dùng route riêng trong hạ tầng hiện có.
- [ ] Chốt cách sinh mã hoá đơn hiển thị ngắn gọn (hiện `tb_invoice` chỉ có `id` dạng UUID) — dùng tạm UUID rút gọn hay thêm cột mã hiển thị riêng (vấn đề tương tự đã ghi nhận cho `<ma_hop_dong>` ở Luồng A cũ, `DECISIONS.md` Đợt 46).
- [ ] Thiết kế Edge Function mới (hoặc mở rộng `generate-payment-qr`) để: sinh ảnh PNG theo layout mục 3, lưu vào Supabase Storage, tạo link rút gọn có hạn dùng (đề xuất: hết hạn sau X ngày qua `dueDate`, tránh lộ QR/số tiền vĩnh viễn qua 1 link tĩnh).
- [ ] Sửa `send-notification/index.ts`: bỏ nhánh Zalo còn để `// TODO`, thêm bước gọi Edge Function sinh ảnh trước khi gửi SMS, dựng nội dung SMS theo mẫu mục 2 (bỏ dấu tự động).
- [ ] Test gửi SMS hàng loạt qua eSMS (API `SendMultipleMessage_V4_post_json` đã dùng cho OTP có hỗ trợ gửi nhiều SĐT nội dung khác nhau/lần gọi — cần xác nhận lại đúng field cho trường hợp nội dung theo từng người, không phải 1 nội dung chung).
- [ ] 2 màn hình minh hoạ trong Figma (SMS + ảnh chi tiết) — xem `DESIGN.md`/link Figma, thêm ở đợt này theo `DECISIONS.md` Đợt 51.

---

## 6. Mẫu KHÔNG DÙNG LINK (phương án chạy được ngay) — chốt 17/09/2026

**Bối cảnh**: mẫu ở mục 2.2 phụ thuộc link tới trang tĩnh (bên ngoài đang dựng) và tên miền chưa mua. Mẫu dưới đây **không phụ thuộc gì cả**, gửi được ngay khi có Brandname.

```
BizTown: HD P{phong} ky {ky} la {tong_tien}d. CK {ngan_hang_va_stk} truoc {han}.
```

**Ví dụ với dữ liệu thật:**
```
BizTown: HD P.101 ky 15/09-14/10/2026 la 3.602.400d. CK Vietcombank 0071000123456 (NGUYEN THUY HUONG) truoc 21/09/2026.
```
(119 ký tự — **1 đoạn GSM-7**)

**Đánh đổi**: mất mã QR (người thuê tự gõ số tài khoản) và mất bảng chi tiết điện/nước. Bù lại chạy được ngay, không chờ trang tĩnh.

### 6.1 ⚠️ Bẫy chi phí: một ký tự sai bảng mã làm đắt gấp 3

Bản tiếng Anh trên Figma dùng **dấu gạch dài `–` (en dash)** trong `15/09–14/10/2026`. Ký tự đó **không nằm trong GSM-7**, nên kéo cả tin sang UCS-2, giới hạn tụt từ 160 xuống 70 ký tự/đoạn:

| Mẫu | Mã hoá | Ký tự | Đoạn | 66 tin/tháng |
|---|---|---|---|---|
| Nguyên văn design (gạch dài `–`) | UCS-2 | 154 | **3** | **79.200đ** |
| Y hệt, đổi thành gạch thường `-` | GSM-7 | 154 | **1** | 26.400đ |
| Tiếng Việt không dấu | GSM-7 | 119 | **1** | 26.400đ |
| Tiếng Việt có dấu | UCS-2 | 129 | 2 | 52.800đ |

**Quy tắc bắt buộc khi dựng chuỗi**: chỉ dùng `-` thường, không dùng `–`/`—`; không dùng `…`, `"` cong, `₫`. dungtv chốt 17/09/2026: **bỏ dấu hoàn toàn, ưu tiên chi phí**.

### 6.2 Quy định nhà mạng về link trong template (đã tra, 17/09/2026)

Link **được phép**, nhưng theo đúng khuôn: **phần cố định của template phải đăng ký sẵn đường link gốc**, phần tham biến chỉ được là **phần mở rộng** của link đó và **không chứa khoảng trắng**.

→ Thiết kế hiện tại (`https://btr.vn/i/` cố định + mã tra cứu 12 ký tự) **đã đúng khuôn này**, không phải đổi gì.

Ngoài ra: tên thương hiệu **bắt buộc xuất hiện trong nội dung tin** (áp dụng từ 12/08/2024). Mẫu của mình mở đầu bằng `BizTown:` nên đã thoả.

**Chưa xác nhận được**: một nguồn ghi Vinaphone giới hạn **tối đa 3 tham số** mỗi template. Mẫu hoá đơn có tới 6-7 chỗ thay đổi. Nhưng mẫu thật của brandname demo `Baotrixemay` quan sát được có tới 5 tham số, nên giới hạn này có thể chỉ áp cho một nhà mạng hoặc đã cũ. **Phải hỏi nhà cung cấp trước khi nộp hồ sơ**; nếu đúng 3 thì gộp `Vietcombank 0071000123456 (NGUYEN THUY HUONG)` thành MỘT tham số thay vì ba.

### 6.3 Không mượn được mẫu của bên khác

Đã tra danh sách template của brandname demo `Baotrixemay` qua API `GetTemplate` — **21 mẫu, không mẫu nào có link, không mẫu nào hợp nghiệp vụ hoá đơn** (toàn mẫu tiệm xe máy: xe đã sửa xong, tới hạn bảo trì, chúc sinh nhật, mã xác minh). Mẫu gắn chết với từng brandname, **không có kho mẫu dùng chung để mượn**. Muốn gửi hoá đơn thì bắt buộc đăng ký brandname riêng.


### 6.4 Link trong SMS: CHẶN vì `?` và `&`, không phải vì là link (test thật 17/09/2026)

Gửi thật tới máy dungtv, cùng brandname `Baotrixemay`, cùng mẫu, chỉ khác dạng link:

| Link trong tin | Kết quả |
|---|---|
| `https://qr.sepay.vn/img?acc=9697354961&bank=970436` | ❌ Thất bại |
| `qr.sepay.vn/img?acc=9697354961&bank=970436` (bỏ `https://`) | ❌ Thất bại |
| `qr.sepay.vn/pay/98A31YT6Q1W0` | ✅ **Tới, bấm được** |
| `btr.vn/i/98A31YT6Q1W0` | ✅ **Tới, bấm được** |

**Kết luận**: cái bị chặn là **tham số truy vấn (`?`, `&`)**, không phải bản thân đường link. Link dạng đường dẫn sạch đi lọt và hiện thành liên kết bấm được trên máy.

**Hệ quả cho thiết kế**: mẫu `https://btr.vn/i/{ma_tra_cuu}` đã chọn từ trước **đúng dạng đi lọt** — không phải đổi gì. Ngược lại, **không được dùng link kiểu `?code=...`** (VD link ảnh QR của SePay) vì sẽ bị loại.

**Lưu ý chi phí**: tin thất bại **vẫn bị trừ tiền** như tin thành công.

# API tra cứu hoá đơn công khai — tài liệu cho bên làm trang hiển thị

> **Trạng thái:** API đã deploy và chạy thật (16/09/2026). Có thể gọi thử ngay bằng ví dụ trong tài liệu này.
> **Đối tượng đọc:** lập trình viên làm trang web hiển thị hoá đơn — không cần biết gì về hệ thống BizTown từ trước.

---

## 1. Bối cảnh: trang này để làm gì

BizTown Rent Manager là ứng dụng cho **chủ nhà trọ** quản lý phòng và hoá đơn. **Người thuê không cài ứng dụng, không có tài khoản** — họ chỉ nhận tin nhắn SMS báo hoá đơn hàng tháng.

Vấn đề: tin nhắn SMS tính phí theo độ dài nên không thể nhét hết chi tiết (tiền điện, tiền nước, chỉ số đầu/cuối, mã QR chuyển khoản). Giải pháp: SMS chỉ ghi tổng tiền kèm **một đường link ngắn**, người thuê bấm vào là mở trang web xem đầy đủ.

**Trang web cần làm chính là trang đó.**

### Luồng hoạt động

```
1. Người thuê nhận SMS:
   "BizTown: Hoa don phong B.5 ky 09/2026: 4.408.400d.
    Han 05/10. Chi tiet: bill.<domain>/PNQF2YB2PBY4"

2. Bấm link → mở trang web (trang tĩnh, host ở Netlify/Cloudflare Pages)

3. Trang đọc mã "PNQF2YB2PBY4" từ đường dẫn

4. Trang gọi API (mô tả ở mục 3) kèm mã đó

5. API trả JSON → trang hiển thị bảng chi tiết + vẽ mã QR chuyển khoản
```

Người thuê **không đăng nhập**, **không cài gì**. Mở link là thấy hoá đơn.

---

## 2. Những điều cần nắm trước khi code

**Mã nằm trong đường dẫn, không phải tham số truy vấn.** Link là `bill.<domain>/PNQF2YB2PBY4`, không phải `bill.<domain>/?code=...`. Viết vậy để tiết kiệm ký tự trong SMS.

Hệ quả: host phải được cấu hình **trả cùng một file HTML cho mọi đường dẫn**, nếu không sẽ ra lỗi 404 của host vì nó đi tìm file tên `PNQF2YB2PBY4`.

- Netlify: tạo file `public/_redirects` với nội dung `/*  /index.html  200`
- Cloudflare Pages: tạo file `public/_redirects` y hệt, hoặc dùng `_routes.json`

**Mã có đúng 12 ký tự**, gồm chữ HOA và số, đã loại bỏ `I`, `L`, `O`, `U` để không nhìn nhầm với `1` và `0`. Biểu thức kiểm tra: `/^[0-9A-HJKMNP-TV-Z]{12}$/`

**Mỗi hoá đơn một mã riêng, mã không hết hạn.** Người thuê mở lại tin nhắn từ 3 tháng trước vẫn xem được hoá đơn tháng đó. Không có khái niệm "hoá đơn mới nhất" — mỗi mã gắn chặt với đúng một hoá đơn.

---

## 3. Đặc tả API

### Địa chỉ

```
POST https://rrtppoibjprlvasnbvwr.supabase.co/functions/v1/invoice-public
```

### Yêu cầu

**Không cần xác thực** — không cần token, không cần API key, không cần header đặc biệt nào.

```http
POST /functions/v1/invoice-public
Content-Type: application/json

{ "code": "PNQF2YB2PBY4" }
```

CORS đã được mở sẵn (`Access-Control-Allow-Origin: *`), gọi được từ bất kỳ tên miền nào.

### Phản hồi thành công (HTTP 200)

```json
{
  "houseName": "Nha trong So 2",
  "rooms": ["B.5"],
  "tenantName": "Phan Thu Huong",
  "periodStart": "2026-09-01",
  "periodEnd": "2026-09-30",
  "dueDate": "2026-09-05",
  "status": "Draft",
  "lines": {
    "rent": 4000000,
    "electricity": {
      "previousReading": 158,
      "currentReading": 186,
      "usageAmount": 28,
      "unitPrice": 3800,
      "amount": 106400
    },
    "water": {
      "previousReading": 63,
      "currentReading": 77,
      "usageAmount": 14,
      "unitPrice": 18000,
      "amount": 252000
    },
    "serviceFee": 50000,
    "recurringFees": [],
    "otherFees": []
  },
  "totalAmount": 4408400,
  "payment": {
    "bankBin": "970436",
    "bankName": "Vietcombank",
    "accountNumber": "9697354961",
    "accountName": "TRAN VAN DUNG",
    "qrPayload": "00020101021138..."
  }
}
```

### Giải thích từng trường

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `houseName` | string | Tên nhà trọ |
| `rooms` | string[] | Danh sách phòng. **Có thể nhiều phòng** — một hợp đồng thuê được nhiều phòng cùng lúc |
| `tenantName` | string | Tên người thuê |
| `periodStart` / `periodEnd` | string `YYYY-MM-DD` | Kỳ hoá đơn |
| `dueDate` | string `YYYY-MM-DD` | Hạn thanh toán |
| `status` | string | `Draft` \| `Sent` \| `Collected`. `Collected` = đã thu tiền |
| `lines.rent` | number | Tiền phòng (VND). **Có thể bằng 0** nếu kỳ này không thu tiền phòng (chu kỳ thu 3 hoặc 6 tháng một lần) |
| `lines.electricity` | object \| **null** | `null` nếu nhà đó không tính tiền điện |
| `lines.water` | object \| **null** | `null` nếu nhà đó không tính tiền nước |
| `lines.serviceFee` | number | Phí dịch vụ |
| `lines.recurringFees` | array | Phí cố định hàng tháng: `[{ "name": "Internet", "amount": 100000 }]` |
| `lines.otherFees` | array | Phí phát sinh, cùng cấu trúc với `recurringFees` |
| `totalAmount` | number | **Tổng cộng** — dùng số này để hiển thị, không tự cộng lại |
| `payment` | object \| **null** | `null` nếu chủ nhà chưa khai báo tài khoản ngân hàng |

**Về `electricity` / `water`:**

- `previousReading` / `currentReading` là chỉ số công tơ đầu kỳ và cuối kỳ
- **Có thể là `null`** khi hoá đơn gồm nhiều phòng (không gộp chỉ số của các công tơ khác nhau được). Khi `null` thì đừng hiển thị dòng chỉ số, chỉ hiển thị `usageAmount` và `amount`
- `unitPrice` là đơn giá mỗi kWh / mỗi m³
- Nếu tính khoán (giá cố định không theo công tơ) thì `usageAmount` và `unitPrice` sẽ là `0`/`null`, chỉ có `amount`

### Lỗi

| HTTP | Nội dung | Ý nghĩa |
|---|---|---|
| 404 | `{"error":"not_found"}` | Mã sai, mã không tồn tại, hoặc sai định dạng |
| 429 | `{"error":"too_many_requests"}` | Gọi trượt quá nhiều lần từ cùng một IP |

**Lưu ý quan trọng về 404**: API cố ý trả **cùng một phản hồi** cho mọi trường hợp không tra được — không phân biệt "mã sai định dạng" với "mã đúng định dạng nhưng không tồn tại". Đây là chủ đích bảo mật (không giúp kẻ dò mã biết mình đang đi đúng hướng), nên **đừng cố suy ra lý do cụ thể** từ phản hồi.

Trang nên hiển thị thông báo chung kiểu: *"Không tìm thấy hoá đơn. Vui lòng kiểm tra lại đường dẫn trong tin nhắn."*

Với 429: *"Bạn đã thử quá nhiều lần. Vui lòng đợi ít phút rồi thử lại."*

---

## 4. Vẽ mã QR

`payment.qrPayload` là **chuỗi VietQR chuẩn EMVCo**, không phải ảnh. Việc của trang là vẽ chuỗi đó thành hình QR bằng thư viện phía trình duyệt.

Thư viện gợi ý: [`qrcode`](https://www.npmjs.com/package/qrcode) hoặc [`qrcode.react`](https://www.npmjs.com/package/qrcode.react).

```js
import QRCode from 'qrcode';
await QRCode.toCanvas(document.getElementById('qr'), data.payment.qrPayload, { width: 240 });
```

Người thuê mở app ngân hàng quét mã này thì **số tiền và nội dung chuyển khoản tự điền sẵn**, không phải gõ tay.

**Không cần lưu ảnh QR ở đâu cả** — mỗi lần gọi API là chuỗi được sinh lại từ số tài khoản hiện tại của chủ nhà. Thiết kế như vậy để nếu chủ trọ đổi số tài khoản thì người thuê mở lại link cũ vẫn ra QR trỏ đúng tài khoản mới, không chuyển nhầm sang tài khoản đã bỏ.

Nên hiển thị kèm **số tài khoản và tên chủ tài khoản dạng chữ** bên dưới mã QR, phòng trường hợp người thuê dùng app ngân hàng không quét được QR và phải nhập tay.

---

## 5. Gọi thử ngay

Mã `PNQF2YB2PBY4` là hoá đơn thật trong hệ thống test, dùng để phát triển:

```bash
curl -X POST https://rrtppoibjprlvasnbvwr.supabase.co/functions/v1/invoice-public \
  -H "Content-Type: application/json" \
  -d '{"code":"PNQF2YB2PBY4"}'
```

```js
const code = window.location.pathname.replace(/^\//, '');

const res = await fetch(
  'https://rrtppoibjprlvasnbvwr.supabase.co/functions/v1/invoice-public',
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code }),
  },
);

if (res.status === 404) { /* hiện thông báo không tìm thấy */ }
else if (res.status === 429) { /* hiện thông báo thử lại sau */ }
else { const invoice = await res.json(); /* hiển thị */ }
```

---

## 6. Gợi ý bố cục trang

Trang chỉ có **một mục đích duy nhất**: người thuê xem tiền phải trả và chuyển khoản cho nhanh. Ưu tiên hiển thị trên điện thoại.

```
┌─────────────────────────────────┐
│  Nha trong So 2 — Phòng B.5     │  houseName + rooms
│  Kỳ 01/09 – 30/09/2026          │  periodStart, periodEnd
├─────────────────────────────────┤
│  Tiền phòng           4.000.000 │  lines.rent
│  Điện  158→186  28kWh   106.400 │  lines.electricity
│  Nước   63→77   14m³    252.000 │  lines.water
│  Phí dịch vụ             50.000 │  lines.serviceFee
│  Internet               100.000 │  lines.recurringFees
├─────────────────────────────────┤
│  TỔNG CỘNG            4.408.400 │  totalAmount (in đậm, to nhất)
│  Hạn thanh toán       05/10/2026│  dueDate
├─────────────────────────────────┤
│         [ mã QR ]               │  payment.qrPayload
│  Vietcombank · 9697354961       │  payment.bankName + accountNumber
│  TRAN VAN DUNG                  │  payment.accountName
└─────────────────────────────────┘
```

Lưu ý khi làm:

- **Định dạng số tiền kiểu Việt Nam**: `4.408.400` (dấu chấm ngăn nghìn), kèm `đ` hoặc `VND`
- **Ngày kiểu Việt Nam**: `05/10/2026`, không dùng `2026-10-05`
- Nếu `status` là `Collected` thì hiện nhãn "ĐÃ THANH TOÁN" và **ẩn mã QR đi** — tránh người thuê chuyển tiền lần thứ hai
- Nếu quá `dueDate` mà `status` chưa phải `Collected` thì hiện nhãn "QUÁ HẠN"
- `payment` là `null` thì ẩn toàn bộ khối QR, chỉ hiện chi tiết hoá đơn
- Trang chỉ để xem, **không có nút bấm nào gửi dữ liệu lên**

---

## 7. Liên hệ khi vướng

Tài liệu này mô tả API đã chạy thật. Nếu cần thêm trường dữ liệu hoặc gặp phản hồi không khớp mô tả, báo lại phía BizTown để chỉnh Edge Function `supabase/functions/invoice-public/`.

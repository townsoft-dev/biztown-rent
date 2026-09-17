# Gửi hoá đơn qua Email
> **Trạng thái:** ✅ Đã chạy thật (17/09/2026) — thư tới Hộp thư đến, mã QR hiển thị đúng.

## 1. Vì sao email, không phải SMS

SMS gửi được nhưng vướng hai thứ: phải đăng ký **Brandname** (eSMS báo giá 10 triệu — không hợp lý ở quy mô hiện tại), và **mọi mẫu nội dung phải được nhà mạng duyệt trước**. Email không vướng cả hai.

| | SMS | Email |
|---|---|---|
| Duyệt mẫu trước | Bắt buộc | **Không** |
| Chi phí | ~400đ/tin (~26.400đ/tháng) | **0đ** |
| Tiếng Việt có dấu | Tốn tiền gấp đôi | Thoải mái |
| Độ dài | 160 ký tự/đoạn | Không giới hạn |
| Bảng chi tiết điện nước | Không | Có |
| Mã QR | Chỉ gửi được link | **Nhúng thẳng trong thư** |

**SMS không bị bỏ** — vẫn là 1 trong 3 kênh ở màn B-05 (SMS / Email / Zalo). OTP **không đổi**, vẫn đi SMS.

## 2. Kiến trúc

```
App (B-05)  ──►  Edge Function `send-invoice-email`  ──►  Brevo API  ──►  hộp thư người thuê
                          │
                          └─►  ảnh QR: Edge Function `invoice-qr/<ma_tra_cuu>`
```

- Hàm đọc hoá đơn qua client **CÓ RLS** (`ctx.supabase`) để tự kiểm tra quyền — người gọi không có quyền trên nhà đó thì không đọc được, trả 403.
- Ảnh QR **sinh lại từ tài khoản HIỆN TẠI của chủ nhà**, không dùng chuỗi QR lưu trong hoá đơn (chuỗi cũ có thể trỏ tài khoản chủ trọ đã đổi — xem `invoice-public`).

## 3. Vì sao Brevo, và vì sao không dùng SMTP

**Không dùng SMTP được**: Edge Function chạy trên Deno Deploy, môi trường này **chặn kết nối ra cổng 25 và 587** (2 cổng SMTP chuẩn), thư viện SMTP cho Deno cũng chạy chập chờn trong Edge Function. Gọi HTTP API là đường duy nhất ổn định.

> Điểm dễ nhầm: "có VPS thì cài SMTP là xong". Gửi được thật, nhưng thư từ IP mới **gần như chắc chắn vào Spam** vì chưa có uy tín. Thực tế vẫn phải trỏ về một nhà cung cấp. Đường nào cũng về nhà cung cấp email; khác biệt chỉ là gọi qua API hay SMTP.

**Chọn Brevo** vì gửi được ngay khi **chưa xác thực tên miền** (chỉ cần một địa chỉ đã xác thực), và miễn phí 300 thư/ngày (~9.000/tháng) trong khi dự án cần ~66 thư/tháng.

**Đánh đổi**: gói miễn phí gắn thương hiệu Brevo + link "Huỷ đăng ký" ở chân thư. Bỏ được bằng gói trả phí (~10 USD/tháng), hoặc đổi sang Resend khi đã xác thực tên miền.

**Đổi nhà cung cấp rẻ**: chỉ sửa hàm `sendViaBrevo` (địa chỉ gọi, tên header khoá, hình dạng dữ liệu). Phần đọc hoá đơn, kiểm quyền, dựng nội dung thư không phụ thuộc nhà cung cấp.

## 4. Secret cần có

| Secret | Giá trị hiện tại | Bắt buộc |
|---|---|---|
| `BREVO_API_KEY` | (đã set) | ✅ |
| `INVOICE_EMAIL_FROM` | `dreamnguyen@townsoftvina.com` | ✅ |
| `INVOICE_EMAIL_FROM_NAME` | `BizTown Rent Manager` | không |

Thiếu secret thì hàm **trả lỗi rõ ràng**, không âm thầm bỏ qua.

## 5. Mẫu thư

`renderInvoiceEmail()` trong `send-invoice-email/index.ts` hiện là **bản tối giản**. Hường đang thiết kế mẫu thật — khi có thì thay đúng hàm đó, phần còn lại không phải sửa.

**4 lưu ý cho người thiết kế** (giới hạn của Gmail/Outlook, không phải của mình):

1. **Bố cục bằng `<table>`, CSS viết inline** — Gmail cắt bỏ `<style>`, không hiểu flex/grid.
2. **Rộng tối đa ~600px.**
3. **Không JavaScript, không font tải về** — dùng font hệ thống.
4. **Ảnh có thể bị chặn mặc định** — thông tin quan trọng (số tiền, số tài khoản) phải là **chữ**, không nằm trong ảnh. Mã QR để ảnh 220×220, nhưng ghi kèm số tài khoản dạng chữ bên dưới.

## 6. Việc còn lại

- **Xác thực tên miền `townsoftvina.com` bên Brevo** (2-3 bản ghi DNS) → thư hết nguy cơ vào Spam, đổi được người gửi thành `hoadon@townsoftvina.com`.
- Ghép mẫu thư của Hường.
- Test từ trong app (màn B-05) — hiện mới gọi thẳng backend.

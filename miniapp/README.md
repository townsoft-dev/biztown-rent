# Zalo Mini App — Hoá đơn BizTown

Mini App **chỉ làm đúng một việc**: nhận mã tra cứu hoá đơn từ nút CTA trong tin
ZBS, rồi hiện ảnh hoá đơn do Supabase sinh ra.

- **Mini App ID**: `1349578819214204914` (đã ghi sẵn trong `.env`)
- **Zalo App**: `2268275600629034490` — cùng App mà backend đang dùng cho OA/ZNS
- Khung dự án do `zmp init` sinh (Vite 5 + TypeScript + zmp-ui), **không phải tự dựng tay**

## Vì sao mỏng như vậy

Toàn bộ nội dung hoá đơn (bố cục, số tiền, mã QR VietQR) do Edge Function `i`
dựng ra dưới dạng **ảnh PNG**, sinh lại mỗi lần gọi từ dữ liệu mới nhất.

Hệ quả: **sửa hoá đơn chỉ cần sửa phía Supabase, Mini App tự đổi theo** — không
phải build lại, không phải xin Zalo duyệt lại. Mã QR cũng luôn trỏ đúng tài
khoản ngân hàng **hiện tại** của chủ nhà. dungtv chốt 18/09/2026.

## Mini App biết đang xem hoá đơn nào bằng cách nào

Không cần biết người dùng là ai. **Mã tra cứu chính là danh tính** — mỗi hoá đơn
mang một mã ngẫu nhiên 12 ký tự đã gắn sẵn người thuê/phòng/kỳ.

```
Nút CTA trong tin ZBS  →  mở Mini App kèm ?code=<ma_tra_cuu>
                       →  getRouteParams()   (zmp-sdk ≥ 2.11.0)
                       →  hiện .../functions/v1/i/<ma_tra_cuu>
```

## Lệnh

```bash
npm install
npx zmp start        # xem trước trên trình duyệt
npx zmp start -D     # chạy trên điện thoại thật (quét QR bằng Zalo)
npx zmp build        # build ra thư mục www/
npx zmp deploy       # đẩy lên Zalo, sinh ra một phiên bản chờ duyệt
```

Đăng nhập khi cần: `npx zmp login --app-id 1349578819214204914 --token <access_token>`
— lấy token ở `developers.zalo.me` → Công cụ → API Explorer (nhớ chọn đúng Zalo App).

## Trạng thái

- [x] Khung dự án, đã gắn Mini App ID
- [x] Trang hiện ảnh hoá đơn, có nhánh báo lỗi khi thiếu mã / mã sai
- [x] Build chạy sạch
- [ ] Chạy thử trên **điện thoại thật** (`zmp start -D`, cần quét QR)
- [ ] `zmp deploy` + gửi xét duyệt — chờ mẫu ZBS cho hoá đơn (mã mẫu + tham số)

## Còn thiếu để chạy thật

**Mẫu ZBS cho hoá đơn**: mã mẫu + tên tham số + cấu hình nút CTA trỏ về Mini App
kèm `?code=`. Hiện mới có mẫu `636121` (tin chào mừng hợp đồng) và `636478` (OTP)
— xem `docs/ZALO-MESSAGING.md`.

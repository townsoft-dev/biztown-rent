# Zalo Mini App — BizTown Rent Manager

Mini App **chỉ làm đúng một việc**: nhận mã tra cứu hoá đơn từ nút CTA trong tin
ZBS, rồi hiện ảnh hoá đơn do Supabase sinh ra.

## Vì sao mỏng như vậy

Toàn bộ nội dung hoá đơn (bố cục, số tiền, mã QR VietQR) do Edge Function
`i` dựng ra dưới dạng **ảnh PNG**, sinh lại mỗi lần gọi từ dữ liệu mới nhất.
Mini App không dựng lại gì cả — chỉ hiện ảnh đó.

Hệ quả: **sửa hoá đơn chỉ cần sửa phía Supabase, Mini App tự đổi theo**, không
phải build lại và không phải xin Zalo duyệt lại. Đây là lý do chọn cách này
(dungtv chốt 18/09/2026).

## Mini App biết đang xem hoá đơn nào bằng cách nào

Không cần biết người dùng là ai. **Mã tra cứu chính là danh tính** — mỗi hoá đơn
mang một mã ngẫu nhiên 12 ký tự đã gắn sẵn người thuê/phòng/kỳ.

```
Nút CTA trong tin ZBS   →   mở Mini App kèm ?code=<ma_tra_cuu>
                        →   getRouteParams() đọc mã
                        →   hiện .../functions/v1/i/<ma_tra_cuu>
```

`getRouteParams()` trả `Record<string, string>` các tham số truy vấn của trang
hiện tại, có từ `zmp-sdk` 2.11.0 — xem
https://docs.zaloplatforms.com/docs/MA/api/routing/getRouteParams

## Chạy thử

```bash
cd miniapp
npm install
npm start          # zmp-cli mở trình giả lập
```

Mở kèm tham số để thử:  `?code=85J8ZPGRGBPT`

## Còn thiếu để phát hành

- **Mini App ID** của Zalo (điền vào `app-config.json`, khoá `app.id`) — phải tạo
  trên Zalo Developer bằng chính tài khoản sở hữu OA, nếu không nút CTA sẽ bị
  xếp nhóm phí cao hơn (xem `docs/ZALO-MESSAGING.md` mục 2.1 vướng mắc #2).
- **Mẫu ZBS cho hoá đơn** (mã mẫu + tên tham số) — hiện mới có mẫu `636121`
  (tin chào mừng hợp đồng) và `636478` (OTP).

# changelog/ — Nhật ký thay đổi của developer

Nhật ký chi tiết các thay đổi trong quá trình phát triển: ngày, giờ, ai làm, sửa tính năng gì, sửa những gì cụ thể.

Khác với [`docs/CHANGELOG.md`](../docs/CHANGELOG.md) (tóm tắt thay đổi theo bản release, hướng tới người dùng cuối), folder này là **lịch sử chi tiết cho developer/team**, ghi lại từng lần thay đổi.

## Quy ước

- Mỗi ngày một file: `YYYY-MM-DD.md`.
- Trong ngày, mỗi lần thay đổi thêm một entry theo mẫu:

```
## HH:MM — <tên người thực hiện>

**Tính năng/khu vực**: <ví dụ: Contract, Auth, Bill...>

**Thay đổi**:
- <mô tả cụ thể đã sửa/thêm/xóa gì>
```

- Entry mới nhất trong ngày thêm ở **cuối file** (theo thứ tự thời gian tăng dần).
- Ghi cả các thay đổi nhỏ (config, docs) lẫn lớn (tính năng mới, sửa bug) — miễn là có ảnh hưởng đến codebase.

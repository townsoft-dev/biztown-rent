# DESIGN.md — Hướng dẫn thiết kế
> **Trạng thái tài liệu:** Version 3  **Last updated:** 2026-09-09 — đồng bộ trạng thái Figma mới nhất (Dream tự sửa trực tiếp + Claude/Cowork sửa cùng ngày, xem `changelog/2026-09-09.md` mục 13:45).

## Nguồn thiết kế

File thiết kế UI/UX (Figma export, mockup, hệ thống thiết kế) được quản lý tại thư mục [design/], trong cùng repo.

- **Figma chính thức:** https://www.figma.com/design/AElzfTBuL8YyA8OJ85f7aX/BizTown-Rent-Manager-%E2%80%94-MVP-Wireframes?node-id=133-57 — ✅ **đã build lại theo Version 3** (cập nhật 08/09/2026): 32 màn/4 tab, Home tab tổ chức lại đúng 6 màn H-01→H-06 theo [SCREEN-SPEC.md](SCREEN-SPEC.md) (gộp 3 màn ghi/xem/sửa chỉ số vào H-06, xoá màn "House Detail (Readings)" trùng lặp), bỏ hiển thị mã đồng hồ theo phòng (đúng BR-READ-01), thêm field `recurringFees` mặc định ở House/Room, prototype (7 flow, 224+ interaction) đã nối lại đầy đủ theo cấu trúc mới, và toàn bộ trích dẫn `BR-xxx` trên trang đã rà soát khớp [BUSINESS-RULES.md](BUSINESS-RULES.md). Có thể dùng trực tiếp làm nguồn thiết kế khi bắt đầu code UI theo Version 3.
  - ✅ **Cập nhật 09/09/2026 — đã đồng bộ thiết kế mới nhất lên repo**: file Figma hiện phản ánh đúng bản mới nhất, kết hợp cả (1) phần Dream tự chỉnh sửa trực tiếp trên Figma (thêm/xoá phần tử, căn chỉnh lại vị trí...) và (2) phần Claude/Cowork đã sửa cùng ngày — dòng "Ngôn ngữ / Language" ở P-01, rà soát + bổ sung prototype toàn bộ 32 màn, tách 2 tab House detail/Rooms + nút Edit ở H-03/H-04, đổi bộ lọc nhà ở T-02 từ chip sang dropdown (chi tiết từng mục xem `changelog/2026-09-09.md`). Không có phần nào của 2 nguồn sửa đổi bị ghi đè lên nhau.
- **Mockup bố cục tham khảo (mới):** [`design/mockups/biztownv3mockup.html`](../design/mockups/biztownv3mockup.html) — mockup HTML tĩnh do Dream cung cấp (08/09/2026), minh hoạ bố cục 4 tab trên khung điện thoại. Đây là **nguồn tham khảo chính thức cho layout & component** khi build lại Figma — mọi token màu/typography/spacing/component đã được rút ra và ghi vào [DESIGN-SYSTEMS.md](DESIGN-SYSTEMS.md) mục 2-6.
  - ⚠️ **Không copy nguyên si 2 chỗ sau khi build Figma** — mockup chỉ minh hoạ bố cục, phần dữ liệu/flow đứng sau bị sai so với business rule đã chốt:
    1. Màn ghi chỉ số nhóm theo "đồng hồ" dùng chung nhiều phòng — thực tế **không có thực thể đồng hồ**, chỉ số gắn thẳng vào từng phòng (BR-READ-01).
    2. Dải chip kỳ hoá đơn ngụ ý hệ thống tạo sẵn hoá đơn thật cho mọi kỳ tương lai — thực tế **kỳ tương lai chỉ là bản xem trước (Scheduled), không có hoá đơn thật** (BR-BILL-12).
  - Chi tiết từng component và chỗ cần sửa xem [DESIGN-SYSTEMS.md](DESIGN-SYSTEMS.md) mục 6 (đánh dấu ⚠️ ở từng mục liên quan).

## Nguyên tắc

- Đồng bộ giữa Figma và code: khi thiết kế thay đổi, cập nhật lại file này để phản ánh design system mới nhất (màu sắc, spacing, component chuẩn...).

design system: [DESIGN-SYSTEMS](DESIGN-SYSTEMS.md)

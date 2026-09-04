# Design SYSTEM— BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 2  **Last updated:** 2026-09-03 — cập nhật Bottom Navigation & trạng thái hoá đơn theo scope Phase 1 mới (Landlord + Manager, bỏ Tenant app). Xem [DECISIONS.md](DECISIONS.md).

---

## 0. Ngôn ngữ UI
**tiếng Anh là ngôn ngữ hiển thị chính thức của sản phẩm**— đa ngôn ngữ (thêm tiếng Việt) được cân nhắc cho Phase 2

---

## 1. Assets nguồn (từ project)

| File | Dùng cho |
|---|---|
| `biztownrentmanagerlockup2x.png` | Logo lockup chính (nền sáng) |
| `biztownrentmanagerlockuponnavy2x.png` | Logo lockup trên nền navy (dark) |
| `biztownrentmanagerbanner2x.png` / `biztownrentmanagerbannernourl2x.png` | Banner |
| `biztownrenticon2x.png` | Icon glyph — biểu tượng "Rent" (cột màu cam) |
| `biztowninvoiceicon2x.png` | Icon glyph — biểu tượng "Invoice/Hoá đơn" (cột màu cam đất/san hô) |

Sẽ bổ sung file svg sau
---

## 2. Bảng màu (Color Palette)

### 2.1 Màu trích xuất từ logo (pixel-accurate)

| Token đề xuất | Hex | Vai trò quan sát được |
|---|---|---|
| `color-primary` (Navy) | `#23305E` | Màu chủ đạo — nền icon app, chữ "Biz" đậm, đường kẻ dưới logo |
| `color-secondary` (Slate) | `#5A6B8A` | Chữ "Town"/"RENT MANAGER", cột biểu đồ giữa trong icon |
| `color-secondary-light` | `#868DA7` | Biến thể nhạt hơn của Slate — dùng cho text phụ/disabled |
| `color-accent-orange` | `#EF9F27` | Cột màu cam trong icon "Rent" — dùng làm accent chính (CTA, highlight) |
| `color-accent-coral` | `#F0997B` | Cột màu san hô trong icon "Invoice" — accent phụ, có thể dùng riêng cho module Hoá đơn |
| `color-neutral-200` | `#B9BDCC` | Xám lavender nhạt — cột thứ 3 trong icon, dùng cho border/divider/disabled bg |

### 2.2 Đề xuất mở rộng — Semantic colors *(placeholder, cần Dream duyệt)*

| Token | Hex đề xuất | Dùng cho |
|---|---|---|
| `color-success` | `#2E9E5B` `TBD` | Trạng thái "Đã thanh toán", "Đã xử lý" |
| `color-warning` | `#EF9F27` (trùng accent-orange) | Trạng thái "Chờ xác nhận" |
| `color-error` | `#D9483C` `TBD` | Trạng thái "Quá hạn", lỗi validate |
| `color-info` | `#5A6B8A` (trùng secondary) | Thông báo chung |
| `color-bg-default` | `#FFFFFF` | Nền chính (light mode) |
| `color-bg-subtle` | `#F5F6F9` `TBD` | Nền card/section |
| `color-text-primary` | `#23305E` | Text chính |
| `color-text-secondary` | `#5A6B8A` | Text phụ |

Cân nhắc darkmode ở phase 2

---

## 3. Typography

| Style | Font (đề xuất) | Size | Weight | Dùng cho |
|---|---|---|---|---|
| Display | (geometric sans, giống logo) | 28px | Bold (700) | Số liệu lớn trên Dashboard (VD: tổng doanh thu) |
| H1 | geometric sans | 24px | Bold (700) | Tiêu đề màn hình |
| H2 | geometric sans | 20px | SemiBold (600) | Tiêu đề section |
| Body | Inter/Roboto | 16px | Regular (400) | Nội dung chính |
| Body Small | geometric sans | 14px | Regular (400) | Text phụ, caption |
| Label / Overline | geometric sans | 12px | Medium (500), letter-spacing rộng | Nhãn dạng "RENT MANAGER" giống logo (uppercase, tracked) |

---

## 4. Spacing & Layout

Đề xuất dùng hệ **8px grid** (chuẩn phổ biến cho mobile):

`4 / 8 / 12 / 16 / 24 / 32 / 48` (px)

- Padding màn hình mặc định: `16px`
- Khoảng cách giữa các card/section: `16-24px`
- Bo góc (border-radius): logo dùng góc bo rất lớn kiểu "squircle" (~22% chiều rộng) cho icon app → đề xuất bo góc **12-16px** cho card/button trong UI để đồng bộ cảm giác "bo tròn mềm mại" mà vẫn hợp lý cho mobile.

---

## 5. Iconography

- Icon glyph hiện có (Rent, Invoice) theo phong cách: **flat, đơn giản, dùng dạng cột biểu đồ (bar chart)** để biểu trưng số liệu/tài chính, bo góc mềm, nền màu navy đặc trưng.

---

## 6. Components (khung sườn — cần thiết kế chi tiết trong Figma)

| Component | Trạng thái/Ghi chú |
|---|---|
| Button (Primary/Secondary/Text) |màu primary dùng Navy . Navy cho nút chính (đồng bộ thương hiệu), Orange cho nhấn mạnh/CTA khẩn (VD: "Pay Now"). |
| Input field (text, number, date picker) | xám nhạt |
| Status badge (cho trạng thái Hoá đơn) | **Cập nhật 2026-09-03** (trạng thái hoá đơn đổi tên — xem [BUSINESS-RULES](BUSINESS-RULES.md) BR-PAY-03): Draft = neutral/xám, Sent = `color-info`/xanh dương nhạt, Collected = `color-success` (xanh), Overdue = `color-error` (đỏ) |
| Card (Phòng, Hoá đơn, Yêu cầu) | xám nhạt |
| Bottom Navigation Bar | **Cập nhật 2026-09-03:** 1 bộ 5 tab dùng chung cho cả Landlord và Manager (khác nhau ở phạm vi dữ liệu, không khác cấu trúc tab): House/Room Management, Tenant Management, Contract Management, Bill Management, User Setting — xem [SCREEN-SPEC](SCREEN-SPEC.md) mục 1.2. Không còn bộ tab riêng cho Tenant (không có app). |
| Empty states, Loading states | đen |

---

## 7. Accessibility
- Cỡ chữ tối thiểu, kích thước touch target (≥44x44pt) — áp dụng chuẩn iOS HIG/Material Design
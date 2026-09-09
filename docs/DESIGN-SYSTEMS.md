# Design SYSTEM— BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 3  **Last updated:** 2026-09-08 — cập nhật Bottom Navigation theo Version 3 (5 menu → 4 tab: Home, Tenant & Contract, Bills, Profile) + bổ sung token/component cụ thể theo mockup HTML tham khảo `design/mockups/biztownv3mockup.html` (Dream cung cấp 08/09). Xem [DECISIONS.md](DECISIONS.md).

---

## 0. Ngôn ngữ UI
**Cập nhật 09/09/2026 — đổi hướng, sửa lại cùng ngày (đợt 2):** App khi build thật hỗ trợ **3 ngôn ngữ ngay từ Phase 1 — English / Tiếng Việt / 한국어** (ngôn ngữ khác để Phase 2), người dùng chọn ngay tại màn Profile **P-01** (1 dòng "Ngôn ngữ / Language", inline picker — **không phải màn riêng**, xem `FR-MGR-05`/`NFR-02`). Mặc định theo ngôn ngữ máy lúc cài lần đầu (fallback English nếu máy dùng ngôn ngữ ngoài 3 lựa chọn trên). Copy/microcopy cần chuẩn bị sẵn 3 bộ string (EN/VI/KO) ngay khi code UI, không chờ Phase 2 như dự kiến trước đó.

**Bản thiết kế (Figma/FigJam) vẫn dựng bằng tiếng Anh** làm ngôn ngữ chuẩn cho wireframe/hi-fi — không cần dựng lại 2 bản ngôn ngữ trên Figma, việc song ngữ xử lý ở tầng code (i18n).

**Lưu ý phân biệt (mới, 09/09/2026 — đợt 3):** 3 ngôn ngữ ở trên chỉ áp dụng cho **giao diện tài khoản** (chủ nhà/quản lý, chọn ở P-01). Nội dung SMS/Zalo gửi cho **Tenant** (hoá đơn, nhắc thanh toán) là một khái niệm hoàn toàn độc lập — cố định **cố định tiếng Anh và tiếng Việt ở Phase 1, tiếng việt bên trên tiếng anh bên dưới** ở Phase 1 bất kể người tạo hoá đơn đang dùng ngôn ngữ nào, xem `BR-NOTI-07`.

---

## 1. Assets nguồn

### 1.1 Logo (`design/Logo/`)

| File | Dùng cho |
|---|---|
| [`biztown-rent-manager-lockup.svg`](../design/Logo/biztown-rent-manager-lockup.svg) | Logo lockup chính (nền sáng) |
| [`biztown-rent-manager-lockup-on-navy.svg`](../design/Logo/biztown-rent-manager-lockup-on-navy.svg) | Logo lockup trên nền navy (dark) |
| [`biztown-rent-manager-lockup-reversed.svg`](../design/Logo/biztown-rent-manager-lockup-reversed.svg) | Logo lockup đảo màu — dùng trên nền tối/ảnh, biến thể ngoài 2 bản trên |
| [`biztown-rent-manager-banner.svg`](../design/Logo/biztown-rent-manager-banner.svg) | Banner |
| [`biztown-wordmark.svg`](../design/Logo/biztown-wordmark.svg) | Wordmark — chỉ chữ "BizTown Rent Manager", không kèm icon |
| [`biztown-rent-icon.svg`](../design/Logo/biztown-rent-icon.svg) | Icon glyph — biểu tượng "Rent" (cột màu cam) |
| [`biztown-invoice-icon.svg`](../design/Logo/biztown-invoice-icon.svg) | Icon glyph — biểu tượng "Invoice/Hoá đơn" (cột màu cam đất/san hô) |

### 1.2 Mockup bố cục tham khảo (`design/mockups/`) — Mới 2026-09-08

| File | Dùng cho |
|---|---|
| [`biztownv3mockup.html`](../design/mockups/biztownv3mockup.html) | Mockup HTML tĩnh (Dream cung cấp) minh hoạ bố cục 4 tab của Version 3 trên khung điện thoại — **nguồn tham khảo chính thức cho layout & component** khi build lại Figma wireframes 32 màn. Không phải file thiết kế chính thức, không đầy đủ (chỉ dựng 1 vài màn đại diện mỗi tab), và **2 chỗ trong mockup mô tả sai mô hình dữ liệu đã chốt** — xem cảnh báo ở mục 6.7 trước khi dùng làm mẫu build Figma. |

---

## 2. Bảng màu (Color Palette)

### 2.1 Màu trích xuất từ logo (pixel-accurate)

| Token đề xuất | Hex | Vai trò quan sát được |
|---|---|---|
| `color-primary` (Navy) | `#23305E` | Màu chủ đạo — nền icon app, chữ "Biz" đậm, đường kẻ dưới logo, nền Topbar |
| `color-secondary` (Slate) | `#5A6B8A` | Chữ "Town"/"RENT MANAGER", cột biểu đồ giữa trong icon, text phụ (card-sub, label) |
| `color-secondary-light` | `#868DA7` | Biến thể nhạt hơn của Slate — text phụ cấp 2 (card-meta), placeholder, disabled |
| `color-accent-orange` | `#EF9F27` | Cột màu cam trong icon "Rent" — accent chính: FAB, CTA khẩn, badge "Sắp hết hạn", trạng thái "kỳ hiện tại" trên dải chip kỳ |
| `color-accent-coral` | `#F0997B` | Cột màu san hô trong icon "Invoice" — accent phụ: badge "Đang sửa chữa", có thể dùng riêng cho module Hoá đơn |
| `color-neutral-200` | `#B9BDCC` | Xám lavender nhạt — border card/input, chip viền, disabled bg, viền chip "kỳ tương lai" (dashed) |

### 2.2 Semantic colors — **đã chốt qua mockup** (không còn placeholder)

> Mockup `biztownv3mockup.html` xác nhận cụ thể các giá trị dưới đây bằng code thật (CSS variables), thay thế các dòng "TBD"/"trùng secondary" trước đó.

| Token | Hex | Dùng cho |
|---|---|---|
| `color-success` | `#2E9E5B` | Badge "Đã thuê" (phòng), "Active" (hợp đồng), "Collected" (hoá đơn) — nền nhạt `#E4F5EA` |
| `color-warning` | `#EF9F27` (trùng accent-orange) | Badge "Sắp hết hạn" — nền nhạt `#FDF1DE` |
| `color-error` | `#D9483C` | Badge "Overdue", lỗi validate — nền nhạt `#FBE7E5` |
| `color-info` | `#3E6BD9` | **Mới, tách khỏi `color-secondary`** — dành riêng cho badge "Sent" (hoá đơn đã gửi, chưa thu) và trạng thái tương tự, nền nhạt `#E8EEFD`. Trước đây đề xuất trùng Slate — mockup cho thấy cần 1 xanh dương rõ ràng hơn để không lẫn với text phụ màu Slate |
| `color-bg-default` | `#FFFFFF` | Nền chính (light mode), nền card |
| `color-bg-subtle` | `#F5F6F9` | Nền content area (đã xác nhận qua mockup, không còn `TBD`) |
| `color-text-primary` | `#23305E` | Text chính, giá trị (value) trong bảng chi tiết |
| `color-text-secondary` | `#5A6B8A` | Text phụ |
| `color-border-subtle` | `#EEF0F5` | **Mới** — viền card/detail-block, đường kẻ ngăn cách (dùng nhiều hơn `color-neutral-200`, nhạt hơn) |

Cân nhắc darkmode ở Phase 2.

---

## 3. Typography — **đã chốt qua mockup: dùng 1 font family duy nhất, Inter**

> Trước đây đề xuất tách riêng 1 font "geometric sans giống logo" cho tiêu đề và Inter/Roboto cho nội dung (`TBD`, chưa xác nhận). Mockup dùng **Inter** (Google Fonts, weight 400/500/600/700/800) cho toàn bộ UI — tiêu đề chỉ khác body ở size/weight, không đổi font family. Chốt theo hướng này để đơn giản hoá (1 font duy nhất, dễ nhúng vào Flutter qua `google_fonts` package hoặc `.ttf` local), trừ khi Dream xác nhận muốn 1 font riêng cho brand.

| Style | Font | Size | Weight | Dùng cho |
|---|---|---|---|---|
| Số liệu lớn (Stat) | Inter | 16px | Bold (700) | Số liệu tổng hợp dạng "Stat card" (VD: tổng số phòng, tổng tiền kỳ này) |
| Screen Title (Topbar) | Inter | 19px | Bold (700) | Tiêu đề trên Topbar navy của từng màn hình |
| Card Title | Inter | 14px | Bold (700) | Tiêu đề dòng trong Card (tên phòng, tên hợp đồng...) |
| Body | Inter | 12–13px | Regular (400) / SemiBold (600) cho giá trị | Nội dung chính, card-sub, detail-block value |
| Body Small / Meta | Inter | 11–11.5px | Regular (400) | card-meta, mc-sub, thời gian tương đối |
| Label / Section Header | Inter | 12px | Bold (700), uppercase, letter-spacing 0.05em | Nhãn section (VD "NHÀ / DÃY TRỌ CỦA BẠN") |
| Badge / Chip | Inter | 10.5–11.5px | Bold (700) / SemiBold (600) | Badge trạng thái, chip filter |
| Button | Inter | 11.5–12.5px | Bold (700) / SemiBold (600) | Label nút bấm |

> Cỡ Display 28px/H1 24px/H2 20px của bản đề xuất cũ (dùng cho số liệu dashboard/tiêu đề lớn) vẫn giữ làm tham khảo cho các màn cần nhấn mạnh số liệu hơn (ngoài phạm vi mockup hiện có) — xem lại khi build màn thật.

---

## 4. Spacing & Layout — cập nhật theo giá trị cụ thể trong mockup

Giữ hệ **8px grid**, nhưng bo góc và khoảng cách quan sát được trong mockup **nhỏ hơn** đề xuất cũ (12–16px) ở phần lớn component — chỉ card/detail-block lớn mới dùng 14px:

| Thành phần | Bo góc (border-radius) | Ghi chú |
|---|---|---|
| Card, Detail block, Meter/Reading card | `14px` | Khung chứa nội dung chính |
| Segmented control (khung ngoài) | `12px` | Nút con bên trong `9px` |
| Search bar, Chip filter dạng thẳng | `12px` | |
| Chip pill (filter, status thường), Badge | `100px` (pill tròn hoàn toàn) | |
| Button (CTA, primary/ghost/danger) | `11px` | |
| Input field | `9px` | |
| FAB | `16px` (squircle, không tròn hoàn toàn) | Đồng bộ tỉ lệ bo góc icon app trong logo |
| Timeline/period chip (dải kỳ hoá đơn) | `9px` | Xem mục 6.6 |
| Thumb icon vuông trong Card | `11px` | Avatar tròn dùng `50%` |

- Padding màn hình mặc định (content area): `14px` (mockup dùng 14px, gần với đề xuất cũ 16px — có thể giữ 16px khi lên Figma thật cho dễ căn lưới 8px).
- Khoảng cách giữa card: `9–10px` (nhỏ hơn đề xuất cũ 16-24px — mật độ thông tin cao hơn, phù hợp app quản lý nhiều danh sách).
- Border card/detail-block: `1px solid #EEF0F5` (viền rất nhạt, gần như chỉ để tách nền chứ không nổi bật) + `box-shadow` rất nhẹ (`0 1px 2px rgba(20,25,46,.06)`).

---

## 5. Iconography

- Icon glyph thương hiệu (Rent, Invoice) theo phong cách: **flat, đơn giản, dạng cột biểu đồ (bar chart)**, bo góc mềm, nền navy đặc trưng — dùng cho icon app/marketing, không dùng làm icon hành động trong UI.
- Icon hành động/UI trong Figma: **Material 3 Design Kit** (đã add vào file Figma) cho icon chuẩn (search, notifications, back, add, location_on, person, check, delete, photo, groups, schedule...); pictogram tự dựng cho icon miền nghiệp vụ mà bộ này thiếu (home, receipt, điện/nước, sửa chữa) — xem `claude/design.md` (project) mục 5 để biết danh sách đầy đủ.
- Mockup dùng **emoji làm placeholder icon** (🏠 🔌 💧 🧾 👤...) — chỉ để dựng nhanh, **không dùng emoji trong Figma/production**, phải thay bằng icon thật từ Material 3 Design Kit hoặc pictogram tương ứng khi build màn chính thức.

---

## 6. Components — chi tiết theo mockup tham khảo

> Đây là bản mô tả các component đã xuất hiện trong `biztownv3mockup.html`, dùng làm cơ sở dựng lại trong Figma. Với mỗi component, phần "⚠️" (nếu có) là chỗ mockup cần sửa lại theo business rule đã chốt trước khi build Figma thật — xem thêm mục 6.7.

### 6.1 Topbar (header màn hình)
Nền `color-primary` (navy), chữ trắng. Cấu trúc: dòng chào nhỏ (optional, chỉ ở màn gốc mỗi tab) + tiêu đề lớn (19px/700) + dòng phụ (12px, màu `#c9cee0`). Nút back (nếu có, màn con) là hình tròn nền trắng mờ `rgba(255,255,255,.14)` bên trái tiêu đề; chuông thông báo là hình tròn nền trắng mờ `rgba(255,255,255,.12)` góc phải trên.

### 6.2 Segmented control
Dùng để chuyển 2 view trong cùng 1 tab (VD Phòng/Đồng hồ trong Home, Người thuê/Hợp đồng trong Tenant & Contract). Nền xám `#e7e9f1`, bo góc 12px, nút active có nền trắng + shadow nhẹ, nút inactive nền trong suốt, chữ Slate.

### 6.3 Search bar & Chip filter
Search bar: icon kính lúp + placeholder, nền trắng, viền `color-neutral-200`. Chip filter: hàng ngang cuộn được, pill bo tròn hoàn toàn, active = nền navy chữ trắng, inactive = nền trắng viền `color-neutral-200` chữ Slate.

### 6.4 Card (list item)
Cấu trúc chuẩn: thumb icon vuông bo góc 11px (màu nền theo ngữ cảnh, ví dụ mỗi nhà 1 màu khác nhau để phân biệt nhanh) + phần thân gồm dòng tiêu đề (kèm badge trạng thái canh phải), dòng phụ, dòng meta (icon nhỏ + text, có thể nhiều mục cách nhau). Toàn bộ card cùng 1 style dùng cho House, Room, Tenant, Contract, Invoice — chỉ đổi icon/màu thumb và nội dung.

### 6.5 Status badge — bảng màu đã chốt

| Badge | Nền | Chữ | Dùng cho |
|---|---|---|---|
| Empty (phòng trống) | `#EEF0F5` | Slate | Room.status = Empty |
| Occupied (đã thuê) | `#E4F5EA` | Success | Room.status = Occupied |
| UnderRepair (đang sửa) | `#FDEEE8` | Coral | Room.status = UnderRepair |
| Active (hợp đồng) | `#E4F5EA` | Success | Contract đang hiệu lực |
| Sắp hết hạn | `#FDF1DE` | Orange (warning) | Contract còn ≤ ngưỡng cảnh báo |
| Ended | `#EEF0F5` | Slate | Contract đã kết thúc |
| Draft (hoá đơn) | `#EEF0F5` | Slate | Invoice.status = Draft |
| Sent (hoá đơn) | `#E8EEFD` | Info `#3E6BD9` | Invoice.status = Sent |
| Collected (hoá đơn) | `#E4F5EA` | Success | Invoice.status = Collected |
| Overdue (hoá đơn) | `#FBE7E5` | Error | Invoice quá `dueDate` còn Sent (derived, không lưu DB) |

### 6.6 Dải chip theo kỳ (Timeline/period chip row)
Hàng ngang cuộn được, mỗi chip đại diện 1 kỳ (hình chữ nhật bo góc 9px, ~34×30px): kỳ đã `Collected` = nền success; đã `Sent` chưa thu = nền info; `Overdue` = nền error; **kỳ hiện tại** = nền trắng, chữ + viền cam (outline nổi bật); **kỳ tương lai** = nền trắng, viền xám đứt nét (`dashed`), chữ xám nhạt.

> ⚠️ **Sửa khi build Figma:** mockup chú thích dải chip này là "hệ thống đã tạo sẵn 1 dòng hoá đơn thật cho mỗi kỳ ngay từ lúc ký hợp đồng". Theo BR-BILL-12 ([BUSINESS-RULES.md](BUSINESS-RULES.md)), **chỉ các chip kỳ đã qua/kỳ hiện tại (Collected/Sent/Overdue/current) là hoá đơn thật**; mọi chip "kỳ tương lai" (viền đứt nét) chỉ là **bản xem trước dựng tạm (T-09 Invoice Schedule Preview)**, KHÔNG có bản ghi `tb_invoice` thật đứng sau — giữ nguyên style hiển thị, chỉ đổi lại phần chú thích/logic đằng sau.

### 6.7 Reading/Meter card (thẻ ghi chỉ số)
Icon tròn/vuông theo loại (⚡ điện = orange, 💧 nước = info) + tiêu đề + badge trạng thái "Đã ghi"/"Chưa ghi" (done = success, todo = orange) + 2 ô: chỉ số cũ (read-only, nền xám) và chỉ số mới (input, viền cam khi focus) + dòng tính lượng tiêu thụ (success, in đậm). Có kèm 1 `progress-wrap` tổng (thanh tiến độ cam) hiển thị "đã ghi x/y" ở đầu màn.

> ⚠️ **Sửa khi build Figma:** mockup nhóm các thẻ này theo **"đồng hồ" (DHĐ-01, DHN-01...)**, có đồng hồ gắn chung nhiều phòng. Theo BR-READ-01 ([BUSINESS-RULES.md](BUSINESS-RULES.md)) và [DATABASE.md](DATABASE.md), **không có thực thể công tơ/đồng hồ, không có đồng hồ dùng chung nhiều phòng** — chỉ số gắn thẳng vào từng PHÒNG. Khi build Figma: đổi tiêu đề mỗi thẻ từ "DHĐ-01 · P.101, P.102" thành liệt kê **theo từng phòng** (VD "P.101 — Điện"), giữ nguyên toàn bộ style thẻ/input/progress bar.

### 6.8 Stat row (thống kê nhanh)
2 ô ngang bằng nhau, mỗi ô: số lớn (16px/700, navy) + label nhỏ (10.5px, Slate). Dùng ở đầu Home (tổng phòng/phòng trống) và đầu Bills (tổng kỳ này/chưa thu).

### 6.9 FAB (nút nổi thêm mới)
Hình vuông bo góc 16px (không phải tròn), 48×48px, nền `color-accent-orange`, icon "+" trắng, đặt góc dưới-phải, nổi trên bottom nav (`bottom: 78px` để không đè lên nav).

### 6.10 Bottom Navigation Bar
4 tab cố định: Home, Tenant & Contract (nhãn rút gọn "Tenant & HĐ"), Bills, Profile — nền trắng, viền trên nhạt `#eceef3`, icon 19px + label 10px/600, active = màu navy, inactive = Slate-light. Dùng chung 1 bộ cho mọi tài khoản — khác nhau ở phạm vi dữ liệu/vai trò theo từng nhà, không khác cấu trúc tab (xem [SCREEN-SPEC](SCREEN-SPEC.md) mục 1.2).

### 6.11 Profile: Profile head + Menu row
Đầu trang Profile: avatar tròn (chữ viết tắt tên, nền navy) + tên + SĐT + 1 pill nhỏ hiển thị vai trò. Bên dưới là danh sách `menu-row` (icon + label bên trái, mũi tên `›` bên phải), nhóm theo `section-label`; dòng "Đăng xuất" dùng biến thể `danger` (chữ đỏ).

> ⚠️ Mockup còn ghi nhãn vai trò kiểu cũ **"Main Manager (Chủ trọ)"** cố định trên 1 tài khoản, và ẩn/hiện mục "Quản lý tài khoản Manager"/"Số tài khoản nhận tiền" theo **loại tài khoản**. Theo mô hình Version 3 ([BUSINESS-RULES.md](BUSINESS-RULES.md) BR-ROLE), vai trò không cố định theo tài khoản mà theo **từng Nhà/Dãy trọ** — khi build Figma, pill vai trò và việc ẩn/hiện các mục "Người quản lý nhà" (P-05)/"Tài khoản ngân hàng" (P-03) cần tính theo nhà đang chọn (nếu tài khoản có ít nhất 1 nhà `role=owner` thì vẫn thấy các mục này), không phải theo 1 vai trò gắn cứng toàn cục.

### 6.12 Detail block & CTA row (Contract Detail)
Khối thông tin dạng bảng label/value (`detail-block`), mỗi dòng cách nhau bằng viền chấm nhạt, label bên trái màu Slate, value bên phải màu navy đậm. Bên dưới là hàng nút hành động `cta-row` (primary navy / ghost xám / danger đỏ), tự xuống dòng khi không đủ chỗ (flex-wrap).

### 6.13 Mini-profile
Card nhỏ gọn (avatar tròn 40px + tên đậm + dòng phụ), dùng để tóm tắt Tenant/Room ngay trong Contract Detail mà không cần mở màn riêng.

### 6.14 House group header (Bills)
Dùng để nhóm danh sách hợp đồng theo Nhà trong tab Bills: icon 🏠 + tên nhà (13px/700, navy) + pill đếm số hợp đồng (`#EEF0F5`, Slate) — khớp đúng yêu cầu B-01 "nhóm theo Nhà → theo Hợp đồng" ở [SCREEN-SPEC.md](SCREEN-SPEC.md).

---

## 7. Accessibility
- Cỡ chữ tối thiểu, kích thước touch target (≥44x44pt) — áp dụng chuẩn iOS HIG/Material Design.
- Riêng phần badge/chip trong mockup dùng cỡ chữ khá nhỏ (10.5–11.5px) — cần kiểm tra contrast + độ dễ đọc thực tế trên thiết bị thật khi lên Figma, đặc biệt với badge chữ trên nền màu nhạt.

# BizTown Rent-Manager — Xác minh "Đánh giá Phase 1 (V3) — Đợt 2"

> **Mục đích:** Đối chiếu từng nhận xét trong `PHASE1GAPANALYSISV2.md` (do một phiên Claude khác soạn) với nội dung **thật** của `docs/*.md` (Version 3, 08/09/2026) hiện có trong repo local `biztown-rent`, để xác nhận nhận xét nào đúng, nhận xét nào cần bổ sung, và đề xuất cách sửa cụ thể.
> **Phương pháp:** Đọc trực tiếp `DATABASE.md`, `BUSINESS-RULES.md`, `REQUIREMENTS.md`, `PRODUCT-OVERVIEW.md`, `SCREEN-SPEC.md`, `USER-FLOWS.md`, `DESIGN-SYSTEMS.md`, `CURRENT_STATUS.md`, kịch bản Mr. Han — không suy đoán từ bản tóm tắt.
> **Kết quả tổng quát:** Cả 7 phát hiện + toàn bộ phần "việc đã biết" trong tài liệu gốc đều **kiểm chứng đúng** với nội dung docs hiện tại. Không phát hiện điểm nào bị nói quá hoặc sai. Có **2 điểm nên bổ sung** thêm chi tiết mà bản gốc chưa nêu hết (đánh dấu 🆕 bên dưới).

---

## Bảng tổng hợp

| # | Mức độ | Nhận xét gốc (tóm tắt) | Kết quả kiểm tra | Nên sửa? | Việc cần chốt |
|---|---|---|---|---|---|
| 1 | 🔴 Nghiêm trọng | `tb_tenant` thiếu `houseId` → không áp được RLS theo nhà cho Tenant Pool chưa gắn phòng | ✅ **Đúng.** `DATABASE.md` liệt kê `tb_tenant`: không có `houseId`. `BR-DATA-01` vẫn xếp `tb_tenant` vào nhóm bảng phải RLS theo `houseId`. `FR-TEN-01` xác nhận Tenant Pool "dùng chung theo Nhà/Dãy trọ" | **Có, trước khi viết migration** | Thêm cột `houseId` (bắt buộc) vào `tb_tenant`, chọn ngay lúc tạo (T-02) |
| 2 | 🟠 Cao | `BR-METER-13` (sửa chỉ số đã khoá qua `otherFees` hoá đơn kế tiếp) không áp dụng được cho chỉ số **MOVE_OUT** | ✅ **Đúng** — xác minh lại bằng cách truy chuỗi `previousReadingId`: chỉ số MOVE_OUT luôn là chỉ số **đóng (to)** của hoá đơn cuối cùng khách cũ; bản ghi kế tiếp trong chuỗi phòng (MOVE_IN khách mới, hoặc PERIODIC nếu phòng bỏ trống) mới là "from" của hoá đơn tiếp theo — MOVE_OUT không bao giờ giữ vai trò "from" | **Có, trước khi code phần thanh lý cọc** | Bổ sung 1 dòng vào mục 6 `BUSINESS-RULES.md`: sửa chỉ số MOVE_OUT sau khi đã `settlementConfirmedAt` → ghi đè qua `damageDeduction`/`settlementNote` (đã có sẵn trên `tb_contract`) |
| 3 | 🟠 Cao | Proration (chia theo ngày ở) mới định nghĩa cho **tiền nhà**, chưa cho **phí dịch vụ**/**phí định kỳ** — đúng lỗ hổng mà cả bản V3 sinh ra để né | ✅ **Đúng**, và có thêm 1 bằng chứng: `BR-BILL-08` chỉ nói rõ "tiền nhà chia theo số ngày ở"; nhưng `SCREEN-SPEC.md` (B-02) lại liệt kê "prorate ngày ở nếu có MOVE_IN/MOVE_OUT" như 1 dòng tính chung, tách biệt khỏi "tiền nhà" — **hai tài liệu đang ngầm hiểu khác nhau phạm vi áp dụng prorate**, không chỉ là thiếu sót đơn thuần | **Có, ưu tiên cao nhất cùng #1** | Bổ sung rõ vào `BR-BILL-08`: phí dịch vụ & phí định kỳ có chia theo ngày ở giống tiền nhà không, hay tính theo "ai đang ở lúc chốt kỳ" |
| 4 | 🟡 Trung bình | Phòng cấu hình `FLAT` (khoán) vẫn bị bắt ghi chỉ số hàng tháng dù không dùng để tính tiền | ✅ **Đúng.** `BR-READ-05`/`FR-READ-07` chỉ miễn cho `NOT_BILLED`, không nhắc `FLAT`. `BR-BILL-02` xác nhận `FLAT` dùng thẳng `electricityFlatAmount`, không đọc chỉ số | **Nên**, trừ khi có lý do nghiệp vụ giữ lại (theo dõi mức tiêu thụ thực tế) | Miễn ghi chỉ số cho cả `FLAT` lẫn `NOT_BILLED`, hoặc ghi rõ lý do nếu cố ý giữ |
| 5 | 🟡 Trung bình | Đổi SĐT (P-02) chưa có quy tắc cascade sang `tb_user_house_access.phone` (FK logic, không phải FK thật) | ✅ **Đúng**, và 🆕 **rộng hơn bản gốc mô tả**: `tb_electricity_reading/tb_water_reading.recordedByUserId` cũng là "FK `tb_user.phone`" — nếu đổi SĐT mà không cascade, lịch sử "người ghi chỉ số" của mọi bản ghi cũ cũng sai theo, không chỉ quyền truy cập nhà | **Có, trước khi code Auth** | Chốt: cascade tự động (UPDATE toàn bộ field tham chiếu theo SĐT cũ) hay bắt buộc mời lại/ghi log riêng "SĐT cũ" |
| 6 | 🟢 Thấp/TB | Nhóm nhà theo "chung chủ sở hữu" (H-01) dựa so khớp chuỗi `ownerFullName`, không có định danh thật | ✅ **Đúng.** `DATABASE.md`: `ownerFullName` là text tự do, không link `tb_user` hay bảng nào khác — đúng tình huống Mr. Han (vợ/con đứng tên hộ) | Nên quyết định rõ (không bắt buộc sửa ngay) | Chấp nhận rủi ro gõ sai, hoặc thêm chọn từ danh sách chủ sở hữu đã nhập trước đó |
| 7 | 🟢 Thấp | UI tiếng Anh chưa khớp persona (chủ nhà 40-50+, quen Zalo, người Việt) | ✅ **Đúng.** `DESIGN-SYSTEMS.md` mục 0 và `NFR-02` xác nhận "tiếng Anh là ngôn ngữ hiển thị chính thức" | Chỉ cần xác nhận chủ đích | Xác nhận đây là quyết định có chủ đích (MVP test nội bộ) hay sót lại |

**Việc đã biết (nhắc lại, không phải phát hiện mới)** — đối chiếu `CURRENT_STATUS.md`: cũng xác nhận đúng 100% — Secret key/PAT đã lộ và **chưa rotate** (`## Còn thiếu` dòng cuối), migration Supabase dev vẫn Version 1 (11 bảng), `generate-invoice` cần viết lại hoàn toàn, SMS vendor "đang nghiên cứu" (INT-02), Zalo OA "đang chờ phê duyệt" (INT-01, tiến triển hơn so với "đang nghiên cứu" ở đợt 1), Figma vẫn 22 màn/V2 chưa build lại 32 màn.

---

## Chi tiết & đề xuất sửa theo từng mục

### 1. `tb_tenant` thiếu `houseId` — 🔴 chốt trước khi viết migration
**Trích dẫn xác nhận:** `DATABASE.md` dòng định nghĩa `tb_tenant`: *"fullName, phone, sex, dateOfBirth, mail, idNumber, idPhotoFront, idPhotoBack, note"* — không có `houseId`. `BR-DATA-01` (`BUSINESS-RULES.md` mục 7): *"Mọi bảng nghiệp vụ (`tb_house`, `tb_room`, **`tb_tenant`**, ...) áp RLS theo... `houseId` liên quan"*.

**Vấn đề thật:** Tenant đã gắn hợp đồng thì suy ra được nhà qua `tb_contract → tb_contract_room → tb_room.houseId`, nhưng Tenant **chưa gắn phòng** (đúng nghĩa "Tenant Pool") thì không có đường nào biết thuộc nhà nào → không RLS được → 1 quản lý nhà ông A có thể thấy Tenant Pool ông A không tạo, vi phạm thẳng `BR-DATA-04`.

**Đề xuất sửa:** Thêm cột `houseId` (bắt buộc, FK `tb_house`) vào `tb_tenant`. Ở màn T-02 (Tenant Profile Create), bắt chọn 1 Nhà/Dãy trọ ngay khi tạo hồ sơ (kể cả khi tạo tắt từ T-04 — lúc đó auto-fill theo nhà đang thao tác).

### 2. `BR-METER-13` không xử lý được MOVE_OUT — 🟠 chốt trước khi code thanh lý cọc
**Trích dẫn xác nhận:** `DATABASE.md` mục `invoiceId`: *"hoá đơn mà bản ghi chỉ số này là chỉ số **ĐÓNG kỳ (to)**... chính bản ghi chỉ số này cũng là chỉ số **MỞ kỳ (from)** của hoá đơn kế tiếp, nhưng liên kết đó lưu ở `tb_invoice`"*. Truy theo `previousReadingId`: chuỗi phòng là `... → MOVE_OUT (khách cũ) → MOVE_IN (khách mới) → PERIODIC ...` — hoá đơn đầu tiên của khách mới dùng MOVE_IN làm "from", **không phải** MOVE_OUT. Nếu phòng bỏ trống, bản ghi kế tiếp là PERIODIC của phòng trống — phòng trống không có hợp đồng nên không phát sinh hoá đơn nào để gắn "from" vào.

**Kết luận:** Đúng như bản gốc chỉ ra — MOVE_OUT không bao giờ là "from" của bất kỳ hoá đơn nào, nên cơ chế "thêm dòng vào `otherFees` của hoá đơn kế tiếp" không có hoá đơn nào để bám vào khi cần sửa MOVE_OUT.

**Đề xuất sửa:** Bổ sung 1 rule mới (VD `BR-METER-14`) vào mục 6 `BUSINESS-RULES.md`: nếu phát hiện chỉ số MOVE_OUT ghi sai **sau khi** hợp đồng đã `Ended`/`settlementConfirmedAt` đã chốt → điều chỉnh qua `tb_contract.damageDeduction` + `settlementNote` (ghi rõ lý do, số tiền chênh lệch quy đổi từ sai lệch chỉ số) — tái dùng field settlement sẵn có, không mở lại/ghi đè chỉ số gốc, không phát hành lại hoá đơn cuối.

### 3. Proration chưa phủ phí dịch vụ/phí định kỳ — 🟠 ưu tiên cao nhất cùng #1
**Trích dẫn xác nhận:** `BR-BILL-08`: *"Vào/ra giữa tháng: **tiền nhà** chia theo số ngày ở thực tế... **Điện/nước không cần chia**"* — không nhắc `serviceFeeAmount`/`recurringFees`. Trong khi đó `SCREEN-SPEC.md` B-02 liệt kê tính toán gồm *"tiền nhà nếu đúng chu kỳ, phí dịch vụ, phí định kỳ, **prorate ngày ở nếu có MOVE_IN/MOVE_OUT**"* — đặt "prorate" như 1 mục tách riêng, dễ hiểu nhầm là áp dụng chung cho mọi khoản chứ không riêng tiền nhà. Hai tài liệu đang mô tả không khớp nhau về phạm vi.

**Đề xuất sửa:** Viết rõ trong `BR-BILL-08` (không chỉ dựa vào ngữ cảnh): chọn 1 trong 2 hướng — (a) phí dịch vụ + phí định kỳ **cũng chia theo ngày ở** như tiền nhà (nhất quán, nhưng phức tạp hơn khi có nhiều phòng đổi khách lệch ngày nhau trong 1 hợp đồng), hoặc (b) tính theo "ai đang ở tại ngày chốt kỳ" (đơn giản hơn nhưng có thể bị 1 bên chịu thiệt nếu đổi khách sát ngày chốt). Sau khi chốt, đồng bộ lại câu chữ ở `SCREEN-SPEC.md` B-02 cho khớp.

### 4. `FLAT` vẫn bắt ghi chỉ số — 🟡 nên sửa trừ khi có lý do
**Trích dẫn xác nhận:** `BR-READ-05`: *"Không áp dụng nghiệp vụ ghi chỉ số cho phòng/hợp đồng có `electricityBillingMethod`/`waterBillingMethod = NOT_BILLED`"* — chỉ nhắc `NOT_BILLED`. `BR-BILL-02`: `FLAT` dùng thẳng `electricityFlatAmount`, không đọc chỉ số → dữ liệu ghi vào không phục vụ tính tiền.

**Đề xuất sửa:** Sửa `BR-READ-05`/`FR-READ-07` thành *"...có `billingMethod = NOT_BILLED` hoặc `= FLAT`"*. Nếu Dream/Mr. Han muốn giữ lại việc ghi số cho phòng `FLAT` để theo dõi mức tiêu thụ thực tế (làm căn cứ sau này đề xuất chuyển sang tính theo chỉ số), nên ghi rõ lý do đó thành 1 dòng chú thích trong `BUSINESS-RULES.md` thay vì để ngầm hiểu.

### 5. Đổi SĐT chưa có rule cascade — 🟡 chốt trước khi code Auth (🆕 phạm vi rộng hơn bản gốc)
**Trích dẫn xác nhận:** `DATABASE.md`: `tb_user.phone` là **PK**; `tb_user_house_access.phone` là *"FK logic (không phải ràng buộc khoá ngoại thật)"*. Đọc thêm: `tb_electricity_reading`/`tb_water_reading.recordedByUserId` cũng ghi *"(FK `tb_user.phone`)"* — tức **không chỉ** bảng phân quyền, mà cả lịch sử "ai ghi chỉ số" trên mọi bản ghi chỉ số cũng khoá theo SĐT. `P-02` (`SCREEN-SPEC.md`) chỉ ghi *"SĐT (đổi cần OTP lại)"*, không có rule cascade nào.

**Đề xuất sửa:** Chốt 1 trong 2 hướng ngay trong `BUSINESS-RULES.md` mục 4 hoặc 1 mục mới: (a) đổi SĐT → cascade UPDATE tất cả field tham chiếu (`tb_user_house_access.phone`, `recordedByUserId`, `grantedByUserId`...) sang SĐT mới trong 1 transaction; hoặc (b) đổi SĐT không cascade, giữ nguyên lịch sử theo SĐT cũ (tài khoản mất quyền cũ, phải được mời lại) — đơn giản hơn về code nhưng trải nghiệm kém hơn. Nên chọn (a) nếu đổi SĐT là thao tác hiếm và có thể làm trong 1 Edge Function transaction.

### 6. Nhóm nhà theo tên chủ sở hữu — 🟢 không khẩn, nhưng nên quyết định rõ
**Trích dẫn xác nhận:** `DATABASE.md`: `ownerFullName` là field text tự do trên `tb_house`, không liên kết `tb_user` hay bảng định danh nào. Kịch bản Mr. Han xác nhận đúng use-case: nhà A đứng tên chủ, nhà B đứng tên vợ, nhà C đứng tên con gái — cùng 1 tài khoản quản lý.

**Đề xuất:** Việc này không chặn nghiệp vụ chính (chỉ ảnh hưởng cách hiển thị nhóm ở H-01), có thể chấp nhận rủi ro gõ sai ở Phase 1. Nếu muốn chắc chắn hơn: đổi từ "nhập tự do mỗi lần" sang "chọn từ danh sách tên chủ sở hữu đã dùng trước đó trong cùng tài khoản" (autocomplete, vẫn là text, chỉ khác UX nhập liệu — không cần bảng mới).

### 7. UI tiếng Anh — 🟢 chỉ cần xác nhận chủ đích
**Trích dẫn xác nhận:** `DESIGN-SYSTEMS.md` mục 0: *"tiếng Anh là ngôn ngữ hiển thị chính thức của sản phẩm"*; `NFR-02` (`REQUIREMENTS.md`): *"Giao diện tiếng Anh là ngôn ngữ chính — Đa ngôn ngữ cân nhắc Phase 2"*.

**Đề xuất:** Không cần sửa tài liệu — chỉ cần Dream xác nhận 1 câu trong `DECISIONS.md` giải thích lý do (VD: build MVP tiếng Anh để test nội bộ/gọi vốn trước, tiếng Việt full là ưu tiên Phase 2 chắc chắn) để tránh dev/QA sau này thắc mắc lại.

---

## Thứ tự nên chốt (theo mức ảnh hưởng tới việc viết migration & code sắp tới)

1. **#1 — `tb_tenant.houseId`** (chặn migration DB)
2. **#3 — Phạm vi proration** (đụng đúng mục tiêu KPI "không tính tiền gấp đôi khi đổi khách" — lý do V3 ra đời)
3. **#2 — Cơ chế sửa MOVE_OUT đã khoá** (chặn code phần thanh lý cọc/kết thúc hợp đồng)
4. **#5 — Cascade đổi SĐT** (chặn code Auth/Edge Function mời quản lý)
5. **#4 — Miễn ghi chỉ số cho `FLAT`** (giảm gánh nặng vận hành, không chặn code)
6. **#6, #7** — quyết định nhanh, không chặn tiến độ

Nếu Dream đồng ý với các đề xuất trên, mình có thể trực tiếp sửa `BUSINESS-RULES.md`/`DATABASE.md`/`REQUIREMENTS.md`/`SCREEN-SPEC.md` trong repo để khớp — chỉ cần xác nhận hướng chọn ở mục #2, #3, #4, #5 (mỗi mục có 2 hướng, cần Dream/Mr. Han chốt 1).

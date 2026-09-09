# Requirements — BizTown Rent-Manager
> **Trạng thái tài liệu:** Version 3 **Last updated:** 2026-09-08
> **MoSCoW** (Must / Should / Could / Won't-for-MVP)
> **Thay đổi lớn so với Version 2:** Vai trò không còn gắn vào loại tài khoản — mọi người dùng đăng ký qua **1 luồng duy nhất** (SĐT + OTP), vai trò `owner`/`manager` xác định theo **từng Nhà/Dãy trọ** (thay FR-AUTH-03/04 cũ). Thêm hẳn mục **2.3 — Nghiệp vụ ghi chỉ số điện/nước** (chặn tại flow Hợp đồng). Hợp đồng cho phép **nhiều phòng**. Hoá đơn: tạo hàng loạt, chu kỳ tiền nhà cấu hình được, phí dịch vụ theo m², mã QR VietQR. Xem [DECISIONS.md](DECISIONS.md) 2026-09-08.

---

## 1. Phạm vi & Actors

**Actors:**
- `User` — tài khoản duy nhất cho mọi người dùng app, đăng ký bằng SĐT + OTP. Vai trò của 1 `User` **không cố định** mà xác định theo **từng Nhà/Dãy trọ** (`tb_user_house_access.role`): có thể là **Chủ nhà (`owner`)** ở nhà này và **Quản lý (`manager`)** ở nhà khác — xem [BUSINESS-RULES](BUSINESS-RULES.md) mục 4.
- `Tenant` — Người thuê. **Không phải actor của app** (không đăng nhập, không thao tác trên app) — chỉ là dữ liệu hồ sơ + người nhận SMS/Zalo một chiều.
- `System` — tác vụ tự động (tính hoá đơn đơn lẻ/hàng loạt, sinh mã QR, gửi SMS/Zalo, nhắc thanh toán, nhắc ghi chỉ số).

**Tech scope:** Mobile app iOS + Android, cross-platform, xem [CLAUDE](CLAUDE.md)

## 2. Functional Requirements

### 2.1 Authentication & Phân quyền theo Nhà/Dãy trọ
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-AUTH-01 | Đăng ký tài khoản bằng số điện thoại + OTP + Tạo mật khẩu — **một luồng duy nhất cho mọi người**, không phân biệt "sẽ là chủ nhà" hay "sẽ là quản lý" | Must | Supabase Auth Phone/OTP — xem [ARCHITECTURE](ARCHITECTURE.md). Thay thế hoàn toàn mô hình 2 loại tài khoản của Version 2 |
| FR-AUTH-02 | Đăng nhập lại bằng SĐT/OTP hoặc mật khẩu | Must | Dùng chung 1 màn cho mọi tài khoản |
| FR-AUTH-03 | Chủ nhà (`role=owner` của 1 Nhà/Dãy trọ) mời quản lý bằng **số điện thoại** — hệ thống chỉ ghi 1 dòng quyền truy cập (`role=manager`) cho từng nhà được chọn, **không tạo tài khoản, không đặt mật khẩu hộ**; ghi được cả khi số đó chưa có tài khoản, dòng quyền tự có hiệu lực khi người đó đăng ký/đăng nhập lần đầu | Must | **Thay thế hoàn toàn** FR-AUTH-03 cũ ("Landlord tạo tài khoản Manager") — xem [BUSINESS-RULES](BUSINESS-RULES.md) BR-ROLE-04 |
| FR-AUTH-04 | Chủ nhà thu hồi quyền truy cập đã cấp cho 1 tài khoản trên 1 Nhà/Dãy trọ cụ thể — chỉ xoá được dòng quyền do chính mình cấp | Must | Không dùng cờ khoá tài khoản — xem BR-ROLE-05 |
| FR-AUTH-05 | Quên mật khẩu / khôi phục tài khoản | Should | Bắt buộc xác nhận OTP để tạo mật khẩu mới |
| FR-AUTH-06 | Đăng xuất (Logout) — xoá session/token, quay về màn hình Đăng nhập, có dialog xác nhận trước khi đăng xuất | Must | Xem [USER-FLOWS.md](USER-FLOWS.md) Flow Z |
| FR-AUTH-07 | Khi mời quản lý bằng số điện thoại đã có tài khoản, hiển thị tên ở dạng che một phần để xác nhận đúng người, không lộ hồ sơ đầy đủ | Must | Xem BR-ROLE-06 |
| ~~FR-AUTH-03 (V2)~~ | ~~Landlord tạo tài khoản Manager (SĐT, mật khẩu ban đầu, họ tên) qua Supabase Admin API~~ | Removed | Xoá Edge Function `create-manager-user` — xem [ARCHITECTURE](ARCHITECTURE.md) |
| ~~FR-AUTH-02 (V1)~~ | ~~Người dùng chọn vai trò khi đăng ký (Landlord/Tenant)~~ | Removed | Không còn vai trò gắn ở cấp tài khoản |

### 2.2 Quản lý Nhà/Dãy trọ & Phòng (House/Room Management)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-ROOM-01 | Người có quyền (`owner`) tạo/sửa/xoá thông tin Nhà/Dãy trọ (tên, địa chỉ, mô tả, ảnh, loại nhà — Dãy trọ/Căn hộ, thông tin chủ sở hữu hiển thị, tài khoản ngân hàng nhận tiền, đơn giá phí dịch vụ/m² mặc định) | Must | Người có `role=manager` chỉ xem, không sửa các field này — xem BR-ROLE-08 |
| FR-ROOM-02 | Người có quyền (`owner`/`manager`) tạo/sửa/xoá Phòng trong 1 Dãy trọ (số phòng, **diện tích m² — bắt buộc**, giá tham khảo, tiện ích, phí định kỳ mặc định, ảnh) | Must | `areaSqm` bắt buộc từ Version 3 — dùng tính phí dịch vụ hợp đồng |
| FR-ROOM-03 | Xem danh sách phòng với trạng thái: Trống / Đã thuê / Đang sửa chữa | Must | |
| FR-ROOM-04 | Lọc/tìm kiếm phòng theo dãy trọ, trạng thái | Should | |
| FR-ROOM-05 | Cấu hình giá thuê tham khảo & phí dịch vụ định kỳ mặc định theo phòng (dùng làm gợi ý khi tạo hợp đồng, không cố định) | Must | Giá/phí thật sự áp dụng nằm ở phiên bản hợp đồng |
| FR-ROOM-06 | Quản lý nhiều Dãy trọ, thuộc nhiều chủ sở hữu khác nhau, cùng lúc trong 1 tài khoản | Must | Phù hợp ca 1 tài khoản đứng tên nhiều nhà hoặc quản lý nhà hộ người khác |
| FR-ROOM-07 | Cấu hình 1 ngày cố định trong tháng để hệ thống nhắc ghi chỉ số định kỳ cho cả Nhà/Dãy trọ | Must | Dùng cho FR-READ-01, nhắc qua FR-NOTI-01 |

### 2.3 Nghiệp vụ ghi chỉ số điện/nước (Meter Reading) — Mới
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-READ-01 | Ghi chỉ số **định kỳ hàng tháng** cho **mọi phòng** của 1 Nhà/Dãy trọ (kể cả phòng trống) vào 1 ngày cố định | Must | Không gắn hợp đồng — xem BR-READ-02 |
| FR-READ-02 | Ghi chỉ số **lúc nhận phòng** (`MOVE_IN`) — bắt buộc trước khi lưu hợp đồng mới | Must | Chặn nút "Lưu hợp đồng" nếu thiếu — xem BR-CTR-10 |
| FR-READ-03 | Ghi chỉ số **lúc trả phòng** (`MOVE_OUT`) — bắt buộc trước khi tính thanh lý cọc | Must | Chặn "Kết thúc hợp đồng" nếu thiếu |
| FR-READ-04 | Hệ thống validate chỉ số mới ≥ chỉ số cũ ngay lúc ghi | Must | |
| FR-READ-05 | Xem lịch sử chỉ số theo phòng (toàn bộ 3 loại, theo trình tự thời gian) — **cùng 1 màn với FR-READ-01** (H-06 Record Monthly Reading, gộp 09/08 trong FigJam), tap 1 phòng để mở detail view, không phải màn riêng | Should | Xem [SCREEN-SPEC.md](SCREEN-SPEC.md) H-06 |
| FR-READ-06 | Chặn sửa trực tiếp chỉ số đã gắn vào 1 hoá đơn (`isLocked=true`, derived — xem BR-READ-04); sửa khi chưa khoá thực hiện **ngay tại detail view của FR-READ-05**, không có màn "sửa" riêng. Muốn điều chỉnh chỉ số đã khoá → thêm dòng vào `otherFees` của hoá đơn kế tiếp (BR-METER-13) | Must | |
| FR-READ-07 | Không yêu cầu ghi chỉ số cho phòng/hợp đồng cấu hình "không thu theo chỉ số" (`NOT_BILLED`) | Must | VD căn hộ cho thuê nguyên căn — khách tự trả điện/nước cho toà nhà. **Chỉ miễn cho `NOT_BILLED`** — phòng `FLAT` (khoán) vẫn ghi chỉ số đầy đủ như bình thường, chỉ không dùng chỉ số đó để tính tiền; có chủ đích để theo dõi mức tiêu thụ thực tế, xem `BR-READ-05` |

### 2.4 Quản lý Người thuê (Tenant Management)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-TEN-01 | Tạo hồ sơ Tenant (họ tên, SĐT, giới tính, ngày sinh, email tuỳ chọn, CCCD/CMND, ảnh CCCD 2 mặt, ghi chú) — lưu vào "Tenant Pool" dùng chung theo Nhà/Dãy trọ | Must | Bắt buộc chọn 1 Nhà/Dãy trọ (`houseId`) ngay lúc tạo — mỗi hồ sơ Tenant thuộc đúng 1 nhà, không dùng chung giữa nhiều nhà dù cùng 1 chủ sở hữu (mới, 09/09/2026 — xem `BR-DATA-05`) |
| FR-TEN-02 | Tạo hồ sơ Tenant **ngay trong lúc** tạo hợp đồng (shortcut), không bắt buộc tạo trước | Must | |
| FR-TEN-03 | Tìm kiếm/lọc Tenant Pool theo tên/SĐT, theo trạng thái gắn phòng | Should | |
| ~~FR-DISC-xx~~ | ~~Tìm kiếm & xem nhà/phòng cho thuê phía Tenant~~ | **Ngoài phạm vi Phase 1** | Yêu cầu Tenant có tài khoản/app — dời Phase 2 |

### 2.5 Quản lý Hợp đồng (Contract Management)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-CTR-01 | Tạo Hợp đồng gắn Tenant (từ Tenant Pool hoặc tạo nhanh) với **1 hoặc nhiều phòng cùng 1 Nhà/Dãy trọ**: ngày bắt đầu, kỳ hạn, tiền cọc (cho cả hợp đồng), tiền thuê/tháng (cho cả hợp đồng), phương thức/đơn giá điện & nước (theo chỉ số / khoán / không thu), chu kỳ thu tiền nhà, ngày cố định làm hạn thanh toán, phí dịch vụ (tự tính theo tổng m² các phòng × đơn giá), phí định kỳ, phạt trễ hạn (optional), môi giới (optional) | Must | **Thay đổi lớn nhất** so với Version 2 (1 hợp đồng = 1 phòng) — khởi tạo `tb_contract` + `tb_contract_room` (1 dòng/phòng) + `tb_contract_version` #1 |
| FR-CTR-02 | Bắt buộc đã có chỉ số **nhận phòng (`MOVE_IN`)** cho từng phòng thuộc hợp đồng mới trước khi lưu | Must | Xem FR-READ-02 |
| FR-CTR-03 | Xem danh sách hợp đồng, lọc theo nhà, sắp hết hạn | Must | |
| FR-CTR-04 | Xem chi tiết 1 hợp đồng, gồm danh sách phòng, điều khoản hiện hành | Must | |
| FR-CTR-05 | Lịch sử phiên bản điều khoản (Version History) — mỗi lần gia hạn/sửa điều khoản/đổi danh sách phòng tạo 1 bản ghi `contract_version` mới | Must | |
| FR-CTR-06 | Gia hạn hợp đồng (`changeReason=Renewal`) — không đo lại chỉ số nếu giữ nguyên Tenant/phòng | Must | |
| FR-CTR-07 | Sửa điều khoản hợp đồng đang hiệu lực, kể cả thêm/bớt phòng (`changeReason=Amendment`) | Should | Phòng bị loại ra cần chỉ số trả phòng riêng — xem BR-CTR-07 |
| FR-CTR-08 | Kết thúc hợp đồng / trả phòng — bắt buộc đã có chỉ số **trả phòng (`MOVE_OUT`)** cho từng phòng, tổng kết công nợ, đối soát tiền cọc (trừ hư hỏng nếu có), xác nhận số tiền hoàn/thu thêm | Must | Xem FR-READ-03 |
| FR-CTR-09 | Nhiều Tenant trên cùng 1 hợp đồng/phòng (ở ghép, nhiều người đại diện) | Won't (Phase 1) | Phase 1 chỉ 1 người đại diện (`tenantId`) mỗi hợp đồng, dù hợp đồng có nhiều phòng |
| FR-CTR-10 | Ký hợp đồng điện tử (e-signature) trong app | Won't (MVP) | Phase 2 |

### 2.6 Hoá đơn & Thu tiền (Bill Management — Core)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-BILL-01 | Hệ thống **tự động tính** hoá đơn theo từng phòng (điện/nước) + theo cả hợp đồng (tiền nhà nếu đúng kỳ, phí dịch vụ theo m², phí định kỳ khác), đọc lại chỉ số đã ghi sẵn (không nhập tay lúc tạo hoá đơn như Version 2) | Must | **Chức năng cốt lõi** của Phase 1 — xem [BUSINESS-RULES](BUSINESS-RULES.md) mục 1 |
| FR-BILL-02 | **Tạo hoá đơn hàng loạt** — chọn 1 Nhà/Dãy trọ + 1 kỳ → tạo cho mọi hợp đồng `Active` có đủ chỉ số; hợp đồng thiếu chỉ số bị bỏ qua, hệ thống chỉ rõ phòng nào thiếu | Must | Mới — xem BR-BILL-11 |
| FR-BILL-03 | Xem trước (preview) hoá đơn trước khi gửi, cho cả tạo đơn lẻ và hàng loạt | Must | |
| FR-BILL-04 | Tự động sinh **mã QR thanh toán chuẩn VietQR/NAPAS-247** kèm theo hoá đơn | Must | Từ tài khoản ngân hàng của Nhà/Dãy trọ — xem BR-BILL-10 |
| FR-BILL-05 | Tự động gửi hoá đơn cho Tenant qua SMS và/hoặc Zalo, kèm mã QR | Must | Một chiều — Tenant không có app |
| FR-BILL-06 | Xem danh sách hoá đơn **nhóm theo Nhà/Dãy trọ → theo Hợp đồng**, lọc/sắp xếp theo trạng thái (Draft/Sent/Collected/Overdue) và theo kỳ | Must | Thay đổi so với danh sách phẳng của Version 2 |
| FR-BILL-07 | Hiển thị kỳ tương lai dưới dạng chip "Scheduled" kèm bản xem trước dựng tạm, không tạo hoá đơn thật trước | Should | Xem BR-BILL-12 |
| FR-BILL-08 | Đánh dấu hoá đơn "Đã thu tiền" (Collected) thủ công, có thể huỷ đánh dấu | Must | Không có bước Tenant tự đánh dấu — kế thừa Version 2 |
| FR-BILL-09 | Tự động nhắc thanh toán trước/đúng/sau hạn qua SMS/Zalo cho Tenant + Push cho người có quyền trên nhà đó | Must | Lịch nhắc — xem BR-PAY-04 |
| FR-BILL-10 | Tính phí phạt trễ hạn tự động | Could | Theo `lateFeeTerms` |
| ~~FR-BILL cũ (V2)~~ | ~~Nhập chỉ số điện/nước trực tiếp lúc tạo hoá đơn~~ | Removed | Thay bằng nghiệp vụ ghi chỉ số riêng — xem mục 2.3 |

### 2.7 Báo cáo doanh thu (Reporting)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-RPT-01 | Xem nhanh tổng/đã thu/chưa thu/quá hạn ngay trong Bill Management qua filter theo trạng thái + kỳ | Should | Kế thừa Version 2 — báo cáo trực quan đầy đủ dời Phase 2 |

### 2.8 Yêu cầu sửa chữa / Bảo trì (Maintenance)
| ~~FR-MAINT-xx~~ | | **Ngoài phạm vi Phase 1** | Yêu cầu Tenant có app — dời Phase 2 |

### 2.9 Thông báo (Notifications)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-NOTI-01 | Push notification cho người có quyền trên Nhà/Dãy trọ liên quan (hoá đơn mới tạo, đến hạn ghi chỉ số định kỳ, hợp đồng sắp hết hạn) | Must | "Đến hạn ghi chỉ số" điều hướng đúng tới màn Ghi chỉ số (không phải màn Tạo hoá đơn) — xem BR-NOTI-05 |
| FR-NOTI-02 | Gửi SMS/Zalo cho Tenant khi có hoá đơn mới (kèm QR) và khi nhắc thanh toán | Must | Kênh duy nhất tiếp cận Tenant |
| FR-NOTI-03 | Trung tâm thông báo (notification inbox) trong app | Must | |
| FR-NOTI-04 | Thông báo khi được mời làm quản lý 1 Nhà/Dãy trọ | Should | Xem BR-NOTI-06 |

### 2.10 Quản lý quyền truy cập theo Nhà/Dãy trọ (Profile)
| ID | Requirement | Priority | Ghi chú |
|---|---|---|---|
| FR-MGR-01 | Xem/sửa Hồ sơ cá nhân (họ tên, giới tính, ngày sinh, email, CCCD/CMND, avatar) | Must | Dùng chung cho mọi tài khoản, không phân biệt owner/manager. **SĐT chỉ xem, không cho sửa** (đổi hướng 09/09/2026 — xem `BR-ROLE-09`) |
| FR-MGR-02 | Xem/sửa thông tin tài khoản ngân hàng nhận tiền theo **từng Nhà/Dãy trọ** (không phải theo tài khoản cá nhân) | Must | Chỉ `role=owner` của nhà đó sửa được — dùng làm mặc định khi tạo hoá đơn/sinh QR |
| FR-MGR-03 | Xem danh sách người đang có quyền truy cập (owner/manager) trên từng Nhà/Dãy trọ mình quản lý; mời thêm bằng SĐT; thu hồi quyền đã cấp | Must | Thay thế hoàn toàn màn "Quản lý tài khoản Manager" kiểu Version 2 — xem FR-AUTH-03/04 |
| FR-MGR-04 | Đổi mật khẩu | Must | Mới — tách riêng khỏi luồng quên mật khẩu |
| FR-MGR-05 | Chọn ngôn ngữ hiển thị ứng dụng — **1 trong 3: English / Tiếng Việt / 한국어**, chọn ngay tại màn Profile P-01 (dòng "Ngôn ngữ / Language", inline picker, không mở màn riêng) | Must | Mới, 09/09/2026 — sửa lại cùng ngày (đợt 2): ban đầu định thêm màn riêng P-08, đổi thành chọn ngay tại P-01 và mở rộng 2→3 ngôn ngữ; ngôn ngữ khác để Phase 2. Xem `NFR-02`, [SCREEN-SPEC.md](SCREEN-SPEC.md) P-01 |

---

## 3. Non-Functional Requirements
| ID | Yêu cầu | Ghi chú |
|---|---|---|
| NFR-01 | Hỗ trợ iOS và Android, cross-platform framework | Flutter |
| NFR-02 | Giao diện hỗ trợ **3 ngôn ngữ ngay từ Phase 1: English / Tiếng Việt / 한국어** — chọn ngay tại P-01 (`FR-MGR-05`); ngôn ngữ khác ngoài 3 ngôn ngữ này để Phase 2 | Đổi hướng 09/09/2026 (trước đó dời "đa ngôn ngữ" sang Phase 2), sửa lại cùng ngày (đợt 2): mở rộng từ song ngữ Anh–Việt lên 3 ngôn ngữ, bỏ màn P-08 riêng — chọn ngay tại P-01. Bản thiết kế Figma vẫn dựng bằng tiếng Anh làm chuẩn, nhưng code UI cần chuẩn bị i18n 3 bộ string (EN/VI/KO) ngay từ đầu — xem [DECISIONS.md](DECISIONS.md) 2026-09-09 |
| NFR-03 | Dữ liệu cá nhân (CCCD, SĐT) cần mã hoá khi lưu trữ & tuân thủ quy định bảo vệ dữ liệu cá nhân | |
| NFR-04 | Hoạt động ổn định với kết nối mạng yếu | |
| NFR-05 | Thời gian phản hồi tạo hoá đơn hàng loạt < 2s / hợp đồng | Cập nhật từ "1 phòng" (V2) sang "1 hợp đồng" vì hợp đồng có thể nhiều phòng |
| NFR-06 | Khả năng mở rộng multi-tenant + phân quyền theo Nhà/Dãy trọ (không phải theo tài khoản) | Phù hợp mô hình RLS mới — xem [BUSINESS-RULES](BUSINESS-RULES.md) mục 7 |
| NFR-07 | Sao lưu dữ liệu định kỳ, có khả năng khôi phục | |
| NFR-08 | Accessibility cơ bản (cỡ chữ, contrast) — xem [DESIGN](DESIGN.md) | |
| NFR-09 | Chuỗi chỉ số điện/nước (`previousReadingId`) phải toàn vẹn — không cho phép xoá 1 bản ghi đang được bản ghi khác trỏ tới | Mới |

---

## 4. Integration Requirements
| ID | Tích hợp | Trạng thái |
|---|---|---|
| INT-01 | Zalo ZNS (Zalo Notification Service) hoặc Zalo OA để gửi hoá đơn/thông báo kèm mã QR cho Tenant | đang tiến hành tạo và chờ phê duyệt tài khoản OA |
| INT-02 | SMS Brandname (qua eSMS, Speedsms, hoặc nhà mạng) | đang nghiên cứu chọn nhà cung cấp |
| INT-03 | OTP xác thực đăng ký/đăng nhập (mọi tài khoản) | dùng chung với INT-02, qua Supabase Auth Send SMS Hook |
| INT-04 | Push notification (Firebase Cloud Messaging / APNs) | Xác nhận lại ở [ARCHITECTURE](ARCHITECTURE.md) |
| INT-05 | Cổng thanh toán online (VNPay/Momo/ZaloPay) | Ngoài phạm vi Phase 1 — Phase 1 chỉ sinh mã QR chuyển khoản tĩnh (VietQR/NAPAS-247), không xử lý thanh toán trong app |
| INT-06 | Lưu trữ ảnh (hồ sơ, CCCD, ảnh phòng, ảnh công tơ) — Cloud storage (Supabase Storage) | |

---

## 5. Data Overview (sơ bộ — xem [DATABASE.md](DATABASE.md) cho schema đầy đủ)
Các thực thể chính (12 bảng, tiền tố `tb_` — **đảo ngược quy ước "không tiền tố" của Version 2**, khớp [DATABASE.md](DATABASE.md)): `tb_user`, `tb_user_house_access`, `tb_house`, `tb_room`, `tb_tenant`, `tb_contract`, `tb_contract_room`, `tb_contract_version`, `tb_electricity_reading`, `tb_water_reading`, `tb_invoice`.

---

## 6. Ngoài phạm vi (Out of Scope cho Phase 1)
Xem chi tiết tại [PRODUCT-OVERVIEW](PRODUCT-OVERVIEW.md) mục 5.2. Tóm tắt: toàn bộ app/tài khoản Tenant (đăng nhập, tìm phòng/marketplace, xem & tự thanh toán hoá đơn trong app, gửi yêu cầu sửa chữa), Service Request Management, Revenue Report riêng biệt (biểu đồ/xuất file), thanh toán online trong app (chỉ dừng ở sinh mã QR tĩnh), đăng ký công tơ/IoT tự động đọc số, nhiều Tenant đại diện trên 1 hợp đồng, chat trong app, e-signature. ~~Đa ngôn ngữ~~ — **không còn ngoài phạm vi** từ 09/09/2026 cho 3 ngôn ngữ English/Tiếng Việt/한국어 (ngôn ngữ khác vẫn để Phase 2), xem `NFR-02`/`FR-MGR-05`.

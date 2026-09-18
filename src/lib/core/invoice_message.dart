import 'package:intl/intl.dart';

import '../data/models/invoice.dart';
import 'supabase_client.dart';

/// Link ẢNH HOÁ ĐƠN của 1 hoá đơn — Edge Function `i`.
///
/// Tên hàm chỉ một chữ `i` là **cố ý**, không phải viết tắt cho gọn: xem giải
/// thích ngân sách ký tự ở [buildInvoiceSmsMessage] ngay bên dưới.
///
/// Dạng **đường dẫn sạch**, KHÔNG dùng `?code=...`: test thật 17/09/2026 cho
/// thấy nhà mạng chặn tin nhắn chứa `?` hoặc `&` (xem `docs/SMS-HOA-DON.md`
/// mục 6.4). Bỏ luôn `https://` cho ngắn — điện thoại vẫn nhận ra là link.
String invoiceImageLink(Invoice invoice) {
  final host = SupabaseConfig.url.replaceFirst(RegExp(r'^https?://'), '');
  return '$host/functions/v1/i/${invoice.publicCode}';
}

/// Nội dung SMS gửi Tenant cho 1 hoá đơn. Dùng chung cho B-05 (gửi đơn lẻ) và
/// B-03 (gửi hàng loạt, qua bản sinh đôi ở `_shared/invoice_message.ts`).
///
/// ⚠️ **Câu chữ bị khoá theo mẫu của brandname đi mượn, không tự viết được.**
/// eSMS chỉ cho gửi đúng những mẫu nội dung đã được nhà mạng duyệt cho từng
/// brandname; sai một dấu chấm là bị trả `CodeResult 146 — Sai template`
/// (kiểm chứng thật 18/09: đổi "Tran trong." thành "Tran trong!" là bị chặn,
/// và không bị trừ tiền). Dự án chưa có brandname riêng nên đang mượn
/// brandname demo `Baotrixemay` của eSMS.
///
/// ## Ngân sách ký tự — vì sao nội dung trông cụt lủn như vậy
///
/// Một đoạn SMS bảng mã GSM-7 chứa **160 ký tự**; vượt một ký tự là thành 2
/// đoạn, **trả tiền gấp đôi** (đo thật 18/09: 1.640đ cho 2 đoạn, ~820đ cho 1).
///
/// Riêng phần chữ CỐ ĐỊNH của mẫu mượn đã ăn **93 ký tự** ("Quy khach da den
/// thoi gian bao tri lan … xe … Vui long lien he … de duoc huong dan. Tran
/// trong.") — toàn chuyện bảo trì xe máy, vô nghĩa với người thuê, mà không
/// sửa được một chữ. Còn đúng **67 ký tự** cho mọi thứ có ích:
///
/// | Thành phần | Ký tự |
/// |---|---|
/// | Link ảnh hoá đơn | 60 |
/// | Kỳ (`MM/YY`) | 5 |
/// | Ô cuối (`BT`) | 2 |
/// | **Tổng cả tin** | **160 — vừa đúng 1 đoạn** |
///
/// Mọi thành phần đều dài CỐ ĐỊNH (tên miền Supabase 32, mã tra cứu luôn 12
/// ký tự) nên con số 160 là chắc chắn, không có hoá đơn nào vọt lên 2 đoạn.
///
/// **Số tiền và hạn thanh toán cố tình KHÔNG nằm trong tin nhắn** — dungtv
/// chốt 18/09/2026. Nhét chúng vào là tin dài 199 ký tự, thành 2 đoạn, đắt
/// gấp đôi. Người thuê bấm link là thấy đầy đủ hoá đơn kèm mã QR.
///
/// Khi mua được tên miền riêng (link còn ~17 ký tự) thì dư ra ~43 ký tự — lúc
/// đó nhét lại số tiền và hạn thanh toán vào mà vẫn giữ 1 đoạn.
String buildInvoiceSmsMessage(Invoice invoice) {
  final ky = DateFormat('MM/yy').format(invoice.periodStart); // 5
  final link = invoiceImageLink(invoice); // 60
  return 'Quy khach da den thoi gian bao tri lan $ky xe $link. '
      'Vui long lien he BT de duoc huong dan. Tran trong.';
}

import 'package:intl/intl.dart';

import '../data/models/invoice.dart';
import 'number_format.dart';
import 'supabase_client.dart';

/// Link ảnh mã QR chuyển khoản của 1 hoá đơn — Edge Function `invoice-qr`.
///
/// Dạng **đường dẫn sạch**, KHÔNG dùng `?code=...`: test thật 17/09/2026 cho
/// thấy nhà mạng chặn tin nhắn chứa `?` hoặc `&` (xem `docs/SMS-HOA-DON.md`
/// mục 6.4). Bỏ luôn `https://` cho ngắn — điện thoại vẫn nhận ra là link.
String invoiceQrLink(Invoice invoice) {
  final host = SupabaseConfig.url.replaceFirst(RegExp(r'^https?://'), '');
  return '$host/functions/v1/invoice-qr/${invoice.publicCode}';
}

/// Nội dung SMS gửi Tenant cho 1 hoá đơn. Dùng chung cho B-05 (gửi đơn lẻ) và
/// B-03 (gửi hàng loạt).
///
/// ⚠️ **Câu chữ bị khoá theo mẫu của brandname đi mượn, không tự viết được.**
/// eSMS chỉ cho gửi đúng những mẫu nội dung đã được nhà mạng duyệt cho từng
/// brandname; nội dung tự do bị trả về `CodeResult 146 — Sai template`. Dự án
/// chưa có brandname riêng nên đang mượn brandname demo `Baotrixemay` của
/// eSMS, và mẫu khớp nhất trong 21 mẫu của họ là mẫu nhắc bảo trì xe máy.
/// dungtv chốt 17/09/2026 chấp nhận dùng tạm mẫu này.
///
/// Hệ quả người thuê nhìn thấy: tin đến từ tên **Baotrixemay** với câu chữ về
/// bảo trì xe, dữ liệu hoá đơn nhét vào các ô tham số. Khi có brandname riêng
/// thì viết lại hàm này theo đúng mẫu ở `docs/SMS-HOA-DON.md` mục 2.2/6.
///
/// Giới hạn độ dài từng ô tham số của mẫu gốc: `{P1,10}` / `{P2,70}` /
/// `{P2,50}` — vượt quá là bị từ chối, nên các chuỗi dưới đây đều cắt cho vừa.
///
/// Toàn bộ nội dung viết **không dấu**: chỉ cần một ký tự ngoài bảng mã GSM-7
/// là cả tin bị đẩy sang UCS-2, giới hạn tụt từ 160 xuống 70 ký tự/đoạn và
/// tiền tin nhắn tăng gấp đôi gấp ba (xem `docs/SMS-HOA-DON.md` mục 6.1).
String buildInvoiceSmsMessage(Invoice invoice) {
  final ky = DateFormat('MM/yyyy').format(invoice.periodStart); // ≤ 10
  final link = invoiceQrLink(invoice); // ≤ 70
  final phong = invoice.roomNos.join(',');
  final tien = formatNumber(invoice.totalAmount);
  final han = DateFormat('dd/MM').format(invoice.dueDate);
  // Ô thứ ba tối đa 50 ký tự — cắt tên phòng trước, giữ tiền và hạn vì đó là
  // thông tin người thuê cần nhất.
  var tomTat = 'BizTown P$phong $tien' 'd han $han';
  if (tomTat.length > 50) tomTat = 'BizTown $tien' 'd han $han';

  return 'Quy khach da den thoi gian bao tri lan $ky xe $link. '
      'Vui long lien he $tomTat de duoc huong dan. Tran trong.';
}

import 'package:intl/intl.dart';

import '../data/models/house.dart';
import '../data/models/invoice.dart';
import '../data/models/vn_bank.dart';
import 'number_format.dart';

/// Nội dung SMS/Zalo gửi Tenant cho 1 hoá đơn — BR-NOTI-07: nội dung LUÔN
/// tiếng Việt, ĐỘC LẬP với ngôn ngữ UI (English/Tiếng Việt/한국어) chủ nhà/
/// quản lý đang chọn, không qua `AppStrings.t()`. Dùng chung cho B-05 (gửi
/// đơn lẻ) và B-03 (gửi hàng loạt).
String buildInvoiceSmsMessage(Invoice invoice, House? house) {
  final bank = VnBank.byBin(house?.bankBin);
  final rooms = invoice.roomNos.join(', ');
  final period = '${DateFormat('dd/MM').format(invoice.periodStart)}–'
      '${DateFormat('dd/MM/yyyy').format(invoice.periodEnd)}';
  final amount = '${formatNumber(invoice.totalAmount)} VND';
  final due = DateFormat('dd/MM/yyyy').format(invoice.dueDate);
  final payTo = (bank != null && house?.bankAccountNumber != null)
      ? ' Chuyển khoản ${bank.name} ${house!.bankAccountNumber}'
          '${house.bankAccountName != null ? ' (${house.bankAccountName})' : ''}.'
      : '';
  return 'BizTown Rent Manager: Hoá đơn phòng $rooms, kỳ $period là $amount.'
      '$payTo Hạn thanh toán $due.';
}

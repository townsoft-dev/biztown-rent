import '../data/models/contract.dart';
import '../data/models/invoice.dart';

/// 1 kỳ hoá đơn suy ra từ điều khoản hợp đồng (KHÔNG phải `tb_invoice` thật)
/// — dùng cho T-05 (dải chip) và T-10 (Invoice Schedule Preview). Xem
/// docs/DECISIONS.md Đợt 28 — chưa có `BR-BILL-xx`/`DATABASE.md` nào định
/// nghĩa chính xác cách chia kỳ, đây là suy luận hợp lý (ngày neo = ngày
/// trong tháng của `startDate` phiên bản hiện hành, hạn thanh toán rơi vào
/// tháng của `end`), chỉ dùng để XEM TRƯỚC — không lưu DB nên thay đổi cách
/// tính sau này không ảnh hưởng dữ liệu cũ.
class InvoicePeriod {
  final DateTime start;
  final DateTime end;
  final DateTime dueDate;

  const InvoicePeriod(
      {required this.start, required this.end, required this.dueDate});
}

/// Ngày `day` của tháng `year-month`, lùi về ngày cuối cùng có thật nếu tháng
/// đó không có ngày này (VD 31 vào tháng 2) — đúng hint đã ghi ở T-06/DATABASE.md.
DateTime dueDateForMonth(int year, int month, int day) {
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDayOfMonth ? lastDayOfMonth : day);
}

InvoicePeriod _periodAt(ContractVersion version, int cycleIndex) {
  final anchorDay = version.startDate.day;
  final start = DateTime(
      version.startDate.year,
      version.startDate.month + cycleIndex * version.rentCycleMonths,
      anchorDay);
  final end =
      DateTime(start.year, start.month + version.rentCycleMonths, anchorDay)
          .subtract(const Duration(days: 1));
  final dueDate =
      dueDateForMonth(end.year, end.month, version.paymentDueDayOfMonth);
  return InvoicePeriod(start: start, end: end, dueDate: dueDate);
}

/// 1 chip trong dải "Invoice schedule" ở T-05 (component Figma node `167:54`).
/// `collected`/`sent`/`overdue` = có dòng `tb_invoice` thật (màu đặc, tap →
/// B-04 sau này); `current` = kỳ đã tới nhưng chưa có hoá đơn (viền cam);
/// `scheduled` = kỳ tương lai, chỉ xem trước ở T-10 (viền đứt nét xám).
enum InvoiceChipState { collected, sent, overdue, current, scheduled }

class InvoiceScheduleChipData {
  final String label;
  final InvoiceChipState state;
  final DateTime periodStart;

  const InvoiceScheduleChipData(
      {required this.label, required this.state, required this.periodStart});
}

/// Dựng dải chip "Invoice schedule" cho T-05 — `totalPeriods` kỳ tính từ kỳ
/// SỚM NHẤT còn chưa có hoá đơn Collected (thường là kỳ chứa hôm nay, trừ khi
/// có hoá đơn thật của kỳ trước đó vẫn chưa thu — B-0x chưa xây UI tạo hoá
/// đơn nên trong thực tế `invoices` luôn rỗng, mọi kỳ tính từ hôm nay trở đi
/// sẽ là `current` (kỳ đầu) rồi `scheduled` (các kỳ sau)).
List<InvoiceScheduleChipData> buildInvoiceScheduleChips(
  ContractVersion version,
  List<Invoice> invoices, {
  int totalPeriods = 10,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final invoiceByStart = <DateTime, Invoice>{
    for (final invoice in invoices) invoice.periodStart: invoice,
  };

  var todayIndex = 0;
  while (_periodAt(version, todayIndex).end.isBefore(today)) {
    todayIndex++;
  }
  var startIndex = todayIndex;
  while (startIndex > 0 &&
      invoiceByStart.containsKey(_periodAt(version, startIndex - 1).start)) {
    startIndex--;
  }

  return List.generate(totalPeriods, (i) {
    final period = _periodAt(version, startIndex + i);
    final invoice = invoiceByStart[period.start];
    final state = invoice != null
        ? switch (invoice.status) {
            InvoiceStatus.collected => InvoiceChipState.collected,
            InvoiceStatus.sent => period.dueDate.isBefore(today)
                ? InvoiceChipState.overdue
                : InvoiceChipState.sent,
            InvoiceStatus.draft => InvoiceChipState.current,
          }
        : (period.start.isAfter(today)
            ? InvoiceChipState.scheduled
            : InvoiceChipState.current);
    return InvoiceScheduleChipData(
        label: 'T${period.start.month}',
        state: state,
        periodStart: period.start);
  });
}

/// Kỳ có `start` khớp đúng ngày `periodStart` — T-10 dựng lại từ tham số route.
InvoicePeriod periodStartingAt(ContractVersion version, DateTime periodStart) {
  final anchorDay = version.startDate.day;
  final monthsFromStart = (periodStart.year - version.startDate.year) * 12 +
      (periodStart.month - version.startDate.month);
  final index = (monthsFromStart / version.rentCycleMonths).round();
  final period = _periodAt(version, index);
  assert(period.start.year == periodStart.year &&
      period.start.month == periodStart.month &&
      period.start.day == anchorDay);
  return period;
}

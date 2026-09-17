import '../data/models/contract.dart';
import '../data/models/invoice.dart';

/// 1 kỳ hoá đơn suy ra từ điều khoản hợp đồng (KHÔNG phải `tb_invoice` thật)
/// — dùng cho T-05 (dải chip) và T-10 (Invoice Schedule Preview). LUÔN đúng
/// 1 THÁNG DƯƠNG LỊCH (`BR-BILL-07`: "điện/nước luôn tính theo tháng dương
/// lịch") — sửa lại 2026-09-14 sau khi đối chiếu với Edge Function thật
/// `generate-invoice` (`periodBounds()`, cũng tính trọn tháng dương lịch)
/// lúc test B-0x, phát hiện bản trước đó (Đợt 28) tự suy luận SAI thành neo
/// theo ngày ký hợp đồng (VD hợp đồng ký 14/09 thì tính kỳ 14/09→13/10) —
/// suy luận đó dựa trên giả định BR-BILL chưa quy định rõ, nhưng thực ra
/// `BR-BILL-07` đã quy định rõ là tháng dương lịch, chỉ là chưa đối chiếu kỹ.
/// Xem docs/DECISIONS.md.
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

/// Kỳ tháng dương lịch thứ [monthOffset] kể từ đúng tháng chứa `startDate`
/// của hợp đồng (0 = tháng ký hợp đồng, LUÔN từ ngày 1 tới ngày cuối tháng —
/// không neo theo ngày ký, khớp `periodBounds()` trong Edge Function).
InvoicePeriod _periodAt(ContractVersion version, int monthOffset) {
  final start = DateTime(
      version.startDate.year, version.startDate.month + monthOffset, 1);
  final daysInMonth = DateTime(start.year, start.month + 1, 0).day;
  final end = DateTime(start.year, start.month, daysInMonth);
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

  /// ID hoá đơn THẬT của kỳ này, `null` khi kỳ đó chưa có hoá đơn nào.
  ///
  /// Cần tách riêng khỏi [state] vì hoá đơn **Nháp** cũng vẽ bằng trạng thái
  /// `current` (đúng Figma: viền cam = kỳ đang tới) — nhìn vào `state` thì
  /// không phân biệt được "chưa có hoá đơn" với "có hoá đơn nháp". Trước
  /// 17/09/2026 chỗ bấm chip chỉ có `periodStart` nên luôn mở màn XEM TRƯỚC,
  /// khiến hoá đơn nháp không bao giờ mở được để gửi (dungtv báo).
  final String? invoiceId;

  const InvoiceScheduleChipData({
    required this.label,
    required this.state,
    required this.periodStart,
    this.invoiceId,
  });
}

/// Dựng dải chip "Invoice schedule" cho T-05 — `totalPeriods` kỳ tính từ kỳ
/// SỚM NHẤT còn chưa có hoá đơn Collected (thường là kỳ chứa hôm nay, trừ khi
/// có hoá đơn thật của kỳ trước đó vẫn chưa thu).
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
        periodStart: period.start,
        invoiceId: invoice?.id);
  });
}

/// Kỳ có `start` khớp đúng tháng/năm của `periodStart` — T-10 dựng lại từ
/// tham số route, B-01 tìm hoá đơn đúng kỳ đang xem.
InvoicePeriod periodStartingAt(ContractVersion version, DateTime periodStart) {
  final monthOffset = (periodStart.year - version.startDate.year) * 12 +
      (periodStart.month - version.startDate.month);
  return _periodAt(version, monthOffset);
}

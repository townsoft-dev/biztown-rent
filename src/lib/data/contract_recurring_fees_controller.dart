import 'package:flutter/material.dart';

import '../core/number_format.dart';
import 'models/recurring_fee.dart';

/// "Billing method" trên mỗi dòng phí định kỳ ở T-06 (Figma: Flat/None) —
/// CHỈ là toggle bật/tắt dòng ngay tại form, không phải field cần lưu riêng
/// (xem docs/DECISIONS.md Đợt 27): T-05 (Contract Detail, màn chỉ đọc dữ liệu
/// đã lưu) không hiển thị dòng nào có method `none` — xác nhận model lưu vẫn
/// giữ nguyên `RecurringFee {name, amount}`, dòng `none` bị loại khi lưu.
enum ContractRecurringFeeBilling { flat, none }

class ContractRecurringFeeRow {
  final TextEditingController nameController;
  final TextEditingController amountController;
  ContractRecurringFeeBilling billing;

  ContractRecurringFeeRow(
      {String name = '',
      String amount = '',
      this.billing = ContractRecurringFeeBilling.flat})
      : nameController = TextEditingController(text: name),
        amountController = TextEditingController(text: amount);

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

/// State cho danh sách phí định kỳ ở T-06 (Create Contract) — khác
/// `RecurringFeesController` (House/Room) ở chỗ có thêm toggle Billing
/// method/dòng, xem [ContractRecurringFeeBilling].
class ContractRecurringFeesController extends ChangeNotifier {
  final List<ContractRecurringFeeRow> rows;

  ContractRecurringFeesController({List<RecurringFee>? initialFees})
      : rows = (initialFees ?? const [])
            .map((f) => ContractRecurringFeeRow(
                name: f.name, amount: formatNumber(f.amount)))
            .toList() {
    if (rows.isEmpty) rows.add(ContractRecurringFeeRow());
  }

  void addRow() {
    rows.add(ContractRecurringFeeRow());
    notifyListeners();
  }

  void removeRow(int index) {
    rows[index].dispose();
    rows.removeAt(index);
    notifyListeners();
  }

  void setBilling(int index, ContractRecurringFeeBilling billing) {
    rows[index].billing = billing;
    notifyListeners();
  }

  /// Bỏ qua dòng chưa nhập tên, số tiền không hợp lệ, hoặc billing = `none`.
  List<RecurringFee> get fees {
    final result = <RecurringFee>[];
    for (final row in rows) {
      if (row.billing == ContractRecurringFeeBilling.none) continue;
      final name = row.nameController.text.trim();
      final amount = parseFormattedNumber(row.amountController.text);
      if (name.isNotEmpty && amount != null) {
        result.add(RecurringFee(name: name, amount: amount));
      }
    }
    return result;
  }

  @override
  void dispose() {
    for (final row in rows) {
      row.dispose();
    }
    super.dispose();
  }
}

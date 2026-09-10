import 'package:flutter/material.dart';

import '../core/number_format.dart';
import 'models/recurring_fee.dart';

class RecurringFeeRow {
  final TextEditingController nameController;
  final TextEditingController amountController;

  RecurringFeeRow({String name = '', String amount = ''})
      : nameController = TextEditingController(text: name),
        amountController = TextEditingController(text: amount);

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

/// State cho danh sách phí định kỳ (H-02 "Default recurring fees" / H-05
/// "Default recurring fees") — cùng 1 controller dùng chung cho cả 2 màn vì
/// cùng thao tác trên `RecurringFee` (`tb_house.recurring_fees`/
/// `tb_room.recurring_fees`, jsonb `[{name, amount}]`).
class RecurringFeesController extends ChangeNotifier {
  final List<RecurringFeeRow> rows;

  RecurringFeesController({List<RecurringFee>? initialFees})
      : rows = (initialFees ?? const [])
            .map((f) =>
                RecurringFeeRow(name: f.name, amount: formatNumber(f.amount)))
            .toList() {
    if (rows.isEmpty) rows.add(RecurringFeeRow());
  }

  void addRow() {
    rows.add(RecurringFeeRow());
    notifyListeners();
  }

  void removeRow(int index) {
    rows[index].dispose();
    rows.removeAt(index);
    notifyListeners();
  }

  /// Bỏ qua dòng chưa nhập tên hoặc số tiền không hợp lệ.
  List<RecurringFee> get fees {
    final result = <RecurringFee>[];
    for (final row in rows) {
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

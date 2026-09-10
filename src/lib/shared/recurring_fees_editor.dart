import 'package:flutter/material.dart';

import '../core/number_format.dart';
import '../data/recurring_fees_controller.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// Danh sách dòng phí định kỳ có thể thêm/xoá (H-02 & H-05 "Default recurring
/// fees") — cùng 1 widget dùng chung cho cả House và Room form thay vì lặp lại
/// UI ở từng màn (2 field Fee name/Amount + nút "+ Add fee").
class RecurringFeesEditor extends StatelessWidget {
  final RecurringFeesController controller;

  const RecurringFeesEditor({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < controller.rows.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                      child: AppTextField(
                          label: 'Fee name',
                          controller: controller.rows[i].nameController)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(
                      label: 'Amount',
                      controller: controller.rows[i].amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [ThousandsInputFormatter()],
                    ),
                  ),
                  if (controller.rows.length > 1) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => controller.removeRow(i),
                      icon: const Icon(Icons.close_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
            ],
            AppButton(
                label: '+ Add fee',
                style: AppButtonStyle.ghost,
                size: AppButtonSize.sm,
                onPressed: controller.addRow),
          ],
        );
      },
    );
  }
}

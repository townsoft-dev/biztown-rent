import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_strings.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../data/contract_recurring_fees_controller.dart';
import 'app_button.dart';
import 'app_text_field.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Danh sách dòng phí định kỳ ở T-06 (Create Contract) — 3 field/dòng (Fee
/// name, Billing method Flat/None, Amount), khác `RecurringFeesEditor`
/// (House/Room, chỉ 2 field) vì Figma T-06 có thêm cột Billing method.
class ContractRecurringFeesEditor extends ConsumerWidget {
  final ContractRecurringFeesController controller;

  const ContractRecurringFeesEditor({super.key, required this.controller});

  Future<void> _pickBilling(BuildContext context, int index) async {
    final picked = await showModalBottomSheet<ContractRecurringFeeBilling>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final billing in ContractRecurringFeeBilling.values)
              ListTile(
                title: Text(billing == ContractRecurringFeeBilling.flat
                    ? AppStrings.t('status.flat')
                    : AppStrings.t('contractForm.billingNone')),
                onTap: () => Navigator.of(context).pop(billing),
              ),
          ],
        ),
      ),
    );
    if (picked != null) controller.setBilling(index, picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
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
                        label: AppStrings.t('common.feeName'),
                        controller: controller.rows[i].nameController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.t('contractForm.billingMethod'),
                      initialValue: controller.rows[i].billing ==
                              ContractRecurringFeeBilling.flat
                          ? AppStrings.t('status.flat')
                          : AppStrings.t('contractForm.billingNone'),
                      key: ValueKey('billing-$i-${controller.rows[i].billing}'),
                      trailing: AppTextFieldTrailingIcon.select,
                      onTap: () => _pickBilling(context, i),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: AppTextField(
                      label: AppStrings.t('common.amount'),
                      controller: controller.rows[i].amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [ThousandsInputFormatter()],
                    ),
                  ),
                  if (controller.rows.length > 1) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => controller.removeRow(i),
                      icon: const Icon(Symbols.close_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
            ],
            AppButton(
                label: AppStrings.t('common.addFee'),
                style: AppButtonStyle.ghost,
                size: AppButtonSize.sm,
                onPressed: controller.addRow),
          ],
        );
      },
    );
  }
}

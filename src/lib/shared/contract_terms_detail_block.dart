import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_strings.dart';
import '../core/enum_labels.dart';
import '../core/number_format.dart';
import '../data/models/contract.dart';
import '../data/models/reading.dart';
import 'detail_row.dart';

/// Khối `DetailBlock` hiển thị đầy đủ điều khoản 1 `ContractVersion` — dùng
/// chung cho T-05 (điều khoản hiện hành) và T-08 (xem chi tiết 1 phiên bản
/// cũ trong lịch sử, "View full terms"), tránh lặp lại ~90 dòng DetailRow.
class ContractTermsDetailBlock extends StatelessWidget {
  final ContractVersion version;

  const ContractTermsDetailBlock({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    final hasBroker =
        version.realEstate != null && !version.realEstate!.isEmpty;
    final hasSpecialNote =
        version.specialNote != null && version.specialNote!.isNotEmpty;

    return DetailBlock(children: [
      DetailRow(
          label: AppStrings.t('contractDetail.startDate'),
          value: _fmt(version.startDate)),
      DetailRow(
          label: AppStrings.t('contractDetail.endDate'),
          value: _fmt(version.endDate)),
      DetailRow(
          label: AppStrings.t('contractDetail.deposit'),
          value: formatNumber(version.depositAmount)),
      DetailRow(
          label: AppStrings.t('contractDetail.monthlyRent'),
          value: formatNumber(version.monthlyRent)),
      DetailRow(
        label:
            '${AppStrings.t('contractDetail.electricity')} · ${utilityBillingMethodLabel(version.electricityBillingMethod)}',
        value: version.electricityUnitPrice == null
            ? '—'
            : AppStrings.t('contractDetail.perUnit', {
                'amount': formatNumber(version.electricityUnitPrice!),
                'unit': UtilityType.electricity.unit,
              }),
      ),
      DetailRow(
        label:
            '${AppStrings.t('contractDetail.water')} · ${utilityBillingMethodLabel(version.waterBillingMethod)}',
        value: version.waterUnitPrice == null
            ? '—'
            : AppStrings.t('contractDetail.perUnit', {
                'amount': formatNumber(version.waterUnitPrice!),
                'unit': UtilityType.water.unit,
              }),
      ),
      DetailRow(
        label:
            '${AppStrings.t('contractDetail.service')} · ${serviceBillingMethodLabel(version.serviceBillingMethod)}',
        value: version.serviceFeeAmount == null
            ? '—'
            : AppStrings.t('contractDetail.perMonth',
                {'amount': formatNumber(version.serviceFeeAmount!)}),
      ),
      DetailRow(
          label: AppStrings.t('contractDetail.paymentDue'),
          value: AppStrings.t('contractDetail.paymentDueValue',
              {'day': '${version.paymentDueDayOfMonth}'})),
      DetailRow(
        label: AppStrings.t('contractDetail.recurringFees'),
        value: version.recurringFees.isEmpty
            ? '—'
            : version.recurringFees
                .map((f) => '${f.name} ${formatNumber(f.amount)}')
                .join('\n'),
      ),
      DetailRow(
          label: AppStrings.t('contractDetail.lateFee'),
          value: version.lateFeeTerms ?? '—',
          showDivider: hasBroker || hasSpecialNote),
      if (hasBroker)
        DetailRow(
          label: AppStrings.t('contractDetail.broker'),
          value: AppStrings.t('contractDetail.brokerValue', {
            'name': version.realEstate!.name ?? '—',
            'fee': version.realEstate!.fee == null
                ? '—'
                : formatNumber(version.realEstate!.fee!),
          }),
          showDivider: hasSpecialNote,
        ),
      if (hasSpecialNote)
        DetailRow(
          label: AppStrings.t('contractDetail.specialNote'),
          value: version.specialNote!,
          showDivider: false,
        ),
    ]);
  }

  String _fmt(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
}

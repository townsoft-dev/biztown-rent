import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/app_strings.dart';
import '../core/enum_labels.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/contract.dart';
import '../shared/contract_terms_detail_block.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

/// T-08 — Version History (node 220:3912, Figma) — timeline mọi
/// `tb_contract_version` của 1 hợp đồng, mới nhất trước. Tap "View full
/// terms" mở bottom sheet dùng lại [ContractTermsDetailBlock] (giống T-05).
class ContractHistoryScreen extends ConsumerWidget {
  final String contractId;

  const ContractHistoryScreen({super.key, required this.contractId});

  void _showFullTerms(BuildContext context, ContractVersion version) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                  AppStrings.t('contractHistory.versionCreated', {
                    'version': '${version.versionNo}',
                    'date': DateFormat('dd/MM/yyyy').format(version.createdAt),
                  }),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              ContractTermsDetailBlock(version: version),
            ],
          ),
        ),
      ),
    );
  }

  StatusBadgeStyle _badgeStyle(ChangeReason reason) => switch (reason) {
        ChangeReason.newContract => StatusBadgeStyle.empty,
        ChangeReason.renewal => StatusBadgeStyle.active,
        ChangeReason.amendment => StatusBadgeStyle.sent,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final versionsAsync = ref.watch(contractVersionsProvider(contractId));
    final rooms = ref.watch(contractRoomsProvider(contractId)).valueOrNull;
    final roomLabel = rooms == null || rooms.isEmpty
        ? '…'
        : rooms.map((r) => r.roomNo).join(', ');

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(
            title: AppStrings.t('contractHistory.title'),
            subtitle: AppStrings.t('contractHistory.subtitle', {
              'room': roomLabel,
              'count': '${versionsAsync.valueOrNull?.length ?? 0}',
            }),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: versionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                  child: Text(AppStrings.t(
                      'contractHistory.loadError', {'error': '$e'}))),
              data: (versions) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  for (final version in versions) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.bgDefault,
                        border: Border.all(color: AppColors.borderSubtle),
                        borderRadius: BorderRadius.circular(AppRadii.card),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatusPill(
                                text: changeReasonLabel(version.changeReason),
                                style: _badgeStyle(version.changeReason),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    AppStrings.t(
                                        'contractHistory.versionCreated', {
                                      'version': '${version.versionNo}',
                                      'date': DateFormat('dd/MM/yyyy')
                                          .format(version.createdAt),
                                    }),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                              AppStrings.t('contractHistory.effective', {
                                'start': DateFormat('dd/MM/yyyy')
                                    .format(version.startDate),
                                'end': DateFormat('dd/MM/yyyy')
                                    .format(version.endDate),
                              }),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          _MiniRow(
                              label: AppStrings.t('contractDetail.monthlyRent'),
                              value: formatNumber(version.monthlyRent)),
                          _MiniRow(
                              label: AppStrings.t('contractDetail.deposit'),
                              value: formatNumber(version.depositAmount)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _showFullTerms(context, version),
                            child: Text(
                                AppStrings.t('contractHistory.viewFullTerms'),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.info)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final String label;
  final String value;

  const _MiniRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

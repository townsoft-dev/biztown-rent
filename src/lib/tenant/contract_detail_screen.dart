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
import '../data/models/reading.dart';
import '../data/models/room.dart';
import '../shared/app_button.dart';
import '../shared/avatar.dart';
import '../shared/coming_soon_screen.dart';
import '../shared/detail_row.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

/// T-05 — Contract Detail (node 220:3552, Figma) — trung tâm điều hướng của
/// mọi thao tác hợp đồng (Renew/Amend → T-07, History → T-08, End contract →
/// T-09, Invoice schedule → T-10). 4 màn kia chưa code (chỉ mới làm T-05/T-06
/// đợt này) — tạm điều hướng sang `ComingSoonScreen`, xoá dần khi từng màn có
/// UI thật.
class ContractDetailScreen extends ConsumerWidget {
  final String contractId;

  const ContractDetailScreen({super.key, required this.contractId});

  bool _isEndingSoon(Contract contract, ContractVersion version) =>
      contract.status == ContractStatus.active &&
      !version.endDate.isBefore(DateTime.now()) &&
      version.endDate.difference(DateTime.now()).inDays <= 30;

  void _openStub(BuildContext context, String title) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ComingSoonScreen(title: title, icon: Icons.description_rounded)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final contractAsync = ref.watch(contractProvider(contractId));

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          Builder(builder: (context) {
            final contract = contractAsync.valueOrNull;
            final rooms =
                ref.watch(contractRoomsProvider(contractId)).valueOrNull;
            final houses = ref.watch(housesProvider).valueOrNull ?? const [];
            final house = (rooms == null || rooms.isEmpty)
                ? null
                : houses.where((h) => h.id == rooms.first.houseId).firstOrNull;
            return TopBar(
              title: rooms == null || rooms.isEmpty
                  ? AppStrings.t('common.loading')
                  : rooms.map((r) => r.roomNo).join(', '),
              subtitle: house == null
                  ? ''
                  : '${house.name} · ${contract == null ? '' : contractStatusLabel(contract.status)}',
              onBack: () => context.pop(),
            );
          }),
          Expanded(
            child: contractAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                  child: Text(AppStrings.t(
                      'contractDetail.loadError', {'error': '$e'}))),
              data: (contract) {
                final versionAsync = contract.currentVersionId == null
                    ? null
                    : ref.watch(
                        contractVersionProvider(contract.currentVersionId!));
                final version = versionAsync?.valueOrNull;
                final tenantAsync =
                    ref.watch(tenantProvider(contract.tenantId));
                final tenant = tenantAsync.valueOrNull;
                final rooms =
                    ref.watch(contractRoomsProvider(contractId)).valueOrNull ??
                        const [];

                if (version == null || tenant == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final endingSoon = _isEndingSoon(contract, version);
                final isEnded = contract.status == ContractStatus.ended;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    InkWell(
                      onTap: () => context.push('/tenant/${tenant.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bgDefault,
                          border: Border.all(color: AppColors.borderSubtle),
                          borderRadius: BorderRadius.circular(AppRadii.card),
                        ),
                        child: Row(
                          children: [
                            Avatar(initials: tenant.initials),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tenant.fullName,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  Text(tenant.phone,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            StatusPill(
                              text: contractStatusLabel(contract.status),
                              style: isEnded
                                  ? StatusBadgeStyle.ended
                                  : (endingSoon
                                      ? StatusBadgeStyle.expiringSoon
                                      : StatusBadgeStyle.active),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SectionLabel(AppStrings.t('contractDetail.currentTerms', {
                      'version': '${version.versionNo}',
                      'reason': changeReasonLabel(version.changeReason),
                      'date':
                          DateFormat('dd/MM/yyyy').format(version.createdAt),
                    })),
                    DetailBlock(children: [
                      DetailRow(
                          label: AppStrings.t('contractDetail.startDate'),
                          value: DateFormat('dd/MM/yyyy')
                              .format(version.startDate)),
                      DetailRow(
                          label: AppStrings.t('contractDetail.endDate'),
                          value:
                              DateFormat('dd/MM/yyyy').format(version.endDate)),
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
                                'amount':
                                    formatNumber(version.electricityUnitPrice!),
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
                            : AppStrings.t('contractDetail.perMonth', {
                                'amount':
                                    formatNumber(version.serviceFeeAmount!)
                              }),
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
                                .map((f) =>
                                    '${f.name} ${formatNumber(f.amount)}')
                                .join('\n'),
                      ),
                      DetailRow(
                          label: AppStrings.t('contractDetail.lateFee'),
                          value: version.lateFeeTerms ?? '—',
                          showDivider: version.realEstate != null &&
                              !version.realEstate!.isEmpty),
                      if (version.realEstate != null &&
                          !version.realEstate!.isEmpty)
                        DetailRow(
                          label: AppStrings.t('contractDetail.broker'),
                          value: AppStrings.t('contractDetail.brokerValue', {
                            'name': version.realEstate!.name ?? '—',
                            'fee': version.realEstate!.fee == null
                                ? '—'
                                : formatNumber(version.realEstate!.fee!),
                          }),
                          showDivider: false,
                        ),
                    ]),
                    SectionLabel(
                        AppStrings.t('contractDetail.sectionMeterReadings')),
                    for (final room in rooms) ...[
                      _RoomReadingsBlock(
                          room: room, contractId: contractId, isEnded: isEnded),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 6),
                    if (!isEnded) ...[
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: AppStrings.t('contractDetail.renew'),
                              onPressed: () => _openStub(
                                  context,
                                  AppStrings.t(
                                      'comingSoon.contractRenewAmend')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              label: AppStrings.t('contractDetail.amend'),
                              style: AppButtonStyle.ghost,
                              onPressed: () => _openStub(
                                  context,
                                  AppStrings.t(
                                      'comingSoon.contractRenewAmend')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: AppStrings.t('contractDetail.history'),
                            style: AppButtonStyle.ghost,
                            onPressed: () => _openStub(context,
                                AppStrings.t('comingSoon.contractHistory')),
                          ),
                        ),
                        if (!isEnded) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              label: AppStrings.t('contractDetail.endContract'),
                              style: AppButtonStyle.danger,
                              onPressed: () => _openStub(context,
                                  AppStrings.t('comingSoon.contractEnd')),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SectionLabel(
                        AppStrings.t('contractDetail.sectionInvoiceSchedule')),
                    AppButton(
                      label: AppStrings.t('contractDetail.viewInvoiceSchedule'),
                      style: AppButtonStyle.ghost,
                      onPressed: () => _openStub(
                          context, AppStrings.t('comingSoon.invoiceSchedule')),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomReadingsBlock extends ConsumerWidget {
  final Room room;
  final String contractId;
  final bool isEnded;

  const _RoomReadingsBlock(
      {required this.room, required this.contractId, required this.isEnded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elecHistory = ref.watch(readingHistoryProvider(
        (roomId: room.id, utilityType: UtilityType.electricity)));
    final waterHistory = ref.watch(readingHistoryProvider(
        (roomId: room.id, utilityType: UtilityType.water)));

    Reading? findByType(List<Reading>? list, ReadingType type) =>
        list?.where((r) => r.readingType == type).firstOrNull;

    final elecMoveIn = findByType(elecHistory.valueOrNull, ReadingType.moveIn);
    final waterMoveIn =
        findByType(waterHistory.valueOrNull, ReadingType.moveIn);
    final elecPeriodic =
        findByType(elecHistory.valueOrNull, ReadingType.periodic);
    final waterPeriodic =
        findByType(waterHistory.valueOrNull, ReadingType.periodic);
    final elecMoveOut =
        findByType(elecHistory.valueOrNull, ReadingType.moveOut);
    final waterMoveOut =
        findByType(waterHistory.valueOrNull, ReadingType.moveOut);

    String pairLine(Reading? elec, Reading? water) {
      if (elec == null && water == null) {
        return AppStrings.t('contractDetail.noReadingYet');
      }
      final date = elec?.readingDate ?? water?.readingDate;
      final elecText =
          elec == null ? '—' : formatReadingValue(elec.currentReading);
      final waterText =
          water == null ? '—' : formatReadingValue(water.currentReading);
      return '${date == null ? '' : DateFormat('dd/MM/yyyy').format(date)} · elec $elecText · water $waterText';
    }

    return DetailBlock(children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(room.roomNo,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
      ),
      DetailRow(
          label: AppStrings.t('contractDetail.moveIn'),
          value: pairLine(elecMoveIn, waterMoveIn)),
      DetailRow(
          label: AppStrings.t('contractDetail.latestPeriodic'),
          value: pairLine(elecPeriodic, waterPeriodic)),
      DetailRow(
          label: AppStrings.t('contractDetail.moveOut'),
          value: isEnded
              ? pairLine(elecMoveOut, waterMoveOut)
              : AppStrings.t('contractDetail.stillActive'),
          showDivider: false),
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/app_strings.dart';
import '../core/enum_labels.dart';
import '../core/invoice_period.dart';
import '../core/locale_provider.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/contract.dart';
import '../data/models/reading.dart';
import '../data/models/room.dart';
import '../shared/app_button.dart';
import '../shared/contract_terms_detail_block.dart';
import '../shared/detail_row.dart';
import '../shared/invoice_schedule_strip.dart';
import '../shared/mini_profile_card.dart';
import '../shared/section_label.dart';
import '../shared/top_bar.dart';

/// T-05 — Contract Detail (node 220:3552, Figma) — trung tâm điều hướng của
/// mọi thao tác hợp đồng (Renew/Amend → T-07, History → T-08, End contract →
/// T-09, dải chip kỳ hoá đơn sắp tới → T-10).
class ContractDetailScreen extends ConsumerWidget {
  final String contractId;

  const ContractDetailScreen({super.key, required this.contractId});

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

                final isEnded = contract.status == ContractStatus.ended;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    MiniProfileCard(
                      initials: tenant.initials,
                      name: tenant.fullName,
                      subtitle: AppStrings.t('contractDetail.tenantSubtitle', {
                        'phone': tenant.phone,
                        'idPhotos': (tenant.idPhotoFront != null &&
                                tenant.idPhotoBack != null)
                            ? AppStrings.t('contractDetail.idPhotosSaved')
                            : AppStrings.t('contractDetail.idPhotosMissing'),
                      }),
                      onTap: () => context.push('/tenant/${tenant.id}'),
                    ),
                    SectionLabel(AppStrings.t('contractDetail.currentTerms', {
                      'version': '${version.versionNo}',
                      'reason': changeReasonLabel(version.changeReason),
                      'date':
                          DateFormat('dd/MM/yyyy').format(version.createdAt),
                    })),
                    ContractTermsDetailBlock(version: version),
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
                              onPressed: () => context
                                  .push('/tenant/contracts/$contractId/renew'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              label: AppStrings.t('contractDetail.amend'),
                              style: AppButtonStyle.ghost,
                              onPressed: () => context
                                  .push('/tenant/contracts/$contractId/amend'),
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
                            onPressed: () => context
                                .push('/tenant/contracts/$contractId/history'),
                          ),
                        ),
                        if (!isEnded) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              label: AppStrings.t('contractDetail.endContract'),
                              style: AppButtonStyle.danger,
                              onPressed: () => context
                                  .push('/tenant/contracts/$contractId/end'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!isEnded) ...[
                      SectionLabel(AppStrings.t(
                          'contractDetail.sectionInvoiceSchedule')),
                      Builder(builder: (context) {
                        final invoices = ref
                                .watch(contractInvoicesProvider(contractId))
                                .valueOrNull ??
                            const [];
                        return InvoiceScheduleStrip(
                          chips: buildInvoiceScheduleChips(version, invoices),
                          // Cùng quy tắc với B-01: có hoá đơn thật thì mở
                          // hoá đơn, chưa có mới mở màn xem trước.
                          onTapPeriod: (chip) => context.push(
                            chip.invoiceId != null
                                ? '/bills/invoices/${chip.invoiceId}'
                                : '/tenant/contracts/$contractId/invoice-schedule'
                                    '?period=${DateFormat('yyyy-MM-dd').format(chip.periodStart)}',
                          ),
                        );
                      }),
                    ],
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

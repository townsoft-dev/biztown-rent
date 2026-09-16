import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/app_strings.dart';
import '../core/enum_labels.dart';
import '../core/invoice_period.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/contract.dart';
import '../data/models/reading.dart';
import '../data/models/vn_bank.dart';
import '../shared/app_banner.dart';
import '../shared/detail_row.dart';
import '../shared/section_label.dart';
import '../shared/top_bar.dart';

/// T-10 — Invoice Schedule Preview (node 220:4076, Figma) — xem trước ĐÚNG 1
/// kỳ (dungtv tự xác nhận qua header "Period MM/YYYY" trên Figma, xem
/// docs/DECISIONS.md Đợt 27), suy ra hoàn toàn từ `contract_version` hiện
/// hành — KHÔNG đọc/ghi `tb_invoice` thật (Bills B-0x chưa xây UI tạo hoá
/// đơn). Cách chia kỳ/hạn thanh toán xem `core/invoice_period.dart`.
class InvoiceScheduleScreen extends ConsumerWidget {
  final String contractId;
  final DateTime periodStart;

  const InvoiceScheduleScreen(
      {super.key, required this.contractId, required this.periodStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final contractAsync = ref.watch(contractProvider(contractId));

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: contractAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
            child: Text(
                AppStrings.t('invoiceSchedule.loadError', {'error': '$e'}))),
        data: (contract) {
          final versionAsync = contract.currentVersionId == null
              ? null
              : ref.watch(contractVersionProvider(contract.currentVersionId!));
          final version = versionAsync?.valueOrNull;
          final tenant =
              ref.watch(tenantProvider(contract.tenantId)).valueOrNull;
          final rooms =
              ref.watch(contractRoomsProvider(contractId)).valueOrNull;
          final houses = ref.watch(housesProvider).valueOrNull ?? const [];
          final house = (rooms == null || rooms.isEmpty)
              ? null
              : houses.where((h) => h.id == rooms.first.houseId).firstOrNull;

          if (version == null ||
              tenant == null ||
              rooms == null ||
              house == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final period = periodStartingAt(version, periodStart);

          // Chỉ số điện/nước thật của kỳ đang xem. Trước 16/09/2026 màn này
          // KHÔNG hề truy vấn chỉ số — 2 ô Điện/Nước luôn hiện "— chưa có chỉ
          // số" kể cả khi đã ghi đủ, nên chủ trọ tưởng chưa ghi (dungtv báo).
          //
          // Dùng lại `houseMeterEntriesProvider` (đã gộp sẵn chỉ số kỳ này +
          // chỉ số liền trước cho mọi phòng, chỉ 2 lượt gọi mạng cho cả nhà)
          // thay vì tự truy vấn riêng ở đây.
          final meterEntriesAsync = ref.watch(houseMeterEntriesProvider(
              (houseId: house.id, periodYm: period.start)));
          final meterEntries = meterEntriesAsync.valueOrNull;
          if (meterEntries == null) {
            return const Center(child: CircularProgressIndicator());
          }

          /// Giá trị hiển thị cho 1 ô tiện ích, tính ĐÚNG theo quy tắc của Edge
          /// Function `generate-invoice` để xem trước khớp hoá đơn thật:
          /// `NOT_BILLED` không tính, `FLAT` lấy tiền khoán, `BY_READING` lấy
          /// (chỉ số kỳ này − chỉ số liền trước) × đơn giá.
          ///
          /// Hợp đồng nhiều phòng thì CỘNG DỒN sản lượng mọi phòng — hoá đơn
          /// cũng gộp về một hợp đồng chứ không tách theo phòng.
          String utilityValue(UtilityType type) {
            final isElectricity = type == UtilityType.electricity;
            final method = isElectricity
                ? version.electricityBillingMethod
                : version.waterBillingMethod;
            if (method == UtilityBillingMethod.notBilled) return '—';
            if (method == UtilityBillingMethod.flat) {
              final flat = isElectricity
                  ? version.electricityFlatAmount
                  : version.waterFlatAmount;
              return flat == null ? '—' : formatNumber(flat);
            }
            final price = isElectricity
                ? version.electricityUnitPrice
                : version.waterUnitPrice;
            if (price == null) return '—';

            final roomIds = rooms.map((r) => r.id).toSet();
            num? usage;
            for (final entry in meterEntries) {
              if (entry.utilityType != type) continue;
              if (!roomIds.contains(entry.room.id)) continue;
              final current = entry.thisPeriod?.currentReading;
              final previous = entry.previous?.currentReading;
              // Thiếu 1 trong 2 đầu thì không ra được sản lượng — bỏ qua phòng
              // đó, đúng như backend (`usage = null` khi không có chỉ số trước).
              if (current == null || previous == null) continue;
              usage = (usage ?? 0) + (current - previous);
            }
            if (usage == null) {
              return AppStrings.t('invoiceSchedule.noReadingYet', {
                'price': formatNumber(price),
                'unit': type.unit,
              });
            }
            return AppStrings.t('invoiceSchedule.readingAmount', {
              'amount': formatNumber(usage * price),
              'usage': formatNumber(usage),
              'unit': type.unit,
              'price': formatNumber(price),
            });
          }

          final roomLabel = rooms.map((r) => r.roomNo).join(', ');
          final bank = VnBank.byBin(house.bankBin);
          final hasPayoutAccount =
              bank != null || house.bankAccountNumber != null;

          final fixedPartTotal = version.monthlyRent +
              (version.serviceFeeAmount ?? 0) +
              version.recurringFees.fold<num>(0, (sum, f) => sum + f.amount);

          return Column(
            children: [
              TopBar(
                title: AppStrings.t('invoiceSchedule.title',
                    {'period': DateFormat('MM/yyyy').format(period.start)}),
                subtitle: AppStrings.t(
                    'invoiceSchedule.subtitle', {'room': roomLabel}),
                onBack: () => context.pop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    AppBanner(
                        message: AppStrings.t('invoiceSchedule.previewBanner'),
                        tone: AppBannerTone.preview),
                    DetailBlock(children: [
                      DetailRow(
                          label: AppStrings.t('invoiceSchedule.house'),
                          value: house.name),
                      DetailRow(
                          label: AppStrings.t('invoiceSchedule.room'),
                          value: roomLabel),
                      DetailRow(
                          label: AppStrings.t('invoiceSchedule.tenant'),
                          value: tenant.fullName),
                      DetailRow(
                        label: AppStrings.t('invoiceSchedule.period'),
                        value:
                            '${DateFormat('dd/MM/yyyy').format(period.start)} → ${DateFormat('dd/MM/yyyy').format(period.end)}',
                      ),
                      DetailRow(
                          label: AppStrings.t('invoiceSchedule.dueDate'),
                          value:
                              DateFormat('dd/MM/yyyy').format(period.dueDate)),
                      DetailRow(
                        label: AppStrings.t('invoiceSchedule.contractTerms'),
                        value:
                            'v${version.versionNo} (${changeReasonLabel(version.changeReason)})',
                        showDivider: false,
                      ),
                    ]),
                    SectionLabel(AppStrings.t(
                        'invoiceSchedule.sectionEstimatedAmounts')),
                    DetailBlock(children: [
                      DetailRow(
                          label: AppStrings.t('invoiceSchedule.monthlyRent'),
                          value: formatNumber(version.monthlyRent)),
                      DetailRow(
                        label: AppStrings.t('contractDetail.electricity'),
                        value: utilityValue(UtilityType.electricity),
                      ),
                      DetailRow(
                        label: AppStrings.t('contractDetail.water'),
                        value: utilityValue(UtilityType.water),
                      ),
                      if (version.serviceFeeAmount != null)
                        DetailRow(
                            label: AppStrings.t('invoiceSchedule.service'),
                            value: formatNumber(version.serviceFeeAmount!)),
                      for (final fee in version.recurringFees)
                        DetailRow(
                            label: fee.name, value: formatNumber(fee.amount)),
                      DetailRow(
                        label: AppStrings.t('invoiceSchedule.fixedPartTotal'),
                        value: formatNumber(fixedPartTotal),
                        showDivider: false,
                      ),
                    ]),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(AppStrings.t('invoiceSchedule.termsNote'),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                    ),
                    SectionLabel(
                        AppStrings.t('invoiceSchedule.sectionPayoutAccount')),
                    DetailBlock(children: [
                      if (!hasPayoutAccount)
                        DetailRow(
                          label:
                              AppStrings.t('invoiceSchedule.noPayoutAccount'),
                          value: '—',
                          showDivider: false,
                        )
                      else ...[
                        DetailRow(
                            label: AppStrings.t('invoiceSchedule.bank'),
                            value: bank?.name ?? '—'),
                        DetailRow(
                            label: AppStrings.t('invoiceSchedule.accountName'),
                            value: house.bankAccountName ?? '—'),
                        DetailRow(
                          label: AppStrings.t('invoiceSchedule.accountNumber'),
                          value: house.bankAccountNumber ?? '—',
                          showDivider: false,
                        ),
                      ],
                    ]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

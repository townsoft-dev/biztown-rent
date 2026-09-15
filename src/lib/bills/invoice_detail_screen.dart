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
import '../data/models/invoice.dart';
import '../data/models/vn_bank.dart';
import '../shared/app_button.dart';
import '../shared/confirm_dialog.dart';
import '../shared/detail_row.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';
import 'send_invoice_sheet.dart';

/// B-04 — Invoice Detail (node 220:4544, Figma) — hiện đầy đủ breakdown đã
/// snapshot của 1 hoá đơn + hành động theo trạng thái (Mark as collected/
/// Resend/Undo collected/Delete draft). Không có luồng chỉnh sửa số liệu ở
/// đây — mọi số liệu là snapshot cố định tại thời điểm tạo (B-02/B-03), chỉ
/// `otherFees` sửa được lúc còn Draft (ở B-02, trước khi rời màn đó).
class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _busy = false;

  void _invalidateAll() {
    // `billsHouseGroupsProvider`/T-05 đọc hoá đơn qua `contractInvoicesProvider`
    // (family theo contractId) — phải invalidate riêng, nếu không B-01/T-05
    // tiếp tục hiện trạng thái CŨ dù hoá đơn vừa đổi (xem docs/DECISIONS.md).
    final contractId =
        ref.read(invoiceProvider(widget.invoiceId)).valueOrNull?.contractId;
    ref.invalidate(invoiceProvider(widget.invoiceId));
    if (contractId != null) {
      ref.invalidate(contractInvoicesProvider(contractId));
    }
    ref.invalidate(billsHouseGroupsProvider);
    ref.invalidate(invoicesProvider);
  }

  Future<void> _markAsCollected() async {
    setState(() => _busy = true);
    await ref
        .read(invoiceRepositoryProvider)
        .updateStatus(widget.invoiceId, InvoiceStatus.collected);
    // BR-NOTI-03 — báo cho người khác cùng quyền trên nhà đó biết đã thu tiền.
    final actorPhone = ref.read(currentUserProfileProvider).valueOrNull?.phone;
    if (actorPhone != null) {
      await ref.read(notificationRepositoryProvider).notifyInvoiceCollected(
          invoiceId: widget.invoiceId, actorPhone: actorPhone);
    }
    _invalidateAll();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _undoCollected() async {
    setState(() => _busy = true);
    await ref.read(invoiceRepositoryProvider).undoCollected(widget.invoiceId);
    _invalidateAll();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _sendOrResend() async {
    await showSendInvoiceSheet(context, ref, widget.invoiceId);
    _invalidateAll();
  }

  Future<void> _deleteDraft() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.t('bills.deleteDraft'),
      description: AppStrings.t('bills.deleteDraftConfirmDescription'),
      confirmLabel: AppStrings.t('common.delete'),
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final contractId =
        ref.read(invoiceProvider(widget.invoiceId)).valueOrNull?.contractId;
    await ref.read(invoiceRepositoryProvider).deleteDraft(widget.invoiceId);
    if (contractId != null) {
      ref.invalidate(contractInvoicesProvider(contractId));
    }
    ref.invalidate(billsHouseGroupsProvider);
    ref.invalidate(invoicesProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final invoiceAsync = ref.watch(invoiceProvider(widget.invoiceId));
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(
            title: invoiceAsync.maybeWhen(
              data: (invoice) => AppStrings.t('bills.invoiceTitle', {
                'period': DateFormat('MM/yyyy').format(invoice.periodStart)
              }),
              orElse: () => AppStrings.t('bills.title'),
            ),
            subtitle: invoiceAsync.maybeWhen(
              data: (invoice) =>
                  '${invoice.roomNos.join(', ')} · ${invoice.tenantName}',
              orElse: () => '',
            ),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: invoiceAsync.when(
              data: (invoice) => _buildBody(invoice),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Invoice invoice) {
    final house = ref.watch(houseProvider(invoice.houseId)).valueOrNull;
    final version = ref
        .watch(contractVersionProvider(invoice.contractVersionId))
        .valueOrNull;
    final bank = VnBank.byBin(house?.bankBin);

    final style = invoice.isOverdue
        ? StatusBadgeStyle.overdue
        : switch (invoice.status) {
            InvoiceStatus.draft => StatusBadgeStyle.draft,
            InvoiceStatus.sent => StatusBadgeStyle.sent,
            InvoiceStatus.collected => StatusBadgeStyle.collected,
          };
    final label = invoice.isOverdue
        ? AppStrings.t('status.overdue')
        : invoiceStatusLabel(invoice.status);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgDefault,
                border: Border.all(color: AppColors.borderSubtle),
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusPill(text: label, style: style),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${DateFormat('dd/MM/yyyy').format(invoice.periodStart)} → ${DateFormat('dd/MM/yyyy').format(invoice.periodEnd)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${formatNumber(invoice.totalAmount)} VND',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    '${AppStrings.t('bills.dueOn', {
                          'date':
                              DateFormat('dd/MM/yyyy').format(invoice.dueDate)
                        })} · ${AppStrings.t('contractDetail.paymentDueValue', {
                          'day': '${invoice.dueDate.day}'
                        })}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            SectionLabel(AppStrings.t('bills.snapshotAtIssueTime')),
            DetailBlock(children: [
              DetailRow(
                  label: AppStrings.t('bills.house'), value: invoice.houseName),
              DetailRow(
                  label: AppStrings.t('bills.room'),
                  value: invoice.roomNos.join(', ')),
              DetailRow(
                  label: AppStrings.t('bills.tenant'),
                  value: invoice.tenantName),
              DetailRow(
                label: AppStrings.t('bills.contractTerms'),
                value: version == null
                    ? '—'
                    : AppStrings.t('bills.contractTermsValue', {
                        'version': '${version.versionNo}',
                        'reason': changeReasonLabel(version.changeReason),
                      }),
                showDivider: false,
              ),
            ]),
            SectionLabel(AppStrings.t('bills.breakdownSection')),
            DetailBlock(children: _breakdownRows(invoice)),
            SectionLabel(AppStrings.t('bills.timelineSection')),
            DetailBlock(children: [
              DetailRow(
                  label: AppStrings.t('bills.created'),
                  value:
                      DateFormat('dd/MM/yyyy HH:mm').format(invoice.createdAt)),
              DetailRow(
                  label: AppStrings.t('status.sent'),
                  value: invoice.sentAt == null
                      ? '—'
                      : DateFormat('dd/MM/yyyy HH:mm').format(invoice.sentAt!)),
              DetailRow(
                  label: AppStrings.t('status.collected'),
                  value: invoice.collectedAt == null
                      ? '—'
                      : DateFormat('dd/MM/yyyy HH:mm')
                          .format(invoice.collectedAt!),
                  showDivider: false),
            ]),
            SectionLabel(AppStrings.t('bills.payoutAccount')),
            DetailBlock(children: [
              DetailRow(
                  label: AppStrings.t('bills.bank'), value: bank?.name ?? '—'),
              DetailRow(
                  label: AppStrings.t('bills.accountName'),
                  value: house?.bankAccountName ?? '—'),
              DetailRow(
                  label: AppStrings.t('bills.accountNumber'),
                  value: house?.bankAccountNumber ?? '—',
                  showDivider: false),
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: AppStrings.t('bills.markAsCollected'),
                    style: AppButtonStyle.accent,
                    onPressed:
                        invoice.status == InvoiceStatus.collected || _busy
                            ? null
                            : _markAsCollected,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: AppStrings.t(invoice.status == InvoiceStatus.draft
                        ? 'bills.send'
                        : 'bills.resend'),
                    style: AppButtonStyle.ghost,
                    onPressed: _busy ? null : _sendOrResend,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: AppStrings.t('bills.undoCollected'),
                    style: AppButtonStyle.ghost,
                    onPressed:
                        invoice.status == InvoiceStatus.collected && !_busy
                            ? _undoCollected
                            : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: AppStrings.t('bills.deleteDraft'),
                    style: AppButtonStyle.danger,
                    onPressed: invoice.status == InvoiceStatus.draft && !_busy
                        ? _deleteDraft
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.t('bills.deleteDraftHint'),
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  List<Widget> _breakdownRows(Invoice invoice) {
    final rows = <Widget>[];
    if (invoice.rentAmount > 0) {
      rows.add(DetailRow(
          label: AppStrings.t('contractDetail.monthlyRent'),
          value: formatNumber(invoice.rentAmount)));
    }
    for (final line in invoice.utilityLines) {
      final utilityLabel = AppStrings.t(
          line.utilityType == InvoiceUtilityType.electricity
              ? 'contractDetail.electricity'
              : 'contractDetail.water');
      final roomLabel = invoice.roomNos.length > 1
          ? '$utilityLabel · ${line.roomNo}'
          : utilityLabel;
      if (line.isFlat) {
        rows.add(DetailRow(
            label: '$roomLabel · ${AppStrings.t('bills.flatAmount')}',
            value: formatNumber(line.totalAmount)));
        continue;
      }
      rows.addAll([
        DetailRow(
            label: '$roomLabel · ${AppStrings.t('bills.fromReading')}',
            value: formatNumber(line.previousReading ?? 0)),
        DetailRow(
            label: AppStrings.t('bills.toReading'),
            value: formatNumber(line.currentReading ?? 0)),
        DetailRow(
            label: AppStrings.t('bills.usageForThisRoom'),
            value: formatNumber(line.usageAmount ?? 0)),
        DetailRow(
            label: AppStrings.t(
                line.utilityType == InvoiceUtilityType.electricity
                    ? 'bills.electricityAmount'
                    : 'bills.waterAmount'),
            value: formatNumber(line.totalAmount)),
      ]);
    }
    if (invoice.serviceFeeAmount > 0) {
      rows.add(DetailRow(
          label: AppStrings.t('contractDetail.service'),
          value: formatNumber(invoice.serviceFeeAmount)));
    }
    for (final fee in invoice.recurringFees) {
      rows.add(DetailRow(label: fee.name, value: formatNumber(fee.amount)));
    }
    for (final fee in invoice.otherFees) {
      rows.add(DetailRow(label: fee.name, value: formatNumber(fee.amount)));
    }
    rows.add(DetailRow(
        label: AppStrings.t('bills.total'),
        value: formatNumber(invoice.totalAmount),
        showDivider: false));
    return rows;
  }
}

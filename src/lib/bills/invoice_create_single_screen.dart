import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/app_strings.dart';
import '../core/invoice_period.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/invoice_repository.dart';
import '../data/models/invoice.dart';
import '../data/models/recurring_fee.dart';
import '../data/models/vn_bank.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/detail_row.dart';
import '../shared/section_label.dart';
import '../shared/top_bar.dart';
import 'send_invoice_sheet.dart';

/// B-02 — Create Invoice (Single) (node 220:4331, Figma) — Figma vẽ như 1
/// màn "xem trước" nhưng Edge Function `generate-invoice` (nguồn tính tiền
/// duy nhất, xem docs/DECISIONS.md Đợt 31) luôn INSERT thật ngay khi gọi,
/// không có chế độ dry-run. dungtv xác nhận (2026-09-14): mở màn này gọi
/// `generate-invoice` NGAY (tạo Draft thật) — 2 nút bên dưới chỉ là bước
/// tiếp theo (ở lại Draft / sang B-05 gửi), không phải bước "tạo" riêng.
/// Draft bỏ dở có thể xoá sau ở B-04 ("Delete draft").
class InvoiceCreateSingleScreen extends ConsumerStatefulWidget {
  final String contractId;

  const InvoiceCreateSingleScreen({super.key, required this.contractId});

  @override
  ConsumerState<InvoiceCreateSingleScreen> createState() =>
      _InvoiceCreateSingleScreenState();
}

class _InvoiceCreateSingleScreenState
    extends ConsumerState<InvoiceCreateSingleScreen> {
  Invoice? _invoice;
  String? _errorText;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final contract =
          await ref.read(contractProvider(widget.contractId).future);
      final version = await ref
          .read(contractVersionProvider(contract.currentVersionId!).future);
      final invoices =
          await ref.read(contractInvoicesProvider(widget.contractId).future);
      final chips = buildInvoiceScheduleChips(version, invoices);
      final periodYm = chips.first.periodStart;

      final invoice = await ref
          .read(invoiceRepositoryProvider)
          .generateSingle(contractId: widget.contractId, periodYm: periodYm);
      // BR-NOTI-01 — backend vừa ghi thông báo "invoice_sent"; chuông ở Home
      // tự cập nhật qua Realtime (`notificationsProvider`), không cần invalidate.
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _loading = false;
      });
    } on InvoiceSkippedException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.reason;
        _loading = false;
      });
    } catch (e) {
      // Không để màn kẹt loading vô hạn nếu Edge Function lỗi bất ngờ (403
      // thiếu quyền, mất mạng...) — luôn thoát ra thông báo lỗi rõ ràng.
      if (!mounted) return;
      setState(() {
        _errorText = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _addOtherFee() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final result = await showDialog<RecurringFee>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.t('bills.addOtherFeeTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
                label: AppStrings.t('bills.otherFeeName'),
                controller: nameController),
            const SizedBox(height: 10),
            AppTextField(
              label: AppStrings.t('bills.otherFeeAmount'),
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsInputFormatter()],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.t('common.cancel'))),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final amount = parseFormattedNumber(amountController.text);
              if (name.isEmpty || amount == null) return;
              Navigator.of(context)
                  .pop(RecurringFee(name: name, amount: amount));
            },
            child: Text(AppStrings.t('common.save')),
          ),
        ],
      ),
    );
    if (result == null || _invoice == null) return;
    final updated = await ref
        .read(invoiceRepositoryProvider)
        .addOtherFee(_invoice!, result);
    setState(() => _invoice = updated);
  }

  void _invalidateAfterSave() {
    ref.invalidate(billsHouseGroupsProvider);
    ref.invalidate(contractInvoicesProvider(widget.contractId));
    ref.invalidate(invoicesProvider);
  }

  Future<void> _saveAsDraft() async {
    _invalidateAfterSave();
    if (mounted) context.pop();
  }

  Future<void> _sendInvoice() async {
    if (_invoice == null) return;
    final sentMessage = await showSendInvoiceSheet(context, ref, _invoice!.id);
    if (sentMessage != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(sentMessage)));
    }
    _invalidateAfterSave();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(
            title: AppStrings.t('bills.createInvoiceTitle'),
            subtitle: _invoice == null
                ? ''
                : AppStrings.t('bills.createInvoiceSubtitle', {
                    'rooms': _invoice!.roomNos.join(', '),
                    'period':
                        DateFormat('MM/yyyy').format(_invoice!.periodStart),
                  }),
            onBack: () => context.pop(),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorText!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error)),
        ),
      );
    }
    final invoice = _invoice!;
    final rooms = invoice.roomNos;
    final house = ref.watch(houseProvider(invoice.houseId)).valueOrNull;
    final bank = VnBank.byBin(house?.bankBin);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        AppTextField(
          label: AppStrings.t('bills.contract'),
          initialValue: '${rooms.join(', ')} — ${invoice.tenantName}',
          readOnly: true,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.t('bills.periodStart'),
                initialValue:
                    DateFormat('dd/MM/yyyy').format(invoice.periodStart),
                readOnly: true,
                trailing: AppTextFieldTrailingIcon.date,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppTextField(
                label: AppStrings.t('bills.periodEnd'),
                initialValue:
                    DateFormat('dd/MM/yyyy').format(invoice.periodEnd),
                readOnly: true,
                trailing: AppTextFieldTrailingIcon.date,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final type in [
          InvoiceUtilityType.electricity,
          InvoiceUtilityType.water
        ]) ...[
          SectionLabel(AppStrings.t(type == InvoiceUtilityType.electricity
              ? 'contractDetail.electricity'
              : 'contractDetail.water')),
          for (final line
              in invoice.utilityLines.where((l) => l.utilityType == type)) ...[
            _UtilityLineBlock(
                line: line,
                showRoomLabel: rooms.length > 1,
                utilityLabel: AppStrings.t(
                    type == InvoiceUtilityType.electricity
                        ? 'contractDetail.electricity'
                        : 'contractDetail.water')),
            const SizedBox(height: 10),
          ],
        ],
        SectionLabel(AppStrings.t('bills.sectionRentAndFees')),
        DetailBlock(children: [
          if (invoice.rentAmount > 0)
            DetailRow(
              label: AppStrings.t('contractDetail.monthlyRent'),
              value: formatNumber(invoice.rentAmount),
            ),
          if (invoice.serviceFeeAmount > 0)
            DetailRow(
                label: AppStrings.t('contractDetail.service'),
                value: formatNumber(invoice.serviceFeeAmount)),
          for (final fee in invoice.recurringFees)
            DetailRow(label: fee.name, value: formatNumber(fee.amount)),
          for (final fee in invoice.otherFees)
            DetailRow(
                label: fee.name,
                value: formatNumber(fee.amount),
                showDivider: fee != invoice.otherFees.last),
        ]),
        const SizedBox(height: 8),
        AppButton(
            label: AppStrings.t('bills.addOtherFee'),
            style: AppButtonStyle.ghost,
            size: AppButtonSize.sm,
            onPressed: _addOtherFee),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadii.card)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.t('bills.total'),
                  style: const TextStyle(fontSize: 14, color: Colors.white)),
              Text('${formatNumber(invoice.totalAmount)} VND',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppTextField(
          label: AppStrings.t('bills.paymentDue'),
          initialValue: DateFormat('dd/MM/yyyy').format(invoice.dueDate),
          readOnly: true,
        ),
        const SizedBox(height: 10),
        AppTextField(
          label: AppStrings.t('bills.payoutAccount'),
          initialValue: house == null
              ? '—'
              : '${bank?.name ?? '—'} · ${house.bankAccountName ?? '—'} · ${house.bankAccountNumber ?? '—'}',
          readOnly: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppButton(
                  label: AppStrings.t('bills.saveAsDraft'),
                  style: AppButtonStyle.ghost,
                  onPressed: _saveAsDraft),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                  label: AppStrings.t('bills.sendInvoice'),
                  style: AppButtonStyle.accent,
                  onPressed: _sendInvoice),
            ),
          ],
        ),
      ],
    );
  }
}

class _UtilityLineBlock extends StatelessWidget {
  final UtilityLine line;
  final bool showRoomLabel;
  final String utilityLabel;

  const _UtilityLineBlock(
      {required this.line,
      required this.showRoomLabel,
      required this.utilityLabel});

  @override
  Widget build(BuildContext context) {
    if (line.isFlat) {
      return DetailBlock(children: [
        DetailRow(
          label: showRoomLabel
              ? '${line.roomNo} · ${AppStrings.t('bills.flatAmount')}'
              : AppStrings.t('bills.flatAmount'),
          value: formatNumber(line.totalAmount),
          showDivider: false,
        ),
      ]);
    }
    return DetailBlock(children: [
      DetailRow(
          label: showRoomLabel
              ? '${line.roomNo} · ${AppStrings.t('bills.fromReading')}'
              : AppStrings.t('bills.fromReading'),
          value: '${formatNumber(line.previousReading ?? 0)} $utilityLabel'),
      DetailRow(
          label: AppStrings.t('bills.toReading'),
          value: '${formatNumber(line.currentReading ?? 0)} $utilityLabel'),
      DetailRow(
          label: AppStrings.t('bills.usageForThisRoom'),
          value: formatNumber(line.usageAmount ?? 0)),
      DetailRow(
          label: AppStrings.t('bills.unitPriceFromContract'),
          value: formatNumber(line.unitPrice ?? 0)),
      DetailRow(
          label: AppStrings.t(
              utilityLabel == AppStrings.t('contractDetail.electricity')
                  ? 'bills.electricityAmount'
                  : 'bills.waterAmount'),
          value: formatNumber(line.totalAmount),
          showDivider: false),
    ]);
  }
}

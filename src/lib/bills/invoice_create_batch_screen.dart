import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/app_strings.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/invoice_repository.dart';
import '../data/models/house.dart';
import '../shared/app_banner.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';
import 'batch_send_channel_sheet.dart';

/// B-03 — Create Invoice (Batch) (node 220:4448, Figma) — xem trước (KHÔNG
/// tạo thật) trạng thái + số tiền ước tính của mọi hợp đồng Active trong 1
/// Nhà/1 kỳ (`mode: "previewBatch"`, chạy song song theo lô ở Edge Function —
/// xem docs/DECISIONS.md), người dùng tick chọn trong số các dòng "Ready" rồi
/// bấm tạo — "Save all as draft"/"Create & send all" gọi ĐÚNG 1 lần
/// `mode: "batchSend"`, để BACKEND tự lặp tạo (+ gửi SMS nếu chọn) cho toàn
/// bộ danh sách đã chọn, KHÔNG phải app tự lặp gọi từng hợp đồng — tránh rủi
/// ro tiến trình bị hệ điều hành tạm dừng giữa chừng nếu người dùng khoá màn
/// hình/chuyển app trong lúc đang chạy (dungtv xác nhận 2026-09-14).
class InvoiceCreateBatchScreen extends ConsumerStatefulWidget {
  final String houseId;

  const InvoiceCreateBatchScreen({super.key, required this.houseId});

  @override
  ConsumerState<InvoiceCreateBatchScreen> createState() =>
      _InvoiceCreateBatchScreenState();
}

class _InvoiceCreateBatchScreenState
    extends ConsumerState<InvoiceCreateBatchScreen> {
  DateTime _period = DateTime(DateTime.now().year, DateTime.now().month, 1);
  final Set<String> _selected = {};
  bool _submitting = false;
  // Khác null trong lúc hiện kết quả thành công (dấu tick + tóm tắt) trước
  // khi tự đóng màn — dungtv phản hồi overlay "Đang xử lý..." tắt đột ngột
  // không rõ đã xong hay chưa, nên phải có bước xác nhận rõ ràng trước khi rời màn.
  String? _resultSummary;

  Future<void> _pickPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _period,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    setState(() {
      _period = DateTime(picked.year, picked.month, 1);
      _selected.clear();
    });
  }

  void _selectAllReady(List<BatchPreviewItem> items) {
    setState(() {
      _selected
        ..clear()
        ..addAll(items
            .where((i) => i.status == BatchPreviewStatus.ready)
            .map((i) => i.contractId));
    });
  }

  void _clearSelection() => setState(_selected.clear);

  void _toggle(String contractId) {
    setState(() {
      if (!_selected.remove(contractId)) _selected.add(contractId);
    });
  }

  Future<void> _submit({required bool sendAfter}) async {
    if (_selected.isEmpty || _submitting) return;
    // "Create & send all" gửi SMS thật cho cả lô — chỉ hỏi kênh 1 LẦN (không
    // hiện preview nội dung từng hoá đơn như B-05 vì mỗi hoá đơn 1 nội dung
    // khác nhau, không hợp lý lặp lại 15-20 lần). Huỷ ở đây thì KHÔNG tạo gì
    // cả (khác "Save as draft" luôn tạo thật).
    if (sendAfter) {
      final confirmed =
          await showBatchSendChannelSheet(context, count: _selected.length);
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _submitting = true;
      _resultSummary = null;
    });
    final ids = _selected.toList();
    try {
      final result =
          await ref.read(invoiceRepositoryProvider).batchCreateAndSend(
                houseId: widget.houseId,
                periodYm: _period,
                contractIds: ids,
                send: sendAfter,
              );
      // `billsHouseGroupsProvider` đọc lại hoá đơn qua `contractInvoicesProvider`
      // (family theo contractId) — phải invalidate riêng từng contract vừa tạo,
      // nếu không nó tự re-run nhưng vẫn đọc lại giá trị CŨ đã cache của family
      // con, khiến B-01/T-05 tiếp tục hiện "Draft"/"chưa tạo" dù backend đã
      // tạo + gửi thành công (phát hiện khi live-test thật, xem docs/DECISIONS.md).
      for (final id in ids) {
        ref.invalidate(contractInvoicesProvider(id));
      }
      ref.invalidate(billsHouseGroupsProvider);
      ref.invalidate(invoicesProvider);
      ref.invalidate(batchPreviewProvider);
      // BR-NOTI-01 — backend vừa ghi thông báo "invoice_sent"; chuông ở Home
      // tự cập nhật qua Realtime (`notificationsProvider`), không cần invalidate.
      if (!mounted) return;

      if (result.created > 0 && result.errors.isEmpty) {
        // Hiện rõ kết quả thành công (dấu tick + tóm tắt) một nhịp trước khi
        // tự đóng màn, thay vì tắt overlay đột ngột — người dùng cần thấy rõ
        // đã xong, không phải đoán.
        setState(() {
          _selected.clear();
          _resultSummary = sendAfter
              ? AppStrings.t(
                  'bills.batchSentSuccess', {'count': '${result.sent}'})
              : AppStrings.t(
                  'bills.batchDraftSuccess', {'count': '${result.created}'});
        });
        await Future.delayed(const Duration(milliseconds: 1300));
        if (!mounted) return;
        context.pop();
        return;
      }

      setState(() {
        _submitting = false;
        _selected.clear();
      });
      if (result.errors.isNotEmpty) {
        final message = result.errors.map((e) => e.reason).join('; ');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      // Không để màn kẹt loading vô hạn nếu Edge Function lỗi bất ngờ.
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final house = ref.watch(houseProvider(widget.houseId)).valueOrNull;
    final previewAsync = ref.watch(
        batchPreviewProvider((houseId: widget.houseId, periodYm: _period)));
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Stack(
        children: [
          Column(
            children: [
              TopBar(
                title: AppStrings.t('bills.createBatchTitle'),
                subtitle: AppStrings.t('bills.batchSubtitle',
                    {'period': DateFormat('MM/yyyy').format(_period)}),
                // Khoá nút Back trong lúc đang tạo/gửi hàng loạt — tránh rời
                // màn giữa chừng khi backend chưa trả kết quả.
                onBack: _submitting ? null : () => context.pop(),
              ),
              Expanded(
                child: previewAsync.when(
                  data: (items) => _buildBody(house, items),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('$e')),
                ),
              ),
            ],
          ),
          if (_submitting)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0x66000000),
                child: Center(
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: AppColors.bgDefault,
                        borderRadius: BorderRadius.circular(AppRadii.card)),
                    child: _resultSummary == null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.pill),
                                child: const LinearProgressIndicator(
                                  minHeight: 6,
                                  backgroundColor: AppColors.borderSubtle,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppStrings.t('bills.batchProcessing'),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Symbols.check_circle_rounded,
                                  size: 36, color: AppColors.success),
                              const SizedBox(height: 10),
                              Text(
                                _resultSummary!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(House? house, List<BatchPreviewItem> items) {
    final readyCount =
        items.where((i) => i.status == BatchPreviewStatus.ready).length;
    final missingCount = items
        .where((i) => i.status == BatchPreviewStatus.missingReading)
        .length;
    final selectedItems =
        items.where((i) => _selected.contains(i.contractId)).toList();
    final selectedTotal =
        selectedItems.fold<num>(0, (sum, i) => sum + i.totalAmount);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.t('bills.house'),
                      initialValue: house?.name ?? '',
                      readOnly: true,
                      trailing: AppTextFieldTrailingIcon.select,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.t('bills.period'),
                      initialValue: DateFormat('MM/yyyy').format(_period),
                      readOnly: true,
                      trailing: AppTextFieldTrailingIcon.select,
                      onTap: _submitting ? null : _pickPeriod,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppBanner(
                message: AppStrings.t('bills.batchBannerInfo', {
                  'total': '${items.length}',
                  'ready': '$readyCount',
                  'missing': '$missingCount',
                }),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  AppButton(
                      label: AppStrings.t('bills.selectAllReady'),
                      style: AppButtonStyle.ghost,
                      size: AppButtonSize.sm,
                      onPressed:
                          _submitting ? null : () => _selectAllReady(items)),
                  const SizedBox(width: 8),
                  AppButton(
                      label: AppStrings.t('common.clear'),
                      style: AppButtonStyle.ghost,
                      size: AppButtonSize.sm,
                      onPressed: _submitting ? null : _clearSelection),
                ],
              ),
              SectionLabel(AppStrings.t('bills.contractsSection')),
              for (final item in items) ...[
                _BatchContractRow(
                  item: item,
                  checked: _selected.contains(item.contractId),
                  onTap: item.status == BatchPreviewStatus.ready && !_submitting
                      ? () => _toggle(item.contractId)
                      : null,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadii.card)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    AppStrings.t('bills.invoicesSelected',
                        {'count': '${selectedItems.length}'}),
                    style: const TextStyle(fontSize: 14, color: Colors.white)),
                Text('${formatNumber(selectedTotal)} VND',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: AppStrings.t('bills.saveAllAsDraft'),
                  style: AppButtonStyle.ghost,
                  onPressed: _selected.isEmpty || _submitting
                      ? null
                      : () => _submit(sendAfter: false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: AppStrings.t('bills.createAndSendAll'),
                  style: AppButtonStyle.accent,
                  onPressed: _selected.isEmpty || _submitting
                      ? null
                      : () => _submit(sendAfter: true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BatchContractRow extends StatelessWidget {
  final BatchPreviewItem item;
  final bool checked;
  final VoidCallback? onTap;

  const _BatchContractRow(
      {required this.item, required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = item.status != BatchPreviewStatus.ready;
    final badgeStyle = switch (item.status) {
      BatchPreviewStatus.ready => StatusBadgeStyle.ready,
      BatchPreviewStatus.missingReading => StatusBadgeStyle.noReading,
      BatchPreviewStatus.alreadyCreated => StatusBadgeStyle.alreadyCreated,
    };
    final badgeLabel = switch (item.status) {
      BatchPreviewStatus.ready => AppStrings.t('bills.previewReady'),
      BatchPreviewStatus.missingReading =>
        AppStrings.t('bills.previewMissingReading'),
      BatchPreviewStatus.alreadyCreated =>
        AppStrings.t('bills.previewAlreadyCreated'),
    };
    final title = item.roomNos.isEmpty
        ? item.tenantName
        : '${item.roomNos.join(', ')} · ${item.tenantName}';
    final amountText = item.status == BatchPreviewStatus.missingReading
        ? '—'
        : formatNumber(item.totalAmount);

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.checkRow),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            border: Border.all(
              color: checked ? AppColors.primary : AppColors.borderSubtle,
              width: checked ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadii.checkRow),
          ),
          child: Row(
            children: [
              Icon(
                checked
                    ? Symbols.check_box_rounded
                    : Symbols.check_box_outline_blank_rounded,
                size: 20,
                color: checked ? AppColors.primary : AppColors.neutral200,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 8),
              Text(amountText,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(width: 8),
              StatusPill(text: badgeLabel, style: badgeStyle),
            ],
          ),
        ),
      ),
    );
  }
}

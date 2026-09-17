import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/app_strings.dart';
import '../core/invoice_message.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/invoice.dart';
import '../shared/app_button.dart';
import '../shared/channel_option.dart';

/// B-05 — Send Invoice (bottom sheet, node `220:4667`, Figma). Chỉ kênh SMS
/// hoạt động thật (qua eSMS, xem `InvoiceRepository.sendSms`) — Zalo/Both vẽ
/// đúng UI theo Figma nhưng khoá lại (không tick được, phụ đề "Coming soon")
/// vì CHƯA có Zalo OA/App ID/Access token/Template ZNS (dungtv xác nhận
/// 2026-09-14 — chờ cung cấp, xem docs/DECISIONS.md Đợt 35). Bật lại 2 kênh
/// này sau chỉ cần đổi state, không cần sửa layout.
Future<bool?> showSendInvoiceSheet(
    BuildContext context, WidgetRef ref, String invoiceId) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SendInvoiceSheet(invoiceId: invoiceId),
  );
}

class _SendInvoiceSheet extends ConsumerStatefulWidget {
  final String invoiceId;
  const _SendInvoiceSheet({required this.invoiceId});

  @override
  ConsumerState<_SendInvoiceSheet> createState() => _SendInvoiceSheetState();
}

/// Kênh gửi hoá đơn CHỌN ĐƯỢC. Zalo vẫn hiện trong danh sách nhưng khoá lại
/// (chờ công ty mua gói Zalo OA — dungtv, 17/09/2026) nên cố tình không có
/// trong enum này: không chọn được thì không cần trạng thái.
enum _SendChannel { sms, email }

class _SendInvoiceSheetState extends ConsumerState<_SendInvoiceSheet> {
  _SendChannel _channel = _SendChannel.sms;
  bool _sending = false;
  String? _errorText;

  Future<void> _send(Invoice invoice, String? phone, String message) async {
    setState(() {
      _sending = true;
      _errorText = null;
    });
    try {
      final repo = ref.read(invoiceRepositoryProvider);
      if (_channel == _SendChannel.email) {
        await repo.sendEmail(invoiceId: invoice.id);
      } else {
        await repo.sendSms(
          invoiceId: invoice.id,
          houseId: invoice.houseId,
          phone: phone!,
          message: message,
        );
      }
      ref.invalidate(invoiceProvider(invoice.id));
      // `billsHouseGroupsProvider`/T-05 đọc hoá đơn qua `contractInvoicesProvider`
      // (family theo contractId) — phải invalidate riêng, nếu không B-01/T-05
      // tiếp tục hiện trạng thái CŨ dù vừa gửi xong (xem docs/DECISIONS.md).
      ref.invalidate(contractInvoicesProvider(invoice.contractId));
      ref.invalidate(billsHouseGroupsProvider);
      ref.invalidate(invoicesProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = '$e';
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceAsync = ref.watch(invoiceProvider(widget.invoiceId));
    return SafeArea(
      top: false,
      child: invoiceAsync.when(
        data: (invoice) => _buildSheet(context, invoice),
        loading: () => const SizedBox(
            height: 220, child: Center(child: CircularProgressIndicator())),
        error: (e, st) => SizedBox(
            height: 120,
            child: Center(
                child: Text('$e',
                    style: const TextStyle(color: AppColors.error)))),
      ),
    );
  }

  Widget _buildSheet(BuildContext context, Invoice invoice) {
    final contractAsync = ref.watch(contractProvider(invoice.contractId));
    final tenant = contractAsync.maybeWhen(
      data: (contract) =>
          ref.watch(tenantProvider(contract.tenantId)).valueOrNull,
      orElse: () => null,
    );
    final phone = tenant?.phone;
    final email = (tenant?.mail ?? '').trim();
    final message = buildInvoiceSmsMessage(invoice);

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(AppRadii.pill)),
            ),
          ),
          const SizedBox(height: 12),
          Text(AppStrings.t('bills.sendInvoiceSheetTitle'),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(
            AppStrings.t('bills.sendInvoiceSheetTo',
                {'name': invoice.tenantName, 'phone': phone ?? '—'}),
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ChannelOption(
            icon: Symbols.sms_rounded,
            title: AppStrings.t('bills.channelSms'),
            subtitle:
                AppStrings.t('bills.channelSmsHint', {'phone': phone ?? '—'}),
            selected: _channel == _SendChannel.sms,
            enabled: true,
            onTap: () => setState(() => _channel = _SendChannel.sms),
          ),
          const SizedBox(height: 8),
          ChannelOption(
            icon: Symbols.mail_rounded,
            title: AppStrings.t('bills.channelEmail'),
            // Email người thuê nay là trường bắt buộc, nhưng hồ sơ tạo trước
            // 17/09/2026 có thể còn trống — khoá kênh này lại thay vì để bấm
            // rồi mới báo lỗi.
            subtitle: email.isEmpty
                ? AppStrings.t('bills.channelEmailNone')
                : AppStrings.t('bills.channelEmailHint', {'email': email}),
            selected: _channel == _SendChannel.email,
            enabled: email.isNotEmpty,
            onTap: () => setState(() => _channel = _SendChannel.email),
          ),
          const SizedBox(height: 8),
          ChannelOption(
            icon: Symbols.chat_rounded,
            title: AppStrings.t('bills.channelZalo'),
            subtitle: AppStrings.t('bills.channelComingSoon'),
            selected: false,
            enabled: false,
          ),
          // Khối "Xem trước tin nhắn" CHỈ dành cho kênh SMS — đó là nội dung
          // app tự dựng và gửi thẳng. Thư điện tử do backend dựng theo mẫu
          // của Hường nên đoạn text này không phản ánh thứ người thuê nhận
          // được; để nguyên lúc chọn Email là đánh lừa chủ trọ (thấy khi test
          // thật 17/09/2026).
          if (_channel == _SendChannel.sms) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.bgMuted,
                  borderRadius: BorderRadius.circular(AppRadii.checkRow)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.t('bills.messagePreview').toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                          color: AppColors.textTertiary)),
                  const SizedBox(height: 4),
                  Text(message,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(_errorText!,
                style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ],
          if (_channel == _SendChannel.sms && phone == null) ...[
            const SizedBox(height: 8),
            Text(AppStrings.t('bills.tenantPhoneMissing'),
                style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: AppStrings.t('common.cancel'),
                  style: AppButtonStyle.ghost,
                  onPressed:
                      _sending ? null : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: AppStrings.t('bills.sendNow'),
                  style: AppButtonStyle.accent,
                  // SMS cần SĐT, Email cần email — thiếu thứ tương ứng thì
                  // khoá nút thay vì để bấm rồi mới báo lỗi.
                  onPressed: _sending ||
                          (_channel == _SendChannel.sms && phone == null) ||
                          (_channel == _SendChannel.email && email.isEmpty)
                      ? null
                      : () => _send(invoice, phone, message),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/app_strings.dart';
import '../core/theme.dart';
import '../shared/app_button.dart';
import '../shared/channel_option.dart';

/// B-03 "Create & send all" — chọn kênh gửi 1 LẦN cho cả lô hoá đơn sắp tạo
/// (khác B-05 vốn hiện preview nội dung của ĐÚNG 1 hoá đơn — không hợp lý áp
/// dụng cho hàng loạt vì mỗi hoá đơn 1 nội dung khác nhau). Chỉ SMS hoạt động
/// thật (xem docs/DECISIONS.md Đợt 35/37) — Zalo/Both khoá "Coming soon".
/// Trả về `true` nếu người dùng xác nhận gửi, `false`/`null` nếu Cancel.
Future<bool?> showBatchSendChannelSheet(BuildContext context,
    {required int count}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _BatchSendChannelSheet(count: count),
  );
}

class _BatchSendChannelSheet extends StatelessWidget {
  final int count;
  const _BatchSendChannelSheet({required this.count});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
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
              AppStrings.t(
                  'bills.batchSendChannelSubtitle', {'count': '$count'}),
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ChannelOption(
              icon: Symbols.sms_rounded,
              title: AppStrings.t('bills.channelSms'),
              subtitle: AppStrings.t('bills.channelSmsHint'),
              selected: true,
              enabled: true,
            ),
            const SizedBox(height: 8),
            ChannelOption(
              icon: Symbols.chat_rounded,
              title: AppStrings.t('bills.channelZalo'),
              subtitle: AppStrings.t('bills.channelComingSoon'),
              selected: false,
              enabled: false,
            ),
            const SizedBox(height: 8),
            ChannelOption(
              icon: Symbols.done_all_rounded,
              title: AppStrings.t('bills.channelBoth'),
              subtitle: AppStrings.t('bills.channelComingSoon'),
              selected: false,
              enabled: false,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: AppStrings.t('common.cancel'),
                    style: AppButtonStyle.ghost,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: AppStrings.t('bills.sendNow'),
                    style: AppButtonStyle.accent,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

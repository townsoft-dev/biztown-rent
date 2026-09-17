import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/theme.dart';

/// "option SMS/Zalo/Both" (B-05 Send Invoice, node `220:4673`/`220:4679`/
/// `220:4685`, Figma) — dùng chung cho B-05 (gửi đơn lẻ) và sheet chọn kênh
/// hàng loạt ở B-03.
class ChannelOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;

  /// Chạm để chọn kênh. `null` = chỉ hiển thị, không chọn được (VD Zalo chưa
  /// mở). Trước 17/09/2026 widget này thuần hiển thị vì B-05 chỉ có đúng 1 kênh
  /// dùng được; nay có 2 kênh thật (SMS/Email) nên phải bấm chọn được.
  final VoidCallback? onTap;

  const ChannelOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadii.checkRow),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Symbols.radio_button_checked_rounded
                    : Symbols.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? AppColors.primary : AppColors.neutral200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

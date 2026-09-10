import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import 'app_button.dart';

/// "Dialog" (173:109 trên Figma) — dialog xác nhận, giữa màn trên scrim navy
/// 45%. Đổi nút phải sang Danger cho xác nhận phá huỷ (xoá, đăng xuất...).
/// Luôn hiện qua `ConfirmDialog.show(...)` — không tự `showDialog` thủ công
/// từng màn, và không bao giờ xoá/phá huỷ trực tiếp khi bấm nút gốc mà chưa
/// qua xác nhận này.
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String description;
  final String cancelLabel;
  final String confirmLabel;
  final AppButtonStyle confirmStyle;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.description,
    this.cancelLabel = 'Cancel',
    required this.confirmLabel,
    this.confirmStyle = AppButtonStyle.danger,
  });

  /// Trả về `true` nếu người dùng bấm nút xác nhận, `false` nếu Cancel/đóng ra ngoài.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String description,
    String cancelLabel = 'Cancel',
    required String confirmLabel,
    AppButtonStyle confirmStyle = AppButtonStyle.danger,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.primary.withValues(alpha: 0.45),
      builder: (context) => ConfirmDialog(
        title: title,
        description: description,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        confirmStyle: confirmStyle,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Container(
        width: 303,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgDefault,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF14192E).withValues(alpha: 0.15),
                offset: const Offset(0, 1),
                blurRadius: 1.5),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 22 / 16,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text(description,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 18 / 13,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                      label: cancelLabel,
                      style: AppButtonStyle.ghost,
                      onPressed: () => Navigator.of(context).pop(false)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                      label: confirmLabel,
                      style: confirmStyle,
                      onPressed: () => Navigator.of(context).pop(true)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

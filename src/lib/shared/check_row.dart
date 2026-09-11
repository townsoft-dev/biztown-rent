import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "check row" (Figma, node 220:5117 nhóm "House access" ở P-06) — dòng
/// checkbox dạng thẻ bo góc, khác hẳn `Checkbox` Material mặc định. Checked =
/// viền navy 1.5px + icon `check_box` navy; unchecked = viền hairline 1px +
/// icon `check_box_outline_blank` neutral200. `disabled` (không có sẵn trên
/// Figma — mở rộng cho luật "1 Manager active/nhà" ở P-06) = nền xám mờ,
/// không bấm được, `subtitle` đổi sang lý do bị khoá (VD "Managed by Lan").
class CheckRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool checked;
  final bool disabled;
  final VoidCallback onTap;

  const CheckRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.checked,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadii.checkRow),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: disabled ? AppColors.bgMuted : AppColors.bgDefault,
          border: Border.all(
            color: disabled
                ? AppColors.borderSubtle
                : (checked ? AppColors.primary : AppColors.borderSubtle),
            width: !disabled && checked ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadii.checkRow),
        ),
        child: Row(
          children: [
            Icon(
              checked
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 20,
              color: disabled
                  ? AppColors.neutral200
                  : (checked ? AppColors.primary : AppColors.neutral200),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 18 / 13,
                          color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 17 / 12,
                          color: AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

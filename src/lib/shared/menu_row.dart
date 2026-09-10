import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import 'status_pill.dart';

/// "Menu row" (171:55 trên Figma) — dòng menu ở P-01 Profile & Settings:
/// icon + nhãn [+ badge pill số liệu] + chevron. `danger` dùng cho "Log out".
enum MenuRowType { normal, danger }

class MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badgeText;
  final MenuRowType type;
  final VoidCallback? onTap;
  final Widget? trailingWidget;

  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.badgeText,
    this.type = MenuRowType.normal,
    this.onTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDanger = type == MenuRowType.danger;
    final fg = isDanger ? AppColors.error : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.bgDefault,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 17 / 13.5,
                      color: fg)),
            ),
            if (badgeText != null) ...[
              StatusPill(text: badgeText!, style: StatusBadgeStyle.active),
              const SizedBox(width: 4),
            ],
            if (trailingWidget != null)
              trailingWidget!
            else
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.neutral200),
          ],
        ),
      ),
    );
  }
}

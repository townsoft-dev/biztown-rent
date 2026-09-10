import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Button" (164:18 trên Figma) — Primary = hành động chính (navy) · Ghost =
/// hành động phụ (viền navy) · Accent = CTA khẩn/nổi bật (cam, VD "Save
/// readings") · Danger = phá huỷ (VD "End contract", "Log out", "Delete").
/// Md = 44h (thường full-width), Sm = 36h (CTA nằm trong 1 dòng).
enum AppButtonStyle { primary, ghost, accent, danger }

enum AppButtonSize { md, sm }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final AppButtonSize size;

  const AppButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.style = AppButtonStyle.primary,
      this.size = AppButtonSize.md});

  @override
  Widget build(BuildContext context) {
    final isGhost = style == AppButtonStyle.ghost;
    final bg = switch (style) {
      AppButtonStyle.primary => AppColors.primary,
      AppButtonStyle.ghost => AppColors.borderSubtle,
      AppButtonStyle.accent => AppColors.accentOrange,
      AppButtonStyle.danger => AppColors.error,
    };
    final fg = isGhost ? AppColors.textPrimary : Colors.white;
    final height = size == AppButtonSize.md ? 44.0 : 36.0;
    final fontSize = size == AppButtonSize.md ? 14.0 : 12.0;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
        side: isGhost
            ? const BorderSide(color: AppColors.primary)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Container(
          height: height,
          constraints: const BoxConstraints(minWidth: 88),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: fontSize, fontWeight: FontWeight.w700, color: fg)),
        ),
      ),
    );
  }
}

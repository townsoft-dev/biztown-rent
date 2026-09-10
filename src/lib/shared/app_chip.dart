import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Chip" (167:41 trên Figma) — dùng cho hàng filter cuộn ngang (H-03, đếm số
/// trong label VD "Empty (6)") lẫn chip chọn nhiều (amenities ở H-05). Cùng 1
/// component, chỉ khác `selected`.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const AppChip(
      {super.key, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.bgDefault,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.neutral200),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 14 / 11,
              color: selected ? Colors.white : AppColors.textSecondary),
        ),
      ),
    );
  }
}

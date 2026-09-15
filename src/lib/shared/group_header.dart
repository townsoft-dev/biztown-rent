import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/theme.dart';

/// "Group header" (167:57 trên Figma) — nhóm hợp đồng/phòng theo Nhà, dùng ở
/// B-01 và H-03.
class GroupHeader extends StatelessWidget {
  final String label;
  final String counterLabel;

  const GroupHeader(
      {super.key, required this.label, required this.counterLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Symbols.home_work_rounded,
            color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 17 / 12.5,
                color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(AppRadii.pill)),
          child: Text(counterLabel,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 14 / 11,
                  color: AppColors.textTertiary)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Section label" (167:55 trên Figma) — nhãn overline chữ hoa phía trên 1
/// nhóm list (VD "YOUR HOUSES"). Component tự lo margin trên/dưới theo spec
/// (24px trên/8px dưới) — nơi dùng chỉ cần đặt trực tiếp trong Column, không
/// cần bọc thêm Padding/SizedBox nữa.
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 16 / 12,
            letterSpacing: 0.6,
            color: AppColors.textTertiary),
      ),
    );
  }
}

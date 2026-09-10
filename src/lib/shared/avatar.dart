import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

export '../core/text_format.dart' show initialsFromName;

/// "Avatar" (163:10 trên Figma) — avatar chữ cái đầu, vòng tròn navy. Dùng ở
/// P-01/P-02 (56px); P-05 dùng thẳng `ListCard(thumbShape: round)` (52px, đã
/// có initials + màu riêng cho từng thẻ).
class Avatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color color;

  const Avatar({
    super.key,
    required this.initials,
    this.size = 56,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(initials,
          style: GoogleFonts.inter(
              fontSize: size * 0.29,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }
}

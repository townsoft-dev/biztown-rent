import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Status badge" (163:26 trên Figma) — pill bo tròn, màu theo tone (xem
/// [StatusBadgeStyle]). Dùng cho badge trạng thái (Occupied/Overdue...) lẫn
/// badge số liệu dạng pill (VD "18/24" phòng ở H-01, "Unread" ở S-03).
class StatusPill extends StatelessWidget {
  final String text;
  final StatusBadgeStyle style;

  const StatusPill({super.key, required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 14 / 11,
              color: style.foreground)),
    );
  }
}

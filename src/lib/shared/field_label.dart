import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Field label" — nhãn tĩnh phía trên input box (165:2 trên Figma).
/// 11px medium, màu text-tertiary, cách box bên dưới 4px.
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, height: 14 / 11, color: AppColors.secondaryLight, fontWeight: FontWeight.w500)),
    );
  }
}

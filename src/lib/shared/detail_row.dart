import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Detail row" (168:58 trên Figma) — dòng key–value trong 1 `DetailBlock`.
/// `showDivider = false` cho dòng cuối cùng (bỏ viền gạch dưới).
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const DetailRow(
      {super.key,
      required this.label,
      required this.value,
      this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 18 / 13,
                  color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung thẻ trắng bo góc chứa nhiều `DetailRow` liên tiếp (168:58's parent
/// "detail block" trên Figma) — dùng ở H-03/H-04/H-06 thay vì tự bọc
/// Container lặp lại mỗi màn.
class DetailBlock extends StatelessWidget {
  final List<Widget> children;

  const DetailBlock({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

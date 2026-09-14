import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import 'package:material_symbols_icons/symbols.dart';

/// "search" (220:3199 trên Figma, T-01/T-02) — ô tìm kiếm dùng chung, nền
/// trắng + viền, icon kính lúp bên trái. Khác `AppTextField` (không có nhãn
/// phía trên, luôn có icon search cố định).
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SearchField(
      {super.key,
      required this.controller,
      required this.hintText,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(AppRadii.searchBarAndChipFilter),
      ),
      child: Row(
        children: [
          const Icon(Symbols.search_rounded,
              color: AppColors.textTertiary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

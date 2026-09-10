import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Banner" (173:101 trên Figma) — cảnh báo/ghi chú inline. Hiện chỉ có tone
/// Info (tone Preview dành riêng cho T-10 Invoice Schedule Preview sau này).
class AppBanner extends StatelessWidget {
  final String message;

  const AppBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: BorderRadius.circular(AppRadii.statCard)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 13, height: 18 / 13, color: AppColors.info))),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Banner" (173:101 trên Figma) — cảnh báo/ghi chú inline. `tone: info`
/// (mặc định, xanh — VD ghi chú trung tính ở H-02) hoặc `tone: warning` (cam
/// nhạt — VD "1 house has no payout account yet" ở P-03). Tone `Preview`
/// dành riêng cho T-10 Invoice Schedule Preview sau này, chưa cần.
enum AppBannerTone { info, warning }

class AppBanner extends StatelessWidget {
  final String message;
  final AppBannerTone tone;

  const AppBanner(
      {super.key, required this.message, this.tone = AppBannerTone.info});

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      AppBannerTone.info => AppColors.info,
      AppBannerTone.warning => AppColors.accentOrange,
    };
    final background = switch (tone) {
      AppBannerTone.info => AppColors.infoBg,
      AppBannerTone.warning => AppColors.warningBg,
    };
    final icon = switch (tone) {
      AppBannerTone.info => Icons.info_outline_rounded,
      AppBannerTone.warning => Icons.warning_amber_rounded,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.statCard)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 13, height: 18 / 13, color: color))),
        ],
      ),
    );
  }
}

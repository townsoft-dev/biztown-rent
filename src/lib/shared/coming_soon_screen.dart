import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// Placeholder dùng chung cho các tab chưa code UI thật (Tenant & Contract,
/// Bills, Profile) — tránh 3 file gần giống nhau; xoá dần từng cái khi tab đó
/// có màn thật (T-0x/B-0x/P-0x).
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? footer;

  const ComingSoonScreen(
      {super.key, required this.title, required this.icon, this.footer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: AppColors.secondaryLight),
                const SizedBox(height: 12),
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Coming soon',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary)),
                if (footer != null) ...[const SizedBox(height: 24), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Mini profile" (168:52 trên Figma) — dải tóm tắt Tenant (avatar chữ cái +
/// tên + dòng phụ). Dùng ở H-04 ("Current contract") và T-05 Contract Detail
/// (tap → T-03) sau này.
class MiniProfileCard extends StatelessWidget {
  final String initials;
  final String name;
  final String subtitle;
  final VoidCallback? onTap;

  const MiniProfileCard(
      {super.key,
      required this.initials,
      required this.name,
      required this.subtitle,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.bgDefault,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: Text(initials,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 18 / 13,
                          color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 11.5,
                          height: 17 / 11.5,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

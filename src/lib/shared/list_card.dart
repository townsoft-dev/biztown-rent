import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "List card" (168:48 trên Figma) — dòng list chính, rộng 343. Dùng cho Nhà
/// (H-01), Phòng (H-03), Hợp đồng (T-02), chỉ số (H-06), thông báo (S-03)...
/// `thumbShape: round` dành riêng cho Tenant (initials), còn lại dùng `square`
/// (icon bên trong). Đây là component dùng chung — KHÔNG copy lại code này
/// riêng cho từng màn, luôn import và dùng lại widget này.
enum ListCardThumbShape { square, round }

class ListCard extends StatelessWidget {
  final Color thumbColor;
  final IconData? icon;
  final String? initials;
  final ListCardThumbShape thumbShape;
  final String title;
  final Widget? trailing;
  final String body;
  final String? meta;
  final VoidCallback? onTap;

  const ListCard({
    super.key,
    required this.thumbColor,
    this.icon,
    this.initials,
    this.thumbShape = ListCardThumbShape.square,
    required this.title,
    this.trailing,
    required this.body,
    this.meta,
    this.onTap,
  }) : assert(icon != null || initials != null,
            'ListCard cần icon (thumbShape.square) hoặc initials (thumbShape.round)');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgDefault,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF14192E).withValues(alpha: 0.06),
                offset: const Offset(0, 1),
                blurRadius: 1)
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: thumbColor,
                shape: thumbShape == ListCardThumbShape.round
                    ? BoxShape.circle
                    : BoxShape.rectangle,
                borderRadius: thumbShape == ListCardThumbShape.square
                    ? BorderRadius.circular(AppRadii.thumbIcon)
                    : null,
              ),
              child: thumbShape == ListCardThumbShape.round
                  ? Text(initials!,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))
                  : Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 20 / 14,
                                color: AppColors.textPrimary)),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(body,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 18 / 13,
                          color: AppColors.textSecondary)),
                  if (meta != null) ...[
                    const SizedBox(height: 2),
                    Text(meta!,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 17 / 12,
                            color: AppColors.textTertiary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

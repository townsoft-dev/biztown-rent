import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Top bar" — component dùng chung (166:34 trên Figma), 3 variant: Title,
/// Title+Action, Home (greeting + tên + dòng tổng quan + chuông — dùng
/// `TopBar.home(...)`). 375-wide navy header: back (tròn 26px, nền trắng 14%)
/// + tiêu đề 20 bold trắng, kèm subtitle tuỳ chọn (12px, #C9CEE0) và 1 action
/// tròn bên phải (30px, nền trắng 12%).
class TopBar extends StatelessWidget {
  final String? greeting;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double opacity;

  const TopBar(
      {super.key,
      required this.title,
      this.subtitle,
      this.onBack,
      this.trailing,
      this.opacity = 1})
      : greeting = null;

  /// Variant "Home": dòng chào (nhỏ, mờ) phía trên tên (thay cho back button),
  /// dòng tổng quan (subtitle) phía dưới. VD: H-01 "Hello, / Tên / 3 houses...".
  const TopBar.home(
      {super.key,
      required this.greeting,
      required String name,
      required String overview,
      this.trailing,
      this.opacity = 1})
      : title = name,
        subtitle = overview,
        onBack = null;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      // SafeArea(bottom: false) — dành chỗ cho status bar hệ thống phía trên
      // (giống lý do AppBottomNav dùng SafeArea(top: false) cho thanh điều
      // hướng dưới) — thiếu cái này khiến nút back/action bị status bar đè
      // lên, có lúc chặn luôn tap (phát hiện qua phản hồi thật trên máy).
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (greeting != null)
                Text(greeting!,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 17 / 12,
                        color: const Color(0xFFC9CEE0))),
              Row(
                children: [
                  if (onBack != null) ...[
                    _TopBarCircleButton(
                        icon: Icons.arrow_back_rounded,
                        size: 26,
                        iconSize: 16,
                        bgOpacity: 0.14,
                        onTap: onBack!),
                    const SizedBox(width: 8)
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 26 / 20,
                          color: Colors.white),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 17 / 12,
                        color: const Color(0xFFC9CEE0))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TopBarMoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const TopBarMoreButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _TopBarCircleButton(
        icon: Icons.more_vert_rounded,
        size: 30,
        iconSize: 18,
        bgOpacity: 0.12,
        onTap: onTap);
  }
}

class TopBarBellButton extends StatelessWidget {
  final VoidCallback onTap;
  const TopBarBellButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _TopBarCircleButton(
        icon: Icons.notifications_rounded,
        size: 30,
        iconSize: 18,
        bgOpacity: 0.12,
        onTap: onTap);
  }
}

class _TopBarCircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final double bgOpacity;
  final VoidCallback onTap;

  const _TopBarCircleButton(
      {required this.icon,
      required this.size,
      required this.iconSize,
      required this.bgOpacity,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: bgOpacity),
            shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

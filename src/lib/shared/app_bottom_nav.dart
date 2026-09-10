import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Bottom navigation" (166:103 trên Figma) — 4 tab cố định (Home/Tenant &
/// Contract/Bills/Profile), giống hệt nhau ở mọi role. Dùng bên trong
/// `AppShell` (core/router.dart), không tự đặt lẻ trong từng màn con.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav(
      {super.key, required this.currentIndex, required this.onTap});

  static const _tabs = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.group_rounded, label: 'Tenant'),
    (icon: Icons.receipt_long_rounded, label: 'Bills'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgDefault,
        border: Border(top: BorderSide(color: AppColors.borderNav)),
      ),
      // SafeArea(top: false) — dành chỗ cho thanh điều hướng hệ thống (nút 3
      // phím Android/gesture bar) bên dưới 14px của design (vốn tính cho tai
      // thỏ/home indicator iOS) — tránh 2 thanh đè lên nhau như trên Android 3-nút.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 14),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_tabs[i].icon,
                              size: 24,
                              color: i == currentIndex
                                  ? AppColors.primary
                                  : AppColors.textTertiary),
                          const SizedBox(height: 3),
                          Text(
                            _tabs[i].label,
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 13 / 10,
                                color: i == currentIndex
                                    ? AppColors.primary
                                    : AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

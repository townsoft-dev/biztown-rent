import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_strings.dart';
import '../core/locale_provider.dart';
import '../core/theme.dart';
import 'package:material_symbols_icons/symbols.dart';

/// "Bottom navigation" (166:103 trên Figma) — 4 tab cố định (Home/Tenant &
/// Contract/Bills/Profile), giống hệt nhau ở mọi role. Dùng bên trong
/// `AppShell` (core/router.dart), không tự đặt lẻ trong từng màn con.
class AppBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nhãn không còn là `static const` được nữa vì `AppStrings.t()` không
    // phải hằng biên dịch — tính lại mỗi lần build, rẻ (4 lần tra JSON trong
    // bộ nhớ) nên không cần tối ưu thêm.
    ref.watch(languageProvider);
    final tabs = [
      (icon: Symbols.home_rounded, label: AppStrings.t('bottomNav.home')),
      (icon: Symbols.group_rounded, label: AppStrings.t('bottomNav.tenant')),
      (
        icon: Symbols.receipt_long_rounded,
        label: AppStrings.t('bottomNav.bills')
      ),
      (icon: Symbols.person_rounded, label: AppStrings.t('bottomNav.profile')),
    ];
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
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tabs[i].icon,
                              size: 24,
                              color: i == currentIndex
                                  ? AppColors.primary
                                  : AppColors.textTertiary),
                          const SizedBox(height: 3),
                          Text(
                            tabs[i].label,
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

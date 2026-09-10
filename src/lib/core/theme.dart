import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens từ docs/DESIGN-SYSTEMS.md — không hardcode màu/spacing rải rác
/// trong widget, luôn tham chiếu qua đây để khi Design System đổi chỉ sửa 1 chỗ.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF23305E); // Navy
  static const secondary = Color(0xFF5A6B8A); // Slate
  static const secondaryLight = Color(0xFF868DA7);
  static const accentOrange = Color(0xFFEF9F27);
  static const accentCoral = Color(0xFFF0997B);
  static const neutral200 = Color(0xFFB9BDCC);

  static const success = Color(0xFF2E9E5B);
  static const successBg = Color(0xFFE4F5EA);
  static const warning = Color(0xFFEF9F27); // = accentOrange
  static const warningBg = Color(0xFFFDF1DE);
  static const error = Color(0xFFD9483C);
  static const errorBg = Color(0xFFFBE7E5);
  static const info = Color(0xFF3E6BD9);
  static const infoBg = Color(0xFFE8EEFD);

  static const bgDefault = Color(0xFFFFFFFF);
  static const bgSubtle = Color(0xFFF5F6F9);
  static const bgTrack = Color(0xFFE7E9F1); // nền track của Segmented control
  static const textTertiary =
      Color(0xFF868DA7); // = secondaryLight, dùng cho meta/caption phụ
  static const textPrimary = Color(0xFF23305E); // = primary
  static const textSecondary = Color(0xFF5A6B8A); // = secondary
  static const borderSubtle = Color(0xFFEEF0F5);
  static const borderNav = Color(0xFFECEEF3); // viền trên Bottom navigation

  static const coralBg = Color(0xFFFDEEE8); // UnderRepair badge bg
}

class AppRadii {
  AppRadii._();

  static const card = 14.0;
  static const statCard = 12.0;
  static const segmentedControl = 12.0;
  static const segmentedControlButton = 9.0;
  static const searchBarAndChipFilter = 12.0;
  static const pill = 100.0;
  static const button = 11.0;
  static const inputField = 9.0;
  static const fab = 16.0;
  static const periodChip = 9.0;
  static const thumbIcon = 11.0;
}

class AppSpacing {
  AppSpacing._();

  static const screenPadding =
      16.0; // 14px trong mockup, làm tròn theo lưới 8px cho Figma thật
  static const cardGap = 10.0;
}

ThemeData buildAppTheme() {
  final base =
      ThemeData(useMaterial3: true, fontFamily: GoogleFonts.inter().fontFamily);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bgSubtle,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.accentOrange,
      error: AppColors.error,
      surface: AppColors.bgDefault,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
          fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    textTheme: base.textTheme
        .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary)
        .copyWith(
          // titleLarge màu trắng có chủ đích — chỉ dùng trên nền navy (Topbar/Splash).
          // Đừng dùng titleLarge cho text trên nền sáng, dùng titleMedium/bodyMedium thay thế.
          titleLarge: GoogleFonts.inter(
              fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
          titleMedium: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          bodyMedium: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary),
          bodySmall: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary),
          labelLarge: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.05,
              color: AppColors.textPrimary),
        ),
    cardTheme: CardThemeData(
      color: AppColors.bgDefault,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgDefault,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      hintStyle:
          GoogleFonts.inter(fontSize: 14, color: AppColors.secondaryLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.inputField),
        borderSide: const BorderSide(color: AppColors.neutral200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.inputField),
        borderSide: const BorderSide(color: AppColors.accentOrange, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(88, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button)),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentOrange,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.fab)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgDefault,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.secondaryLight,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

/// Màu nền + chữ cho badge trạng thái — xem DESIGN-SYSTEMS.md mục 6.5.
class StatusBadgeStyle {
  final Color background;
  final Color foreground;
  const StatusBadgeStyle(this.background, this.foreground);

  static const empty =
      StatusBadgeStyle(AppColors.borderSubtle, AppColors.secondary);
  static const occupied =
      StatusBadgeStyle(AppColors.successBg, AppColors.success);
  static const underRepair =
      StatusBadgeStyle(AppColors.coralBg, AppColors.accentCoral);
  static const active =
      StatusBadgeStyle(AppColors.successBg, AppColors.success);
  static const expiringSoon =
      StatusBadgeStyle(AppColors.warningBg, AppColors.warning);
  static const ended =
      StatusBadgeStyle(AppColors.borderSubtle, AppColors.secondary);
  static const draft =
      StatusBadgeStyle(AppColors.borderSubtle, AppColors.secondary);
  static const sent = StatusBadgeStyle(AppColors.infoBg, AppColors.info);
  static const collected =
      StatusBadgeStyle(AppColors.successBg, AppColors.success);
  static const overdue = StatusBadgeStyle(AppColors.errorBg, AppColors.error);
}

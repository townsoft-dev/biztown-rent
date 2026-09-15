import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_strings.dart';
import '../core/theme.dart';

/// "Chip" bên trong ô SĐT (S-02 Sign up node `386:2292`, dùng lại y hệt ở S-04
/// Forgot password) — bấm gửi OTP, mờ xám khi đã gửi/đang tải.
class SendOtpChip extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const SendOtpChip({super.key, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.neutral200,
          borderRadius: BorderRadius.circular(AppRadii.inputField),
        ),
        child: loading
            ? const SizedBox(
                height: 11,
                width: 11,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(AppStrings.t('signup.sendOtp'),
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 14 / 11,
                    color: Colors.white)),
      ),
    );
  }
}

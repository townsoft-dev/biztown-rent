import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Input field" (165:60 trên Figma) — label 11px phía trên + ô nhập. Text
/// dùng theme `inputDecorationTheme` có sẵn (viền/focus đã đúng token).
/// Readonly = nền xám `bgMuted`, không viền. Select/Date thêm icon cuối ô.
enum AppTextFieldTrailingIcon { none, select, date }

class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final bool readOnly;
  final int maxLines;
  final AppTextFieldTrailingIcon trailing;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final Widget? suffixWidget;

  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hintText,
    this.readOnly = false,
    this.maxLines = 1,
    this.trailing = AppTextFieldTrailingIcon.none,
    this.onTap,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.onChanged,
    this.obscureText = false,
    this.validator,
    this.suffixWidget,
  });

  @override
  Widget build(BuildContext context) {
    final suffixIcon = suffixWidget ??
        switch (trailing) {
          AppTextFieldTrailingIcon.select => const Icon(
              Icons.expand_more_rounded,
              color: AppColors.textTertiary,
              size: 20),
          AppTextFieldTrailingIcon.date => const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.textTertiary,
              size: 18),
          AppTextFieldTrailingIcon.none => null,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 14 / 11,
                color: AppColors.textTertiary)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          readOnly: readOnly || onTap != null,
          onTap: onTap,
          maxLines: obscureText ? 1 : maxLines,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          validator: validator,
          style: GoogleFonts.inter(
              fontSize: 14,
              color:
                  readOnly ? AppColors.textSecondary : AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            errorMaxLines: 3,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: readOnly ? AppColors.bgMuted : AppColors.bgDefault,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.inputField),
              borderSide: readOnly
                  ? BorderSide.none
                  : const BorderSide(color: AppColors.neutral200, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

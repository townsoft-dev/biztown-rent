import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Input field" (165:60 trên Figma) — label 11px phía trên + ô nhập. Text
/// dùng theme `inputDecorationTheme` có sẵn (viền/focus đã đúng token).
///
/// 4 biến thể Figma, KHÔNG được trộn lẫn (đã xảy ra bug 2 lần — Status ở
/// H-05, Bank name ở P-03 — do gán nhầm `readOnly: true` cho field đáng lẽ
/// phải là "Select"):
/// - **Text** (mặc định): nền trắng, viền `neutral200`, chữ `textPrimary`.
/// - **Readonly** (`readOnly: true`, trailing != select): nền xám `bgMuted`,
///   KHÔNG viền, chữ `textSecondary` — dùng cho field tĩnh thật sự (Phone,
///   Created at, Join from, Previous reading...).
/// - **Select** (`trailing: select`): LUÔN nền trắng + viền (giống Text),
///   chữ `textTertiary`, kèm icon `expand_more` — dùng cho field bấm mở
///   picker (Bank name ở P-03) hoặc field chỉ hiện giá trị đã chọn sẵn,
///   không gõ tay được (Status ở H-05). Áp dụng bất kể `readOnly` truyền vào
///   thế nào — không để caller tự chọn nhầm giữa Select và Readonly nữa.
/// - **Textarea** (`textarea: true`, `maxLines > 1`): nền trắng + viền
///   (giống Text), nhưng chữ `textTertiary` (đúng theo Figma — Note ở H-05/
///   P-06 dùng tông chữ nhạt hơn cho ghi chú, khác hẳn field dữ liệu chính).
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
  final bool textarea;

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
    this.textarea = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelect = trailing == AppTextFieldTrailingIcon.select;
    // "Readonly" thật sự (nền xám, không viền) chỉ áp dụng khi KHÔNG phải
    // biến thể Select — Select luôn nền trắng có viền dù `readOnly` là gì.
    final isMuted = readOnly && !isSelect;
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
          readOnly: readOnly || onTap != null || isSelect,
          onTap: onTap,
          maxLines: obscureText ? 1 : maxLines,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          validator: validator,
          style: GoogleFonts.inter(
              fontSize: 14,
              color: isSelect || textarea
                  ? AppColors.textTertiary
                  : (isMuted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary)),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            errorMaxLines: 3,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isMuted ? AppColors.bgMuted : AppColors.bgDefault,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.inputField),
              borderSide: isMuted
                  ? BorderSide.none
                  : const BorderSide(color: AppColors.neutral200, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import 'package:material_symbols_icons/symbols.dart';

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

/// Ô có `obscureText: true` sẽ TỰ mọc nút ẩn/hiện mật khẩu ở cuối ô — dùng ở
/// P-04 Đổi mật khẩu. Các màn Auth dùng `PasswordField` riêng vì kiểu ô khác.
class AppTextField extends StatefulWidget {
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
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _hienMatKhau = false;

  @override
  Widget build(BuildContext context) {
    final isSelect = widget.trailing == AppTextFieldTrailingIcon.select;
    // "Readonly" thật sự (nền xám, không viền) chỉ áp dụng khi KHÔNG phải
    // biến thể Select — Select luôn nền trắng có viền dù `widget.readOnly` là gì.
    final isMuted = widget.readOnly && !isSelect;
    // Ô mật khẩu tự mọc nút ẩn/hiện, trừ khi nơi gọi đã tự truyền
    // `suffixWidget` riêng (không giành chỗ của họ).
    final nutAnHien = widget.obscureText && widget.suffixWidget == null
        ? IconButton(
            icon: Icon(
                _hienMatKhau
                    ? Symbols.visibility_rounded
                    : Symbols.visibility_off_rounded,
                size: 20,
                color: AppColors.textTertiary),
            onPressed: () => setState(() => _hienMatKhau = !_hienMatKhau),
            splashRadius: 20,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          )
        : null;

    final suffixIcon = nutAnHien ??
        widget.suffixWidget ??
        switch (widget.trailing) {
          AppTextFieldTrailingIcon.select => const Icon(
              Symbols.expand_more_rounded,
              color: AppColors.textTertiary,
              size: 20),
          AppTextFieldTrailingIcon.date => const Icon(
              Symbols.calendar_today_rounded,
              color: AppColors.textTertiary,
              size: 18),
          AppTextFieldTrailingIcon.none => null,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 14 / 11,
                color: AppColors.textTertiary)),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          readOnly: widget.readOnly || widget.onTap != null || isSelect,
          onTap: widget.onTap,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          obscureText: widget.obscureText && !_hienMatKhau,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          validator: widget.validator,
          style: GoogleFonts.inter(
              fontSize: 14,
              color: isSelect || widget.textarea
                  ? AppColors.textTertiary
                  : (isMuted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary)),
          decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: widget.errorText,
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

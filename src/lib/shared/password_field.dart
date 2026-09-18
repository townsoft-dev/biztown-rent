import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/theme.dart';

/// Ô nhập mật khẩu kèm nút **ẩn/hiện** — dùng chung cho S-01 Đăng nhập,
/// S-02 Đăng ký và S-04 Quên mật khẩu.
///
/// Gom về một widget vì trước 18/09/2026 mỗi màn tự dựng `TextFormField` với
/// `obscureText: true` cứng, không màn nào có nút xem lại mật khẩu vừa gõ —
/// dungtv yêu cầu bổ sung cho **tất cả** các ô mật khẩu. Để mỗi màn tự thêm
/// thì chắc chắn sẽ lệch nhau và sót chỗ.
///
/// Màn P-04 Đổi mật khẩu dùng `AppTextField` (kiểu ô khác, có nhãn nổi) nên
/// nút ẩn/hiện của màn đó nằm luôn trong `AppTextField`.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final InputDecoration? decoration;

  const PasswordField({
    super.key,
    required this.controller,
    this.onChanged,
    this.validator,
    this.decoration,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hien = false;

  @override
  Widget build(BuildContext context) {
    final nut = IconButton(
      // `visibility_off` = đang ẩn (bấm để hiện), `visibility` = đang hiện.
      icon: Icon(
          _hien ? Symbols.visibility_rounded : Symbols.visibility_off_rounded,
          size: 20,
          color: AppColors.textTertiary),
      onPressed: () => setState(() => _hien = !_hien),
      splashRadius: 20,
      // Giữ ô nhập cao đúng như các ô khác — nút mặc định của Material chiếm
      // 48px làm ô mật khẩu cao hơn ô số điện thoại ngay bên trên.
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
    );

    final base = widget.decoration ?? const InputDecoration();
    return TextFormField(
      controller: widget.controller,
      obscureText: !_hien,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      onChanged: widget.onChanged,
      validator: widget.validator,
      decoration: base.copyWith(suffixIcon: nut),
    );
  }
}

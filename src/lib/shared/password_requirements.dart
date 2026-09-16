import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/password_validation.dart';
import 'detail_row.dart';

/// Checklist 3 điều kiện mật khẩu, cập nhật sống theo từng ký tự người dùng gõ
/// (✓ khi đạt, — khi chưa). Tách khỏi P-04 để S-02 Đăng ký và S-04 Quên mật
/// khẩu dùng lại đúng một khối, thay vì mỗi màn tự dựng một kiểu.
///
/// Màn nào dùng widget này thì nhớ `onChanged: (_) => setState(() {})` ở ô
/// mật khẩu — checklist chỉ vẽ lại khi màn cha vẽ lại.
class PasswordRequirements extends StatelessWidget {
  final String password;

  const PasswordRequirements({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    String mark(bool ok) => ok ? '✓' : '—';
    return DetailBlock(children: [
      DetailRow(
          label: AppStrings.t('password.reqMinLength'),
          value: mark(passwordHasMinLength(password))),
      DetailRow(
          label: AppStrings.t('password.reqNumber'),
          value: mark(passwordHasNumber(password))),
      DetailRow(
          label: AppStrings.t('password.reqUppercase'),
          value: mark(passwordHasUppercase(password)),
          showDivider: false),
    ]);
  }
}

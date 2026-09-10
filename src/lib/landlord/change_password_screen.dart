import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/detail_row.dart';
import '../shared/top_bar.dart';

/// P-04 — Change Password (node 220:4985, Figma) — checklist dưới field "New
/// password" cập nhật sống theo từng ký tự gõ (BR không ghi rõ độ dài/luật
/// mật khẩu ở DATABASE.md/BUSINESS-RULES.md, dùng đúng 3 điều kiện hiện trên
/// Figma: ≥8 ký tự, ≥1 số, ≥1 chữ hoa).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  String? _errorText;

  bool get _hasMinLength => _newController.text.length >= 8;
  bool get _hasNumber => _newController.text.contains(RegExp(r'[0-9]'));
  bool get _hasUppercase => _newController.text.contains(RegExp(r'[A-Z]'));

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _errorText = null);
    if (_currentController.text.isEmpty) {
      setState(() => _errorText = 'Enter your current password.');
      return;
    }
    if (!_hasMinLength || !_hasNumber || !_hasUppercase) {
      setState(() =>
          _errorText = 'New password does not meet all requirements above.');
      return;
    }
    if (_newController.text != _confirmController.text) {
      setState(() => _errorText = 'Passwords do not match.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(userRepositoryProvider).changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );
      if (mounted) context.pop();
    } on AuthException {
      setState(() => _errorText = 'Current password is incorrect.');
    } catch (e) {
      setState(
          () => _errorText = 'Could not change password. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: Column(
        children: [
          TopBar(title: 'Change password', onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                AppTextField(
                  label: 'Current password *',
                  controller: _currentController,
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'New password *',
                  controller: _newController,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Confirm new password *',
                  controller: _confirmController,
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                DetailBlock(children: [
                  DetailRow(
                      label: 'At least 8 characters',
                      value: _hasMinLength ? '✓' : '—'),
                  DetailRow(
                      label: 'At least 1 number',
                      value: _hasNumber ? '✓' : '—'),
                  DetailRow(
                      label: 'At least 1 uppercase letter',
                      value: _hasUppercase ? '✓' : '—',
                      showDivider: false),
                ]),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorText!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        style: AppButtonStyle.ghost,
                        onPressed: _isSaving ? null : () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: AppButton(
                            label: 'Save',
                            onPressed: _isSaving ? null : _save)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

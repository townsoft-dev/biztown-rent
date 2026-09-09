import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/auth_repository.dart';

/// S-01 — Đăng nhập. Layout/copy khớp ảnh Figma thật (09/09/2026) — không suy
/// diễn từ text spec nữa, xem ảnh gửi kèm trong changelog/2026-09-09.md.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  late final TapGestureRecognizer _signUpTap;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _signUpTap = TapGestureRecognizer()..onTap = () => context.go('/signup');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _signUpTap.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await authRepository.signInWithPassword(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      // go_router redirect (xem core/router.dart) tự chuyển sang /home khi có session.
    } catch (e) {
      // TODO: rate-limit sau 5 lần sai (edge case trong SCREEN-SPEC.md) — chưa
      // implement, cần đếm số lần thử ở phía server/Edge Function.
      setState(() => _errorText = 'Sai số điện thoại hoặc mật khẩu');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                SvgPicture.asset('assets/logo/biztown-rent-manager-lockup.svg', width: 180),
                const SizedBox(height: 28),
                Text('Log in', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Welcome! Please sign in to continue.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 24),
                const _FieldLabel('Phone number'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập số điện thoại' : null,
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (v) => (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    // TODO: luồng "Quên mật khẩu" dùng lại OTP của SignupScreen — chưa nối.
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Log in'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign up',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          recognizer: _signUpTap,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
    );
  }
}

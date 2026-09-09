import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/auth_repository.dart';

/// S-01 — Đăng nhập. Xem docs/SCREEN-SPEC.md mục 2.1.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                SvgPicture.asset('assets/logo/biztown-rent-manager-lockup.svg', width: 200),
                const SizedBox(height: 16),
                Text('Welcome to BizTown', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                const Text(
                  'Manage your rentals or track your rent — all in one app',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number', hintText: '+84 9xx xxx xxx'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập số điện thoại' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Đăng nhập'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  // TODO: luồng "Quên mật khẩu" dùng lại OTP của SignupScreen — chưa nối.
                  onPressed: () {},
                  child: const Text('Quên mật khẩu?'),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text('Chưa có tài khoản? Đăng ký'),
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

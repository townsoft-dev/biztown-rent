import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../data/auth_repository.dart';
import 'field_label.dart';

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
      if (mounted) context.go('/home');
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
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset('assets/logo/biztown-rent-manager-lockup.svg', width: 200),
                const SizedBox(height: 40),
                Text('Log in', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, height: 34 / 28, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Text(
                  'Welcome! Please sign in to continue.',
                  style: GoogleFonts.inter(fontSize: 13, height: 18 / 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                const FieldLabel('Phone number'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập số điện thoại' : null,
                ),
                const SizedBox(height: 12),
                const FieldLabel('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  validator: (v) => (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    // TODO: luồng "Quên mật khẩu" dùng lại OTP của SignupScreen — chưa nối.
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text('Forgot password?', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.info)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Log in'),
                  ),
                ),
                const SizedBox(height: 5),
                Center(
                  child: GestureDetector(
                    onTap: () => context.push('/signup'),
                    child: Text(
                      "Don't have an account?  Sign up",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_strings.dart';
import '../core/theme.dart';
import '../data/auth_repository.dart';
import '../data/login_rate_limiter.dart';
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
    final phone = AuthRepository.normalizeVnPhone(_phoneController.text);

    final lockedUntil = await loginRateLimiter.checkLocked(phone);
    if (lockedUntil != null) {
      setState(() => _errorText = _lockedMessage(lockedUntil));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await authRepository.signInWithPassword(
          phone: phone, password: _passwordController.text);
      await loginRateLimiter.recordSuccess(phone);
      if (mounted) context.go('/home');
    } catch (e) {
      final justLockedUntil = await loginRateLimiter.recordFailure(phone);
      setState(() => _errorText = justLockedUntil != null
          ? _lockedMessage(justLockedUntil)
          : AppStrings.t('login.invalidCredentials'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _lockedMessage(DateTime lockedUntil) {
    final minutesLeft = lockedUntil.difference(DateTime.now()).inMinutes + 1;
    return AppStrings.t('login.lockedMessage', {'minutes': '$minutesLeft'});
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
                SvgPicture.asset('assets/logo/biztown-rent-manager-lockup.svg',
                    width: 200),
                const SizedBox(height: 40),
                Text(AppStrings.t('login.title'),
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 34 / 28,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Text(
                  AppStrings.t('login.welcome'),
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 18 / 13,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                FieldLabel(AppStrings.t('login.phoneNumber')),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textPrimary),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.t('login.phoneRequired')
                      : null,
                ),
                const SizedBox(height: 12),
                FieldLabel(AppStrings.t('login.password')),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textPrimary),
                  validator: (v) => (v == null || v.isEmpty)
                      ? AppStrings.t('login.passwordRequired')
                      : null,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorText!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    // Dùng lại luồng OTP của SignupScreen (Verify phone → Set password) —
                    // verifyOTP tạo session hợp lệ cho SĐT đã tồn tại, setPassword đổi
                    // đúng mật khẩu của tài khoản đó. Không có màn Forgot Password riêng
                    // trong Figma — đây là cách tái dùng đã ghi trong TODO trước đó.
                    onPressed: () => context.push('/signup'),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text(AppStrings.t('login.forgotPassword'),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(AppStrings.t('login.submit')),
                  ),
                ),
                const SizedBox(height: 5),
                Center(
                  child: GestureDetector(
                    onTap: () => context.push('/signup'),
                    child: Text(
                      AppStrings.t('login.noAccount'),
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
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

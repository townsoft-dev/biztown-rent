import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_strings.dart';
import '../core/theme.dart';
import '../core/phone_validation.dart';
import '../data/auth_repository.dart';
import '../data/login_rate_limiter.dart';
import '../data/push_repository.dart';
import 'field_label.dart';
import 'password_field.dart';

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

  /// "Ghi nhớ đăng nhập" — nhớ SỐ ĐIỆN THOẠI để lần sau khỏi gõ lại, giống
  /// cách các trang web nhớ tên đăng nhập.
  ///
  /// CỐ Ý KHÔNG lưu mật khẩu: lưu mật khẩu dạng thường xuống máy là rủi ro
  /// thật (ai mượn máy, hoặc bản sao lưu bị lộ, là đọc được). Phiên đăng nhập
  /// vốn đã được Supabase giữ sẵn nên người dùng bình thường không phải gõ
  /// lại gì; ô này chỉ có tác dụng sau khi họ chủ động Đăng xuất.
  bool _rememberMe = true;

  static const _prefKeyRemember = 'login_remember_me';
  static const _prefKeyPhone = 'login_remembered_phone';

  @override
  void initState() {
    super.initState();
    _khoiPhucSoDaNho();
  }

  Future<void> _khoiPhucSoDaNho() async {
    final prefs = await SharedPreferences.getInstance();
    final nho = prefs.getBool(_prefKeyRemember) ?? true;
    final soDt = prefs.getString(_prefKeyPhone) ?? '';
    if (!mounted) return;
    setState(() {
      _rememberMe = nho;
      if (nho && soDt.isNotEmpty) _phoneController.text = soDt;
    });
  }

  Future<void> _luuSoDaNho(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyRemember, _rememberMe);
    if (_rememberMe) {
      await prefs.setString(_prefKeyPhone, phone);
    } else {
      await prefs.remove(_prefKeyPhone);
    }
  }

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
      await _luuSoDaNho(_phoneController.text.trim());
      unawaited(pushRepository.registerDeviceToken());
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
                // Logo thương hiệu BizTown (icon + wordmark) — bộ asset mới
                // 18/09/2026, đổi đồng loạt theo docs/DESIGN-SYSTEMS.md mục
                // 1.1. Trước đây dùng lockup gộp cả "RENT MANAGER"; ở đây bỏ
                // phần đó vì màn đã có tiêu đề "Login" riêng ngay dưới, tránh
                // lặp tên sản phẩm 2 lần.
                // Khối "brand" theo đúng Figma S-01 (node `220:2176`): icon
                // 60×60 ĐỨNG CẠNH wordmark "RENT MANAGER" bản chữ đậm màu
                // navy, không phải icon đứng một mình (dungtv báo 18/09/2026).
                // Wordmark ở đây dùng bản NAVY vì nền màn đăng nhập sáng —
                // khác Splash dùng bản trắng trên nền navy.
                Row(
                  children: [
                    Image.asset(
                        'assets/logo/biztown-rent-icon-wordmark-alt.png',
                        width: 60,
                        height: 60),
                    // KHÔNG chèn khoảng hở: Figma đặt khung wordmark ngay sát
                    // icon (x=60, rộng 235) vì bản thân file PNG đã có sẵn lề
                    // trống hai bên.
                    //
                    // Đặt theo BỀ NGANG 235 chứ không theo chiều cao: file
                    // 1784×431 nhưng phần chữ thật chỉ 1448×96, phần còn lại
                    // là lề. Đặt `height` làm cả khung co lại nên chữ bé hơn
                    // hẳn thiết kế (đã thấy khi chụp màn lần đầu).
                    Image.asset(
                        'assets/logo/rentmanager-wordmark-bold-navy.png',
                        width: 235),
                  ],
                ),
                // 16px spacer + 12px trước tiêu đề, theo Figma (brand kết thúc
                // y=92, "Log in" bắt đầu y=132 tính từ đầu `content`).
                const SizedBox(height: 28),
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
                  inputFormatters: const [VnPhoneInputFormatter()],
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textPrimary),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.t('login.phoneRequired')
                      : null,
                ),
                const SizedBox(height: 12),
                FieldLabel(AppStrings.t('login.password')),
                PasswordField(
                  controller: _passwordController,
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
                // Figma S-01 node `664:2646`: ô tick 20×20 + chữ cách 7px,
                // nằm ngay dưới ô mật khẩu và TRÊN dòng "Quên mật khẩu?".
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(
                              color: AppColors.neutral200, width: 1.5),
                          activeColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(AppStrings.t('login.rememberMe'),
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    // S-04 — Forgot password (màn riêng trên Figma, node `386:2282` —
                    // phát hiện 2026-09-14 khi test thật là trước đó bị nhầm trỏ sang
                    // `/signup`, hỏi cả Full name/nút "Create account" sai hoàn toàn).
                    onPressed: () => context.push('/forgot-password'),
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_strings.dart';
import '../core/theme.dart';
import '../core/password_validation.dart';
import '../core/phone_validation.dart';
import '../data/auth_repository.dart';
import 'field_label.dart';
import 'send_otp_chip.dart';
import 'signup_stepper.dart';
import 'top_bar.dart';

/// S-04 — Forgot password (node `386:2282`/`388:2375`/`388:2386`, Figma) — 3
/// bước RIÊNG khỏi Sign up (Step 1: SĐT + OTP chung 1 trang; Step 2: đặt lại
/// mật khẩu, KHÔNG có field Full name; Step 3: bottom sheet "Well Done!").
/// Trước 2026-09-14 màn "Forgot password?" ở Login tái dùng thẳng `/signup`
/// (hỏi cả Full name, nút "Create account") vì lúc code màn đó Figma CHƯA có
/// frame S-04 riêng — phát hiện bug UI khi test thật, tách hẳn màn riêng theo
/// đúng Figma hiện tại. Tái dùng `authRepository.sendOtp/verifyOtp/setPassword`
/// (đã có comment sẵn ghi rõ dùng chung cho cả 2 luồng) — KHÔNG gọi
/// `ensureUserProfile()` (sẽ ghi đè nhầm `full_name`/`phone` của tài khoản đã
/// có sẵn, chỉ hợp lý cho tài khoản MỚI ở Sign up).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _FpPage { verifyPhone, resetPassword }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _FpPage _page = _FpPage.verifyPhone;
  final _phoneController = TextEditingController();
  // Theo dõi focus để KHUNG NGOÀI đổi sang viền cam, thay vì để TextField bên
  // trong tự vẽ viền cam rồi bị cắt.
  final _phoneFocus = FocusNode();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _otp = '';
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isLoading = false;
  bool _passwordReset = false;
  String? _errorText;
  String? _confirmPasswordError;

  Timer? _resendTimer;
  int _resendSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    // Vẽ lại khung khi đổi focus để viền đổi màu (cam khi đang nhập).
    _phoneFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phoneFocus.removeListener(_onFocusChanged);
    _phoneController.dispose();
    _phoneFocus.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _mmss =>
      '${(_resendSecondsLeft ~/ 60).toString().padLeft(1, '0')}:${(_resendSecondsLeft % 60).toString().padLeft(2, '0')}';

  void _startResendCountdown() {
    _resendSecondsLeft = 120;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSecondsLeft <= 1) {
        timer.cancel();
        setState(() => _resendSecondsLeft = 0);
      } else {
        setState(() => _resendSecondsLeft -= 1);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _errorText = AppStrings.t('signup.phoneRequired'));
      return;
    }
    // Chặn số sai định dạng trước khi gọi Supabase: gửi OTP tới số rác vẫn
    // tốn tiền SMS mà người dùng chỉ nhận lại thông báo lỗi chung chung.
    if (!isValidVnPhone(_phoneController.text)) {
      setState(() => _errorText = AppStrings.t('common.phoneInvalid'));
      return;
    }
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await authRepository.sendOtp(_phoneController.text.trim());
      setState(() => _otpSent = true);
      _startResendCountdown();
    } catch (e) {
      setState(() => _errorText = AppStrings.t('signup.otpSendFailed'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await authRepository.verifyOtp(
          phone: _phoneController.text.trim(), token: _otp);
      setState(() => _otpVerified = true);
    } on AuthApiException catch (e) {
      setState(() => _errorText = e.code == 'otp_expired'
          ? AppStrings.t('signup.otpExpired')
          : AppStrings.t('signup.otpIncorrect'));
    } catch (e) {
      setState(() => _errorText = AppStrings.t('signup.otpIncorrectOrExpired'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onConfirmPasswordChanged(String value) {
    setState(() {
      _confirmPasswordError =
          value.isNotEmpty && value != _passwordController.text
              ? AppStrings.t('signup.passwordsDoNotMatch')
              : null;
    });
  }

  Future<void> _savePassword() async {
    // Dùng chung đúng một luật với P-04 Đổi mật khẩu (xem
    // core/password_validation.dart) — trước 16/09/2026 màn này chỉ bắt
    // `length < 6` nên đăng ký được bằng mật khẩu mà chính P-04 lại từ chối.
    //
    // Dùng `requirementsSummary` (câu tự nêu đủ 3 điều kiện) chứ KHÔNG dùng
    // `requirementsNotMet` ("...các điều kiện ở trên") như P-04: màn này không
    // có khối checklist nên chẳng có "ở trên" nào để người dùng nhìn. Figma
    // (`347:2941` Sign up, `388:2375` Quên mật khẩu) không vẽ checklist ở đây,
    // và rule dự án là bám sát Figma nên không tự thêm vào.
    if (!isValidPassword(_passwordController.text)) {
      setState(() => _errorText = AppStrings.t('password.requirementsSummary'));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() =>
          _confirmPasswordError = AppStrings.t('signup.passwordsDoNotMatch'));
      return;
    }
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await authRepository.setPassword(_passwordController.text);
      if (!mounted) return;
      setState(() => _passwordReset = true);
      await _showSuccessSheet();
    } catch (e) {
      setState(() => _errorText = AppStrings.t('forgotPassword.resetFailed'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.bgDefault,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _ForgotPasswordSuccessSheet(
        onGoToLogin: () async {
          Navigator.of(sheetContext).pop();
          // Đổi mật khẩu xong bắt đăng nhập lại từ đầu bằng mật khẩu mới
          // (đúng Figma "Go to login") — khác Sign up "Get started" đi thẳng
          // /home, vì verifyOTP ở luồng này đã tạo session TẠM cho tài khoản
          // CŨ, không phải phiên đăng nhập thật người dùng chủ động bắt đầu.
          await authRepository.signOut();
          // `context` ở đây là context của State (ForgotPasswordScreen), KHÔNG
          // phải context của bottom sheet đã pop ở trên — cố tình không đặt
          // tên trùng `context` để tránh nhầm 2 context như lint cảnh báo.
          if (mounted) context.go('/login');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onStep1 = _page == _FpPage.verifyPhone;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDefault,
        body: Column(
          children: [
            TopBar(
              title: AppStrings.t(onStep1
                  ? 'forgotPassword.topBarTitleStep1'
                  : 'forgotPassword.topBarTitleStep2'),
              opacity: _passwordReset ? 0.3 : 1,
              onBack: () => _handleBack(context),
            ),
            Expanded(
              child: Opacity(
                opacity: _passwordReset ? 0.3 : 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: onStep1
                      ? _buildVerifyPhonePage()
                      : _buildResetPasswordPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (_page == _FpPage.verifyPhone) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    } else {
      setState(() => _page = _FpPage.verifyPhone);
    }
  }

  Widget _buildVerifyPhonePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignupStepper(current: 1),
        const SizedBox(height: 12),
        Text(AppStrings.t('forgotPassword.step1Title'),
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 26 / 20,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        FieldLabel(AppStrings.t('signup.phoneNumber')),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            border: Border.all(
                color: _phoneFocus.hasFocus
                    ? AppColors.accentOrange
                    : AppColors.neutral200,
                width: 1.5),
            borderRadius: BorderRadius.circular(AppRadii.inputField),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  enabled: !_otpSent,
                  keyboardType: TextInputType.phone,
                  inputFormatters: const [VnPhoneInputFormatter()],
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    // Phải tắt TẤT CẢ biến thể viền, không chỉ `border`:
                    // `InputDecoration.collapsed` vẫn để lọt `focusedBorder`
                    // màu cam của theme, vẽ thêm một viền BÊN TRONG khung
                    // ngoài rồi bị padding cắt mất một phần — đúng lỗi dungtv
                    // chụp lại 16/09/2026. Viền của ô này do Container bên
                    // ngoài vẽ, đổi màu theo trạng thái focus.
                    isCollapsed: true,
                    hintText: '',
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SendOtpChip(
                  loading: _isLoading && !_otpSent,
                  onTap: _otpSent ? null : _sendOtp),
            ],
          ),
        ),
        if (_otpSent) ...[
          const SizedBox(height: 12),
          Text(
            AppStrings.t('signup.otpSentMessage',
                {'phone': _phoneController.text.trim(), 'countdown': _mmss}),
            style: GoogleFonts.inter(
                fontSize: 13, height: 18 / 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          PinCodeTextField(
            appContext: context,
            length: 6,
            enabled: !_otpVerified,
            onChanged: (value) => _otp = value,
            onCompleted: (_) => _verifyOtp(),
            keyboardType: TextInputType.number,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(AppRadii.inputField),
              fieldHeight: 52,
              fieldWidth: 46,
              activeColor: AppColors.accentOrange,
              selectedColor: AppColors.accentOrange,
              inactiveColor: AppColors.neutral200,
            ),
            textStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Center(
            child: _resendSecondsLeft > 0
                ? Text(
                    AppStrings.t(
                        'signup.resendCodeCountdown', {'countdown': _mmss}),
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.secondaryLight))
                : TextButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: Text(AppStrings.t('signup.resendCode'))),
          ),
        ],
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
              textAlign: TextAlign.center),
        ],
        const SizedBox(height: 60),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _otpVerified
                ? () => setState(() => _page = _FpPage.resetPassword)
                : null,
            child: Text(AppStrings.t('forgotPassword.nextResetPassword')),
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignupStepper(current: 2),
        const SizedBox(height: 12),
        Text(AppStrings.t('forgotPassword.step2Title').toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 26 / 20,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        FieldLabel(AppStrings.t('forgotPassword.newPassword')),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          onChanged: (_) =>
              _onConfirmPasswordChanged(_confirmPasswordController.text),
        ),
        const SizedBox(height: 12),
        FieldLabel(AppStrings.t('forgotPassword.confirmNewPassword')),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          onChanged: _onConfirmPasswordChanged,
          decoration: _confirmPasswordError == null
              ? null
              : InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.inputField),
                      borderSide:
                          const BorderSide(color: AppColors.error, width: 1.5)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.inputField),
                      borderSide:
                          const BorderSide(color: AppColors.error, width: 1.5)),
                ),
        ),
        if (_confirmPasswordError != null) ...[
          const SizedBox(height: 4),
          Text(_confirmPasswordError!,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.error)),
        ],
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!,
              style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _savePassword,
            child: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(AppStrings.t('forgotPassword.save')),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet thành công (S-04 — Forgot password - Step 3, node `388:2386`)
/// hiện sau khi đặt lại mật khẩu xong, đè lên trang Reset password (đang mờ
/// 30% phía sau) — dùng lại đúng asset success icon của Sign up (component
/// chung, không có bản riêng cho S-04 trên Figma).
class _ForgotPasswordSuccessSheet extends StatelessWidget {
  final VoidCallback onGoToLogin;
  const _ForgotPasswordSuccessSheet({required this.onGoToLogin});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(100))),
            const SizedBox(height: 30),
            SvgPicture.asset('assets/icons/signup_success.svg',
                width: 123, height: 123),
            const SizedBox(height: 30),
            Text(
              AppStrings.t('forgotPassword.successTitle'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 15),
            Text(
              AppStrings.t('forgotPassword.successBody'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 18 / 13,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: onGoToLogin,
                  child: Text(AppStrings.t('forgotPassword.goToLogin'))),
            ),
          ],
        ),
      ),
    );
  }
}

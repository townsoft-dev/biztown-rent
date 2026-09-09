import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../core/theme.dart';
import '../data/auth_repository.dart';
import 'field_label.dart';
import 'signup_stepper.dart';
import 'top_bar.dart';

/// S-02 — Sign Up. Trên Figma đây là 2 trang điều hướng riêng (Step 1: SĐT +
/// OTP chung 1 trang; Step 2: đặt mật khẩu) + 1 bottom sheet thành công khi
/// tạo tài khoản xong (node 220:2214, 347:2941, 347:3087 — lấy qua Figma MCP
/// 09/09/2026, không phải suy đoán từ ảnh chụp nữa).
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

enum _SignupPage { verifyPhone, setPassword }

class _SignupScreenState extends State<SignupScreen> {
  _SignupPage _page = _SignupPage.verifyPhone;
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _otp = '';
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isLoading = false;
  bool _accountCreated = false;
  String? _errorText;
  String? _confirmPasswordError;

  Timer? _resendTimer;
  int _resendSecondsLeft = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _mmss => '${(_resendSecondsLeft ~/ 60).toString().padLeft(1, '0')}:${(_resendSecondsLeft % 60).toString().padLeft(2, '0')}';

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
      setState(() => _errorText = 'Nhập số điện thoại');
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
      setState(() => _errorText = 'Không gửi được OTP, thử lại sau');
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
      await authRepository.verifyOtp(phone: _phoneController.text.trim(), token: _otp);
      setState(() => _otpVerified = true);
    } catch (e) {
      // TODO: phân biệt "sai OTP" và "hết hạn" để hiện đúng thông báo (SCREEN-SPEC.md edge case).
      setState(() => _errorText = 'Mã OTP không đúng hoặc đã hết hạn');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onConfirmPasswordChanged(String value) {
    setState(() {
      _confirmPasswordError = value.isNotEmpty && value != _passwordController.text ? 'Passwords do not match' : null;
    });
  }

  Future<void> _createAccount() async {
    if (_passwordController.text.length < 6) {
      setState(() => _errorText = 'Mật khẩu tối thiểu 6 ký tự');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await authRepository.setPassword(_passwordController.text);
      await authRepository.ensureUserProfile(
        phone: _phoneController.text.trim(),
        fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _accountCreated = true);
      await _showSuccessSheet();
      // go_router redirect tự chuyển sang /home khi có session (đã có từ lúc verifyOtp).
    } catch (e) {
      setState(() => _errorText = 'Không tạo được tài khoản, thử lại');
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _SignupSuccessSheet(
        onGetStarted: () {
          Navigator.of(context).pop();
          context.go('/home');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onStep1 = _page == _SignupPage.verifyPhone;
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
              title: 'Create account',
              opacity: _accountCreated ? 0.3 : 1,
              onBack: () => _handleBack(context),
            ),
            Expanded(
              child: Opacity(
                opacity: _accountCreated ? 0.3 : 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: onStep1 ? _buildVerifyPhonePage() : _buildSetPasswordPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (_page == _SignupPage.verifyPhone) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    } else {
      setState(() => _page = _SignupPage.verifyPhone);
    }
  }

  Widget _buildVerifyPhonePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignupStepper(current: 1),
        const SizedBox(height: 12),
        Text('Verify your phone', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, height: 26 / 20, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        const FieldLabel('Phone number'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            border: Border.all(color: AppColors.neutral200, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadii.inputField),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  enabled: !_otpSent,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration.collapsed(hintText: ''),
                ),
              ),
              const SizedBox(width: 8),
              _SendOtpChip(loading: _isLoading && !_otpSent, onTap: _otpSent ? null : _sendOtp),
            ],
          ),
        ),
        if (_otpSent) ...[
          const SizedBox(height: 12),
          Text(
            'We sent a 6-digit code to ${_phoneController.text.trim()}. The code expires in $_mmss.',
            style: GoogleFonts.inter(fontSize: 13, height: 18 / 13, color: AppColors.textSecondary),
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
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Center(
            child: _resendSecondsLeft > 0
                ? Text('Resend code  ·  $_mmss', style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondaryLight))
                : TextButton(onPressed: _isLoading ? null : _sendOtp, child: const Text('Resend code')),
          ),
        ],
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 60),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _otpVerified ? () => setState(() => _page = _SignupPage.setPassword) : null,
            child: const Text('Next - Set up your password'),
          ),
        ),
      ],
    );
  }

  Widget _buildSetPasswordPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignupStepper(current: 2),
        const SizedBox(height: 12),
        Text('SET PASSWORD', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, height: 26 / 20, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        const FieldLabel('Full name'),
        TextFormField(controller: _fullNameController, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        const FieldLabel('Password'),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          onChanged: (_) => _onConfirmPasswordChanged(_confirmPasswordController.text),
        ),
        const SizedBox(height: 12),
        const FieldLabel('Confirm password'),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          onChanged: _onConfirmPasswordChanged,
          decoration: _confirmPasswordError == null
              ? null
              : InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.inputField), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.inputField), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
                ),
        ),
        if (_confirmPasswordError != null) ...[
          const SizedBox(height: 4),
          Text(_confirmPasswordError!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.error)),
        ],
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createAccount,
            child: _isLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create account'),
          ),
        ),
      ],
    );
  }
}

class _SendOtpChip extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _SendOtpChip({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.neutral200,
          borderRadius: BorderRadius.circular(AppRadii.inputField),
        ),
        child: loading
            ? const SizedBox(height: 11, width: 11, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text('Send OTP', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, height: 14 / 11, color: Colors.white)),
      ),
    );
  }
}

/// Bottom sheet thành công (S-02 — Sign Up - Step 3, node 347:3087) hiện sau
/// khi tạo tài khoản xong, đè lên trang Set Password (đang mờ 30% phía sau).
class _SignupSuccessSheet extends StatelessWidget {
  final VoidCallback onGetStarted;
  const _SignupSuccessSheet({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(100))),
            const SizedBox(height: 30),
            SvgPicture.asset('assets/icons/signup_success.svg', width: 123, height: 123),
            const SizedBox(height: 30),
            Text(
              'Congratulation! Account created.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, height: 20 / 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 15),
            Text(
              'Your account is ready. From here you can keep track of your properties, tenants, and bills — all in one place. Take a look around.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, height: 18 / 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: onGetStarted, child: const Text('Get started')),
            ),
          ],
        ),
      ),
    );
  }
}

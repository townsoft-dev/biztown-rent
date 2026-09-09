import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../core/theme.dart';
import '../data/auth_repository.dart';

enum _SignupStep { enterPhone, verifyAndSetPassword }

/// S-02 — Đăng ký. Layout/copy khớp ảnh Figma thật (09/09/2026): AppBar "Create
/// account / Main Manager", progress dots, phần "Verify your phone" (OTP) và
/// "STEP 3 — SET PASSWORD" cùng nằm trên 1 màn liên tục (không chuyển route).
///
/// ⚠️ Chưa chắc 100% cơ chế hiện/ẩn 2 phần này khớp Figma thật (ảnh tĩnh không
/// thấy được animation/trạng thái trung gian) — hiện làm: nhập đủ 6 số OTP thì
/// tự verify, verify xong mới hiện phần "Set password" bên dưới, KHÔNG ẩn phần
/// OTP đi (khớp ảnh: cả 2 phần cùng hiển thị). Cần Dream xác nhận lại nếu sai.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  _SignupStep _step = _SignupStep.enterPhone;
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _otp = '';
  bool _otpVerified = false;
  bool _isLoading = false;
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
      setState(() => _step = _SignupStep.verifyAndSetPassword);
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
      // go_router redirect tự chuyển sang /home khi có session (đã có từ lúc verifyOtp).
    } catch (e) {
      setState(() => _errorText = 'Không tạo được tài khoản, thử lại');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/login')),
        title: const Text('Create account'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        toolbarHeight: kToolbarHeight + 8,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Main Manager', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _ProgressDots(step: _step == _SignupStep.enterPhone ? 0 : (_otpVerified ? 2 : 1)),
              const SizedBox(height: 20),
              if (_step == _SignupStep.enterPhone) _buildPhoneStep() else _buildVerifyAndPasswordStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sign up', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text("Let's get your account started.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        const _FieldLabel('Phone number'),
        TextField(controller: _phoneController, keyboardType: TextInputType.phone),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            child: _isLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send code'),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyAndPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verify your phone', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          'We sent a 6-digit code to ${_phoneController.text}. The code expires in $_mmss.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Center(
          child: PinCodeTextField(
            appContext: context,
            length: 6,
            enabled: !_otpVerified,
            onChanged: (value) => _otp = value,
            onCompleted: (_) => _verifyOtp(),
            keyboardType: TextInputType.number,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(AppRadii.inputField),
              fieldHeight: 48,
              fieldWidth: 42,
              activeColor: AppColors.accentOrange,
              selectedColor: AppColors.accentOrange,
              inactiveColor: AppColors.neutral200,
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 8),
        Center(
          child: _resendSecondsLeft > 0
              ? Text('Resend code · $_mmss', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
              : TextButton(onPressed: _isLoading ? null : _sendOtp, child: const Text('Resend code')),
        ),
        if (_otpVerified) ...[
          const SizedBox(height: 28),
          const Text('STEP 3 — SET PASSWORD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          const _FieldLabel('Full name'),
          TextField(controller: _fullNameController),
          const SizedBox(height: 16),
          const _FieldLabel('Password'),
          TextField(controller: _passwordController, obscureText: true, onChanged: (_) => _onConfirmPasswordChanged(_confirmPasswordController.text)),
          const SizedBox(height: 16),
          const _FieldLabel('Confirm password'),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            onChanged: _onConfirmPasswordChanged,
            decoration: _confirmPasswordError == null
                ? null
                : InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.inputField), borderSide: const BorderSide(color: AppColors.error)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.inputField), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
                  ),
          ),
          if (_confirmPasswordError != null) ...[
            const SizedBox(height: 4),
            Text(_confirmPasswordError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
          const SizedBox(height: 20),
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
      ],
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

/// 4 chấm tiến trình trên đầu màn Đăng ký — khớp ảnh Figma (xanh=xong,
/// cam=đang làm, xám=chưa tới). `step`: 0=nhập SĐT, 1=xác thực OTP, 2=đặt mật khẩu.
class _ProgressDots extends StatelessWidget {
  final int step;
  const _ProgressDots({required this.step});

  @override
  Widget build(BuildContext context) {
    Color colorFor(int index) {
      if (index < step) return AppColors.success;
      if (index == step) return AppColors.accentOrange;
      return AppColors.neutral200;
    }

    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
            decoration: BoxDecoration(color: colorFor(i), borderRadius: BorderRadius.circular(2)),
          ),
        );
      }),
    );
  }
}

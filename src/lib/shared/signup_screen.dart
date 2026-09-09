import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../core/theme.dart';
import '../data/auth_repository.dart';

enum _SignupStep { enterPhone, enterOtp, createPassword }

/// S-02 — Đăng ký (SĐT & OTP). Xem docs/SCREEN-SPEC.md mục 2.1.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  _SignupStep _step = _SignupStep.enterPhone;
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _otp = '';
  bool _isLoading = false;
  String? _errorText;

  Timer? _resendTimer;
  int _resendSecondsLeft = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

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
      setState(() => _step = _SignupStep.enterOtp);
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
      setState(() => _step = _SignupStep.createPassword);
    } catch (e) {
      // TODO: phân biệt "sai OTP" và "hết hạn" để hiện đúng thông báo (SCREEN-SPEC.md edge case).
      setState(() => _errorText = 'Mã OTP không đúng hoặc đã hết hạn');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createPassword() async {
    if (_passwordController.text.length < 6) {
      setState(() => _errorText = 'Mật khẩu tối thiểu 6 ký tự');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorText = 'Mật khẩu xác nhận không khớp');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await authRepository.setPassword(_passwordController.text);
      await authRepository.ensureUserProfile(phone: _phoneController.text.trim());
      // go_router redirect tự chuyển sang /home khi có session (đã có từ lúc verifyOtp).
    } catch (e) {
      setState(() => _errorText = 'Không tạo được mật khẩu, thử lại');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/login')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: switch (_step) {
            _SignupStep.enterPhone => _buildPhoneStep(),
            _SignupStep.enterOtp => _buildOtpStep(),
            _SignupStep.createPassword => _buildPasswordStep(),
          },
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text('Nhập số điện thoại', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone number', hintText: '+84 9xx xxx xxx'),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: _isLoading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Gửi mã OTP'),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text('Nhập mã OTP', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Đã gửi mã 6 số tới ${_phoneController.text}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 20),
        PinCodeTextField(
          appContext: context,
          length: 6,
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
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        Center(
          child: _resendSecondsLeft > 0
              ? Text('Gửi lại mã sau ${_resendSecondsLeft}s', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
              : TextButton(onPressed: _isLoading ? null : _sendOtp, child: const Text('Gửi lại mã')),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isLoading || _otp.length != 6 ? null : _verifyOtp,
          child: _isLoading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Xác nhận'),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text('Tạo mật khẩu', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mật khẩu (tối thiểu 6 ký tự)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _createPassword,
          child: _isLoading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Hoàn tất'),
        ),
      ],
    );
  }
}

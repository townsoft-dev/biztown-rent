import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';

/// Bọc lại các thao tác Auth của Supabase — 1 luồng đăng ký/đăng nhập duy nhất
/// cho mọi người (không phân biệt sẽ là owner/manager, vai trò xác định theo
/// từng nhà ở tb_user_house_access). Xem docs/ARCHITECTURE.md mục Auth.
class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  /// Chuẩn hoá SĐT nhập kiểu VN (`0909 888 777`, có/không dấu cách) về chuẩn
  /// E.164 (`+84909888777`) mà Supabase Auth yêu cầu. Số đã có `+` thì giữ nguyên.
  static String normalizeVnPhone(String raw) {
    final digits = raw.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('0')) return '+84${digits.substring(1)}';
    if (digits.startsWith('84')) return '+$digits';
    return '+84$digits';
  }

  /// S-01: đăng nhập bằng SĐT + mật khẩu.
  Future<void> signInWithPassword(
      {required String phone, required String password}) async {
    await _client.auth
        .signInWithPassword(phone: normalizeVnPhone(phone), password: password);
  }

  /// S-02 bước 1 / "Quên mật khẩu": gửi OTP qua Send SMS Hook (nhà cung cấp SMS VN).
  Future<void> sendOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: normalizeVnPhone(phone));
  }

  /// S-02 bước 2: xác thực OTP — tạo session nếu đúng.
  Future<void> verifyOtp({required String phone, required String token}) async {
    await _client.auth.verifyOTP(
        phone: normalizeVnPhone(phone), token: token, type: OtpType.sms);
  }

  /// S-02 bước 3 (tài khoản mới) / khôi phục sau OTP quên mật khẩu: đặt mật khẩu.
  Future<void> setPassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  /// Tạo/đảm bảo có dòng tb_user tương ứng với session hiện tại — gọi sau khi
  /// hoàn tất đăng ký (OTP verified + password set). fullName/idNumber điền sau
  /// ở P-02 nếu để trống lúc đăng ký nhanh.
  Future<void> ensureUserProfile(
      {required String phone, String? fullName}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final normalizedPhone = normalizeVnPhone(phone);
    await _client.from('tb_user').upsert({
      'id': userId,
      'phone': normalizedPhone,
      'full_name': fullName ?? normalizedPhone,
    });
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

final authRepository = AuthRepository(supabase);

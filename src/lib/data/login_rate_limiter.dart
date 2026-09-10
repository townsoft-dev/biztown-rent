import 'package:shared_preferences/shared_preferences.dart';

/// S-01 edge case (SCREEN-SPEC.md): "Sai mật khẩu nhiều lần → rate-limit (khoá tạm
/// 10 phút sau 5 lần sai)". Lưu cục bộ trên máy (SharedPreferences), theo từng SĐT —
/// đây là hàng rào UX phía client, không thay thế cho rate-limit thật phía server
/// (Supabase Auth có rate-limit chung riêng, không theo đúng ngữ nghĩa "5 lần/SĐT" này).
class LoginRateLimiter {
  static const _maxAttempts = 5;
  static const _lockDuration = Duration(minutes: 10);

  String _attemptsKey(String phone) => 'login_attempts_$phone';
  String _lockedUntilKey(String phone) => 'login_locked_until_$phone';

  /// Trả về thời điểm hết khoá nếu đang bị khoá, null nếu không.
  Future<DateTime?> checkLocked(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final lockedUntilMs = prefs.getInt(_lockedUntilKey(phone));
    if (lockedUntilMs == null) return null;
    final lockedUntil = DateTime.fromMillisecondsSinceEpoch(lockedUntilMs);
    if (lockedUntil.isAfter(DateTime.now())) return lockedUntil;
    // Hết hạn khoá — dọn luôn để lần sau không phải check nữa.
    await prefs.remove(_lockedUntilKey(phone));
    await prefs.remove(_attemptsKey(phone));
    return null;
  }

  /// Gọi khi đăng nhập sai — trả về thời điểm hết khoá nếu lần này khiến tài khoản bị khoá.
  Future<DateTime?> recordFailure(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(_attemptsKey(phone)) ?? 0) + 1;
    if (attempts >= _maxAttempts) {
      final lockedUntil = DateTime.now().add(_lockDuration);
      await prefs.setInt(
          _lockedUntilKey(phone), lockedUntil.millisecondsSinceEpoch);
      await prefs.setInt(_attemptsKey(phone), 0);
      return lockedUntil;
    }
    await prefs.setInt(_attemptsKey(phone), attempts);
    return null;
  }

  Future<void> recordSuccess(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptsKey(phone));
    await prefs.remove(_lockedUntilKey(phone));
  }
}

final loginRateLimiter = LoginRateLimiter();

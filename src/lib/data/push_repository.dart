import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';

/// Đăng ký device token (FCM) vào `tb_device_token` — điều kiện để nhận Push
/// khi app đang tắt/nền (khác Realtime chỉ chạy khi app đang mở, xem
/// docs/DECISIONS.md Đợt 43, 46). Gọi mỗi khi có session hợp lệ (Splash +
/// Login thành công) — an toàn gọi lại nhiều lần nhờ unique(user_id, token)
/// + upsert. Mọi lỗi đều bị nuốt (log rồi bỏ qua) — push KHÔNG phải luồng lõi,
/// không được phép chặn đăng nhập/mở app (VD: user từ chối quyền thông báo).
class PushRepository {
  final SupabaseClient _client;
  PushRepository(this._client);

  Future<void> registerDeviceToken() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission().timeout(const Duration(seconds: 15));
      // getToken() gọi tới backend FCM của Google — có thể treo vô thời hạn nếu
      // máy/mạng không tới được (VD: máy ảo test không có Google Play Services
      // hoạt động đầy đủ) — timeout để không giữ mãi 1 Future không bao giờ xong.
      final token =
          await messaging.getToken().timeout(const Duration(seconds: 15));
      if (token == null) return;
      await _upsert(userId, token);
    } catch (e) {
      debugPrint('registerDeviceToken() lỗi, bỏ qua: $e');
    }
  }

  /// FCM tự đổi token định kỳ — nghe để cập nhật lại DB, tránh push vào token cũ.
  void listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      try {
        await _upsert(userId, token);
      } catch (e) {
        debugPrint('onTokenRefresh() upsert lỗi, bỏ qua: $e');
      }
    });
  }

  Future<void> _upsert(String userId, String token) async {
    await _client.from('tb_device_token').upsert(
      {
        'user_id': userId,
        'platform':
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'token': token,
      },
      onConflict: 'user_id,token',
    );
  }
}

final pushRepository = PushRepository(supabase);

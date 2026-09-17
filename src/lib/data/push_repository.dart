import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';

/// Kết quả chẩn đoán push, hiện thẳng ở cuối tab Hồ sơ.
///
/// Có cái này vì push hỏng RẤT khó truy: mọi lỗi đều bị nuốt có chủ ý để không
/// chặn đăng nhập, log `debugPrint` thì không đọc được trên bản TestFlight, và
/// macOS đời mới bỏ luôn khả năng đọc log iPhone qua mạng. Ngày 17/09/2026 mất
/// gần cả buổi mới khoanh được vùng chỉ vì không nhìn thấy nó chết ở bước nào.
enum PushStatus {
  /// Chưa đăng nhập nên chưa đăng ký gì — không phải lỗi.
  notSignedIn,

  /// Người dùng chưa cấp quyền thông báo (hoặc đã từ chối).
  permissionDenied,

  /// iOS: Apple chưa cấp APNs token. Thường là app chưa đăng ký được với APNs.
  noApnsToken,

  /// FCM không trả về device token.
  noFcmToken,

  /// Lấy được token nhưng lưu xuống `tb_device_token` thất bại.
  saveFailed,

  /// Đủ điều kiện nhận push.
  ready,
}

/// Đăng ký device token (FCM) vào `tb_device_token` — điều kiện để nhận Push
/// khi app đang tắt/nền (khác Realtime chỉ chạy khi app đang mở, xem
/// docs/DECISIONS.md Đợt 43, 46). Gọi mỗi khi có session hợp lệ (Splash +
/// Login thành công) — an toàn gọi lại nhiều lần nhờ unique(user_id, token)
/// + upsert. Mọi lỗi đều bị nuốt (log rồi bỏ qua) — push KHÔNG phải luồng lõi,
/// không được phép chặn đăng nhập/mở app (VD: user từ chối quyền thông báo).
class PushRepository {
  final SupabaseClient _client;
  PushRepository(this._client);

  /// Chạy lại đúng các bước của `registerDeviceToken()` nhưng TRẢ VỀ lý do
  /// thất bại thay vì nuốt. Gọi khi mở tab Hồ sơ — vừa chẩn đoán, vừa là một
  /// lần thử đăng ký lại (lưu token luôn nếu lấy được).
  Future<PushStatus> diagnose() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return PushStatus.notSignedIn;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging
          .requestPermission()
          .timeout(const Duration(seconds: 15));
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return PushStatus.permissionDenied;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        if (await _waitForApnsToken(messaging) == null) {
          return PushStatus.noApnsToken;
        }
      }
      final token =
          await messaging.getToken().timeout(const Duration(seconds: 15));
      if (token == null) return PushStatus.noFcmToken;
      await _upsert(userId, token);
      return PushStatus.ready;
    } catch (e) {
      debugPrint('diagnose() lỗi: $e');
      return PushStatus.saveFailed;
    }
  }

  Future<void> registerDeviceToken() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission().timeout(const Duration(seconds: 15));

      // iOS: PHẢI có APNs token của Apple trước, rồi FCM mới đổi được sang
      // device token. Gọi `getToken()` sớm hơn thì nó ném
      // `apns-token-not-set` và (do cả hàm này bọc try/catch) hỏng im lặng —
      // người dùng cho phép thông báo xong mà `tb_device_token` vẫn trống.
      // Apple cấp token này bất đồng bộ sau khi đăng ký, thường dưới 1 giây
      // nhưng mạng chậm thì lâu hơn, nên chờ có giới hạn thay vì gọi ngay.
      // Android không có khái niệm này nên bỏ qua.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _waitForApnsToken(messaging);
        if (apnsToken == null) {
          debugPrint('Chưa lấy được APNs token sau 20s — bỏ qua đăng ký push. '
              'Thường do sai `aps-environment` trong entitlements (bản Release '
              'phải là "production") hoặc máy chưa vào được mạng Apple.');
          return;
        }
      }

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

  /// Chờ Apple cấp APNs token, tối đa 20 giây. Trả `null` nếu hết giờ.
  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final apnsToken = await messaging.getAPNSToken();
      if (apnsToken != null) return apnsToken;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return null;
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

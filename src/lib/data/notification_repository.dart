import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import 'models/app_notification.dart';

/// S-03 — Notification Center. Chỉ làm 3 loại tức thời (BR-NOTI-01/03/06);
/// 03/06 gọi Edge Function `create-notification` (permission check + fan-out
/// phía server); 01 đã tự ghi thẳng trong `generate-invoice`, không cần gọi
/// từ đây. Đọc/đánh dấu đã đọc đi thẳng qua bảng `tb_notification` (RLS tự
/// giới hạn đúng `recipient_phone` của người đang đăng nhập).
class NotificationRepository {
  final SupabaseClient _client;
  const NotificationRepository(this._client);

  /// Realtime — chuông/danh sách tự cập nhật ngay cả khi thông báo mới đến
  /// từ người khác (quản lý khác, hoặc backend) trong lúc app đang mở sẵn,
  /// không chỉ khi chính người dùng vừa thao tác xong. RLS SELECT có sẵn tự
  /// áp dụng cho luồng này (chỉ nhận đúng dòng của mình), không cần lọc thêm
  /// `recipient_phone` ở đây.
  Stream<List<AppNotification>> watch({int limit = 50}) {
    return _client
        .from('tb_notification')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .map((rows) => rows.map((r) => AppNotification.fromMap(r)).toList());
  }

  Future<void> markAsRead(String id) async {
    await _client
        .from('tb_notification')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .isFilter('read_at', null);
  }

  /// BR-NOTI-03 — gọi sau khi B-04 "Mark as collected" thành công.
  Future<void> notifyInvoiceCollected({
    required String invoiceId,
    required String actorPhone,
  }) async {
    await _client.functions.invoke('create-notification', body: {
      'type': 'invoice_collected',
      'invoiceId': invoiceId,
      'actorPhone': actorPhone,
    });
  }

  // BR-NOTI-06 (được mời làm quản lý) gọi thẳng từ `UserRepository.saveManager()`
  // — nơi đó đã có sẵn `_myPhone`/houseId đang xử lý, không cần thêm 1 lớp gọi
  // qua đây.
}

final notificationRepository = NotificationRepository(supabase);

enum NotificationType { invoiceSent, invoiceCollected, managerInvited }

extension NotificationTypeX on NotificationType {
  static NotificationType fromDb(String value) => switch (value) {
        'invoice_collected' => NotificationType.invoiceCollected,
        'manager_invited' => NotificationType.managerInvited,
        _ => NotificationType.invoiceSent,
      };
}

/// 1 dòng `tb_notification` — S-03 Notification Center. Chỉ lưu `type` +
/// `payload` có cấu trúc, KHÔNG lưu sẵn câu chữ hiển thị — dựng câu qua
/// `AppStrings.t()` tại thời điểm hiển thị để đúng ngôn ngữ UI người xem
/// đang chọn (xem `notification_center_screen.dart`).
class AppNotification {
  final String id;
  final NotificationType type;
  final String? houseId;
  final String? targetInvoiceId;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.houseId,
    required this.targetInvoiceId,
    required this.payload,
    required this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      type: NotificationTypeX.fromDb(map['type'] as String),
      houseId: map['house_id'] as String?,
      targetInvoiceId: map['target_invoice_id'] as String?,
      payload: (map['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      readAt: map['read_at'] == null
          ? null
          : DateTime.parse(map['read_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

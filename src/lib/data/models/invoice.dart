enum InvoiceStatus { draft, sent, collected }

extension InvoiceStatusX on InvoiceStatus {
  static InvoiceStatus fromDb(String value) => switch (value) {
        'Sent' => InvoiceStatus.sent,
        'Collected' => InvoiceStatus.collected,
        _ => InvoiceStatus.draft,
      };

  String get dbValue => switch (this) {
        InvoiceStatus.draft => 'Draft',
        InvoiceStatus.sent => 'Sent',
        InvoiceStatus.collected => 'Collected',
      };
}

/// `tb_invoice` (docs/DATABASE.md) — Bills (B-0x) CHƯA xây (chưa có UI tạo
/// hoá đơn thật) nên bảng này trong thực tế luôn rỗng; model/repo này chỉ
/// đọc (không tạo/sửa) để T-09 tính "Outstanding invoices" và tương lai B-0x
/// dùng lại đúng field khi xây thật, không phải định nghĩa lại.
class Invoice {
  final String id;
  final String contractId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime dueDate;
  final num totalAmount;
  final InvoiceStatus status;

  const Invoice({
    required this.id,
    required this.contractId,
    required this.periodStart,
    required this.periodEnd,
    required this.dueDate,
    required this.totalAmount,
    required this.status,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      contractId: map['contract_id'] as String,
      periodStart: DateTime.parse(map['period_start'] as String),
      periodEnd: DateTime.parse(map['period_end'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      totalAmount: map['total_amount'] as num,
      status: InvoiceStatusX.fromDb(map['status'] as String),
    );
  }
}

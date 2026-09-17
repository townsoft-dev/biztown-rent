import 'recurring_fee.dart';

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

enum InvoiceUtilityType { electricity, water }

extension InvoiceUtilityTypeX on InvoiceUtilityType {
  static InvoiceUtilityType fromDb(String value) => value == 'water'
      ? InvoiceUtilityType.water
      : InvoiceUtilityType.electricity;

  String get dbValue => switch (this) {
        InvoiceUtilityType.electricity => 'electricity',
        InvoiceUtilityType.water => 'water',
      };
}

/// 1 dòng trong `tb_invoice.utility_lines` (jsonb) — 1 phòng × 1 loại tiện
/// ích. `previousReading`/`currentReading`/`usageAmount`/`unitPrice` đều
/// `null` khi phòng tính `FLAT` (chỉ có `totalAmount` = số khoán).
class UtilityLine {
  final String roomId;
  final String roomNo;
  final InvoiceUtilityType utilityType;
  final num? previousReading;
  final num? currentReading;
  final num? usageAmount;
  final num? unitPrice;
  final num totalAmount;
  final String? readingId;

  const UtilityLine({
    required this.roomId,
    required this.roomNo,
    required this.utilityType,
    this.previousReading,
    this.currentReading,
    this.usageAmount,
    this.unitPrice,
    required this.totalAmount,
    this.readingId,
  });

  factory UtilityLine.fromMap(Map<String, dynamic> map) {
    return UtilityLine(
      roomId: map['roomId'] as String,
      roomNo: map['roomNo'] as String,
      utilityType: InvoiceUtilityTypeX.fromDb(map['utilityType'] as String),
      previousReading: map['previousReading'] as num?,
      currentReading: map['currentReading'] as num?,
      usageAmount: map['usageAmount'] as num?,
      unitPrice: map['unitPrice'] as num?,
      totalAmount: map['totalAmount'] as num,
      readingId: map['readingId'] as String?,
    );
  }

  bool get isFlat => previousReading == null && unitPrice == null;
}

/// `tb_invoice` (docs/DATABASE.md) — Bills (B-0x). Engine tính tiền nằm ở
/// Edge Function `generate-invoice` (không viết lại bằng Dart) — model này
/// chỉ đọc/ghi đúng field, không tự tính toán gì thêm.
class Invoice {
  final String id;
  final String contractId;
  final String contractVersionId;
  final String houseId;
  final String houseName;
  final List<String> roomNos;
  final String tenantName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime dueDate;
  final num rentAmount;
  final List<UtilityLine> utilityLines;
  final num serviceFeeAmount;
  final List<RecurringFee> recurringFees;
  final List<RecurringFee> otherFees;
  final num totalAmount;
  final InvoiceStatus status;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? collectedAt;

  /// Mã tra cứu công khai (12 ký tự) — dùng dựng link xem hoá đơn/mã QR gửi
  /// cho người thuê, xem `core/invoice_message.dart` và Edge Function
  /// `invoice-qr`. `null` với hoá đơn tạo trước khi có cột này.
  final String? publicCode;

  const Invoice({
    required this.id,
    required this.contractId,
    required this.contractVersionId,
    required this.houseId,
    required this.houseName,
    required this.roomNos,
    required this.tenantName,
    required this.periodStart,
    required this.periodEnd,
    required this.dueDate,
    required this.rentAmount,
    required this.utilityLines,
    required this.serviceFeeAmount,
    required this.recurringFees,
    required this.otherFees,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.sentAt,
    this.collectedAt,
    this.publicCode,
  });

  /// Overdue là trạng thái SUY RA (BR-BILL: không lưu DB) — còn `Sent` mà đã
  /// qua `dueDate`.
  bool get isOverdue =>
      status == InvoiceStatus.sent && dueDate.isBefore(DateTime.now());

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      contractId: map['contract_id'] as String,
      contractVersionId: map['contract_version_id'] as String,
      houseId: map['house_id'] as String,
      houseName: map['house_name'] as String,
      roomNos: (map['room_nos'] as List).map((e) => e as String).toList(),
      tenantName: map['tenant_name'] as String,
      periodStart: DateTime.parse(map['period_start'] as String),
      periodEnd: DateTime.parse(map['period_end'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      rentAmount: map['rent_amount'] as num,
      utilityLines: (map['utility_lines'] as List)
          .map((e) => UtilityLine.fromMap(e as Map<String, dynamic>))
          .toList(),
      serviceFeeAmount: map['service_fee_amount'] as num,
      recurringFees: (map['recurring_fees'] as List)
          .map((e) => RecurringFee.fromMap(e as Map<String, dynamic>))
          .toList(),
      otherFees: (map['other_fees'] as List)
          .map((e) => RecurringFee.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalAmount: map['total_amount'] as num,
      status: InvoiceStatusX.fromDb(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      sentAt: map['sent_at'] == null
          ? null
          : DateTime.parse(map['sent_at'] as String),
      collectedAt: map['collected_at'] == null
          ? null
          : DateTime.parse(map['collected_at'] as String),
      publicCode: map['public_code'] as String?,
    );
  }
}

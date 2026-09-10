import '../../core/number_format.dart';

/// Format số chỉ số (Previous/Current/Usage) có dấu phẩy phân cách hàng
/// nghìn — đúng Figma (VD "1,120 kWh", "1,216", không phải "1120"/"1216").
/// Dùng chung [formatNumber] (`core/number_format.dart`) — cùng 1 chuẩn định
/// dạng số cho mọi nơi trong app, không riêng gì chỉ số điện/nước.
String formatReadingValue(num value) => formatNumber(value);

/// Loại tiện ích — quyết định bảng nào bị tác động (`tb_electricity_reading`
/// hay `tb_water_reading`, xem migration `20260909133320_v3_schema_rebuild.sql`).
/// 2 bảng cấu trúc giống hệt nhau, không gộp làm 1 vì đây là quyết định đã
/// chốt từ trước (tách riêng theo từng loại tiện ích).
enum UtilityType { electricity, water }

extension UtilityTypeX on UtilityType {
  String get table => switch (this) {
        UtilityType.electricity => 'tb_electricity_reading',
        UtilityType.water => 'tb_water_reading',
      };

  String get label => switch (this) {
        UtilityType.electricity => 'Electricity',
        UtilityType.water => 'Water',
      };

  String get unit => switch (this) {
        UtilityType.electricity => 'kWh',
        UtilityType.water => 'm³',
      };

  /// Dùng cho path param trên route (`/readings/:roomId/:utility`).
  String get pathSegment => switch (this) {
        UtilityType.electricity => 'electricity',
        UtilityType.water => 'water',
      };

  static UtilityType fromPathSegment(String value) => switch (value) {
        'water' => UtilityType.water,
        _ => UtilityType.electricity,
      };
}

enum ReadingType { periodic, moveIn, moveOut }

extension ReadingTypeX on ReadingType {
  static ReadingType fromDb(String value) => switch (value) {
        'MOVE_IN' => ReadingType.moveIn,
        'MOVE_OUT' => ReadingType.moveOut,
        _ => ReadingType.periodic,
      };

  String get dbValue => switch (this) {
        ReadingType.periodic => 'PERIODIC',
        ReadingType.moveIn => 'MOVE_IN',
        ReadingType.moveOut => 'MOVE_OUT',
      };

  String get label => switch (this) {
        ReadingType.periodic => 'Periodic',
        ReadingType.moveIn => 'Move-in',
        ReadingType.moveOut => 'Move-out',
      };
}

/// 1 dòng trong `tb_electricity_reading`/`tb_water_reading` (BR-READ-01..07,
/// docs/BUSINESS-RULES.md mục 6) — `utilityType` không phải cột DB, chỉ đánh
/// dấu bản ghi này đọc từ bảng nào (2 bảng giống hệt cấu trúc).
/// `previousReadingId` mới là nguồn sự thật của chuỗi chỉ số (BR-METER-13) —
/// `previousReading` chỉ là snapshot hiển thị, KHÔNG dùng để tính lại gì cả.
class Reading {
  final String id;
  final UtilityType utilityType;
  final String roomId;
  final String houseId;
  final ReadingType readingType;
  final DateTime periodYm;
  final String? contractId;
  final DateTime readingDate;
  final String? previousReadingId;
  final num? previousReading;
  final num currentReading;
  final num? usageAmount;
  final String recordedByPhone;
  final String? photoUrl;
  final String? invoiceId;
  final String? note;
  final DateTime createdAt;

  const Reading({
    required this.id,
    required this.utilityType,
    required this.roomId,
    required this.houseId,
    required this.readingType,
    required this.periodYm,
    this.contractId,
    required this.readingDate,
    this.previousReadingId,
    this.previousReading,
    required this.currentReading,
    this.usageAmount,
    required this.recordedByPhone,
    this.photoUrl,
    this.invoiceId,
    this.note,
    required this.createdAt,
  });

  factory Reading.fromMap(Map<String, dynamic> map, UtilityType utilityType) {
    return Reading(
      id: map['id'] as String,
      utilityType: utilityType,
      roomId: map['room_id'] as String,
      houseId: map['house_id'] as String,
      readingType: ReadingTypeX.fromDb(map['reading_type'] as String),
      periodYm: DateTime.parse(map['period_ym'] as String),
      contractId: map['contract_id'] as String?,
      readingDate: DateTime.parse(map['reading_date'] as String),
      previousReadingId: map['previous_reading_id'] as String?,
      previousReading: map['previous_reading'] as num?,
      currentReading: map['current_reading'] as num,
      usageAmount: map['usage_amount'] as num?,
      recordedByPhone: map['recorded_by_phone'] as String,
      photoUrl: map['photo_url'] as String?,
      invoiceId: map['invoice_id'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

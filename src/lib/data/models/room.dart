import 'recurring_fee.dart';

enum RoomStatus { empty, occupied, underRepair }

extension RoomStatusX on RoomStatus {
  static RoomStatus fromDb(String value) => switch (value) {
        'Occupied' => RoomStatus.occupied,
        'UnderRepair' => RoomStatus.underRepair,
        _ => RoomStatus.empty,
      };

  String get dbValue => switch (this) {
        RoomStatus.empty => 'Empty',
        RoomStatus.occupied => 'Occupied',
        RoomStatus.underRepair => 'UnderRepair',
      };

  String get label => switch (this) {
        RoomStatus.empty => 'Empty',
        RoomStatus.occupied => 'Occupied',
        RoomStatus.underRepair => 'Under repair',
      };
}

/// `tb_room` (docs/DATABASE.md mục "tb_room"). `photos` là path object trong
/// bucket Storage `property-photos`, không phải URL công khai.
class Room {
  final String id;
  final String houseId;
  final String roomNo;
  final num areaSqm;
  final num? baseRent;
  final List<RecurringFee> recurringFees;
  final List<String> amenities;
  final List<String> photos;
  final RoomStatus status;
  final String? note;
  final DateTime createdAt;

  const Room({
    required this.id,
    required this.houseId,
    required this.roomNo,
    required this.areaSqm,
    this.baseRent,
    required this.recurringFees,
    required this.amenities,
    required this.photos,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      roomNo: map['room_no'] as String,
      areaSqm: map['area_sqm'] as num,
      baseRent: map['base_rent'] as num?,
      recurringFees: (map['recurring_fees'] as List? ?? const [])
          .map((e) => RecurringFee.fromMap(e as Map<String, dynamic>))
          .toList(),
      amenities: (map['amenities'] as List?)?.cast<String>() ?? const [],
      photos: (map['photos'] as List?)?.cast<String>() ?? const [],
      status: RoomStatusX.fromDb(map['status'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Dùng cho insert/update — không gồm `id`/`created_at`. Không có `status`:
  /// tạo mới luôn là Empty (server default); "Occupied" chỉ được set tự động
  /// khi có hợp đồng Active (chưa làm ở phase này) — Status field trên form
  /// hiện chỉ để xem, xem `docs/CURRENT_STATUS.md`.
  Map<String, dynamic> toInsertMap() => {
        'house_id': houseId,
        'room_no': roomNo,
        'area_sqm': areaSqm,
        'base_rent': baseRent,
        'recurring_fees': recurringFees.map((e) => e.toMap()).toList(),
        'amenities': amenities,
        'photos': photos,
        'note': note,
      };
}

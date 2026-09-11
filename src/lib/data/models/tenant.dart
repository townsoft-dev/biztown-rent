import '../../core/text_format.dart';

enum TenantSex { male, female }

extension TenantSexX on TenantSex {
  static TenantSex? fromDb(String? value) => switch (value) {
        'M' => TenantSex.male,
        'F' => TenantSex.female,
        _ => null,
      };

  String get dbValue => switch (this) {
        TenantSex.male => 'M',
        TenantSex.female => 'F',
      };

  String get label => switch (this) {
        TenantSex.male => 'Male',
        TenantSex.female => 'Female',
      };
}

/// `tb_tenant` (docs/DATABASE.md mục "tb_tenant") — hồ sơ Người thuê, KHÔNG có
/// tài khoản đăng nhập, thuộc đúng 1 `houseId` (BR-DATA-05, "Tenant Pool"
/// theo từng Nhà, không dùng chung giữa các Nhà dù cùng 1 chủ thật).
/// `idPhotoFront`/`idPhotoBack` là path trong bucket Storage `property-photos`
/// (path `<houseId>/tenants/<tenantId>/<file>`), không phải URL công khai.
class Tenant {
  final String id;
  final String houseId;
  final String fullName;
  final String phone;
  final TenantSex? sex;
  final DateTime? dateOfBirth;
  final String? mail;
  final String? idNumber;
  final String? idPhotoFront;
  final String? idPhotoBack;
  final String? note;
  final DateTime createdAt;

  const Tenant({
    required this.id,
    required this.houseId,
    required this.fullName,
    required this.phone,
    this.sex,
    this.dateOfBirth,
    this.mail,
    this.idNumber,
    this.idPhotoFront,
    this.idPhotoBack,
    this.note,
    required this.createdAt,
  });

  String get initials => initialsFromName(fullName);

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String,
      sex: TenantSexX.fromDb(map['sex'] as String?),
      dateOfBirth: map['date_of_birth'] == null
          ? null
          : DateTime.parse(map['date_of_birth'] as String),
      mail: map['mail'] as String?,
      idNumber: map['id_number'] as String?,
      idPhotoFront: map['id_photo_front'] as String?,
      idPhotoBack: map['id_photo_back'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Dùng cho insert/update — không gồm `id`/`created_at`.
  Map<String, dynamic> toInsertMap() => {
        'house_id': houseId,
        'full_name': fullName,
        'phone': phone,
        'sex': sex?.dbValue,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'mail': mail,
        'id_number': idNumber,
        'id_photo_front': idPhotoFront,
        'id_photo_back': idPhotoBack,
        'note': note,
      };
}

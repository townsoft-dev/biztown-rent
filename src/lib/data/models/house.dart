import 'recurring_fee.dart';

/// `tb_house` (docs/DATABASE.md mục "tb_house"). `photos` là danh sách path
/// object trong bucket Storage `property-photos` (không phải URL công khai —
/// bucket private, phải qua `HouseRepository.signedPhotoUrl`).
class House {
  final String id;
  final String name;
  final String address;
  final String? description;
  final List<String> photos;
  final String houseType; // 'Dãy trọ' | 'Căn hộ'
  final String ownerFullName;
  final String? ownerPhone;
  final String? ownerIdNumber;
  final String? ownerTaxCode;
  final String? ownerEmail;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankBin;
  final num? serviceFeeRatePerSqm;
  final num? defaultElectricityPrice;
  final num? defaultWaterPrice;
  final List<RecurringFee> recurringFees;
  final DateTime createdAt;

  const House({
    required this.id,
    required this.name,
    required this.address,
    this.description,
    required this.photos,
    required this.houseType,
    required this.ownerFullName,
    this.ownerPhone,
    this.ownerIdNumber,
    this.ownerTaxCode,
    this.ownerEmail,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankBin,
    this.serviceFeeRatePerSqm,
    this.defaultElectricityPrice,
    this.defaultWaterPrice,
    required this.recurringFees,
    required this.createdAt,
  });

  factory House.fromMap(Map<String, dynamic> map) {
    return House(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      description: map['description'] as String?,
      photos: (map['photos'] as List?)?.cast<String>() ?? const [],
      houseType: map['house_type'] as String,
      ownerFullName: map['owner_full_name'] as String,
      ownerPhone: map['owner_phone'] as String?,
      ownerIdNumber: map['owner_id_number'] as String?,
      ownerTaxCode: map['owner_tax_code'] as String?,
      ownerEmail: map['owner_email'] as String?,
      bankAccountName: map['bank_account_name'] as String?,
      bankAccountNumber: map['bank_account_number'] as String?,
      bankBin: map['bank_bin'] as String?,
      serviceFeeRatePerSqm: map['service_fee_rate_per_sqm'] as num?,
      defaultElectricityPrice: map['default_electricity_price'] as num?,
      defaultWaterPrice: map['default_water_price'] as num?,
      recurringFees: (map['recurring_fees'] as List? ?? const [])
          .map((e) => RecurringFee.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Dùng cho insert/update — không gồm `id`/`created_at` (server tự sinh).
  Map<String, dynamic> toInsertMap() => {
        'name': name,
        'address': address,
        'description': description,
        'photos': photos,
        'house_type': houseType,
        'owner_full_name': ownerFullName,
        'owner_phone': ownerPhone,
        'owner_id_number': ownerIdNumber,
        'owner_tax_code': ownerTaxCode,
        'owner_email': ownerEmail,
        'bank_account_name': bankAccountName,
        'bank_account_number': bankAccountNumber,
        'bank_bin': bankBin,
        'service_fee_rate_per_sqm': serviceFeeRatePerSqm,
        'default_electricity_price': defaultElectricityPrice,
        'default_water_price': defaultWaterPrice,
        'recurring_fees': recurringFees.map((e) => e.toMap()).toList(),
      };
}

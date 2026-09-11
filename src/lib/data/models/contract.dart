import 'recurring_fee.dart';

enum ContractStatus { active, ended }

extension ContractStatusX on ContractStatus {
  static ContractStatus fromDb(String value) =>
      value == 'Ended' ? ContractStatus.ended : ContractStatus.active;

  String get dbValue => this == ContractStatus.ended ? 'Ended' : 'Active';

  String get label => this == ContractStatus.ended ? 'Ended' : 'Active';
}

/// `changeReason` của `tb_contract_version` — `newContract` thay vì `new`
/// (từ khoá dành riêng của Dart).
enum ChangeReason { newContract, renewal, amendment }

extension ChangeReasonX on ChangeReason {
  static ChangeReason fromDb(String value) => switch (value) {
        'Renewal' => ChangeReason.renewal,
        'Amendment' => ChangeReason.amendment,
        _ => ChangeReason.newContract,
      };

  String get dbValue => switch (this) {
        ChangeReason.newContract => 'New',
        ChangeReason.renewal => 'Renewal',
        ChangeReason.amendment => 'Amendment',
      };

  String get label => switch (this) {
        ChangeReason.newContract => 'New',
        ChangeReason.renewal => 'Renewal',
        ChangeReason.amendment => 'Amendment',
      };
}

/// `electricityBillingMethod`/`waterBillingMethod` của `tb_contract_version`
/// (BR-CTR-10/BR-READ-05) — `byReading` tính theo chỉ số thật,
/// `flat` khoán số cố định, `notBilled` không thu (căn hộ nguyên căn).
enum UtilityBillingMethod { byReading, flat, notBilled }

extension UtilityBillingMethodX on UtilityBillingMethod {
  static UtilityBillingMethod fromDb(String value) => switch (value) {
        'FLAT' => UtilityBillingMethod.flat,
        'NOT_BILLED' => UtilityBillingMethod.notBilled,
        _ => UtilityBillingMethod.byReading,
      };

  String get dbValue => switch (this) {
        UtilityBillingMethod.byReading => 'BY_READING',
        UtilityBillingMethod.flat => 'FLAT',
        UtilityBillingMethod.notBilled => 'NOT_BILLED',
      };

  String get label => switch (this) {
        UtilityBillingMethod.byReading => 'Metered',
        UtilityBillingMethod.flat => 'Flat',
        UtilityBillingMethod.notBilled => 'Not billed',
      };
}

/// `serviceBillingMethod` của `tb_contract_version` — `flat` nhập thẳng
/// `serviceFeeAmount`/tháng, `byArea` tính `serviceFeeRatePerSqm *
/// contractAreaSqm` như cũ (xem docs/DECISIONS.md Đợt 27).
enum ServiceBillingMethod { flat, byArea }

extension ServiceBillingMethodX on ServiceBillingMethod {
  static ServiceBillingMethod fromDb(String value) =>
      value == 'Flat' ? ServiceBillingMethod.flat : ServiceBillingMethod.byArea;

  String get dbValue => this == ServiceBillingMethod.flat ? 'Flat' : 'ByArea';

  String get label => this == ServiceBillingMethod.flat ? 'Flat' : 'By area';
}

/// Thông tin môi giới/cò nhà (optional), lưu theo từng phiên bản hợp đồng —
/// `tb_contract_version.real_estate` (jsonb `{name, contact, fee}`).
class RealEstateInfo {
  final String? name;
  final String? contact;
  final num? fee;

  const RealEstateInfo({this.name, this.contact, this.fee});

  factory RealEstateInfo.fromMap(Map<String, dynamic> map) => RealEstateInfo(
        name: map['name'] as String?,
        contact: map['contact'] as String?,
        fee: map['fee'] as num?,
      );

  Map<String, dynamic> toMap() =>
      {'name': name, 'contact': contact, 'fee': fee};

  bool get isEmpty => name == null && contact == null && fee == null;
}

/// `tb_contract` (docs/DATABASE.md mục "tb_contract") — không có `roomId`
/// trực tiếp (xem `tb_contract_room`, 1 hợp đồng có thể gồm nhiều phòng).
/// Field settlement (`unpaidInvoicesTotal`.../`settlementConfirmedAt`) chỉ có
/// giá trị sau khi kết thúc hợp đồng ở T-09.
class Contract {
  final String id;
  final String tenantId;
  final String? currentVersionId;
  final ContractStatus status;
  final num? unpaidInvoicesTotal;
  final num? damageDeduction;
  final num? refundAmount;
  final String? settlementNote;
  final DateTime? settlementConfirmedAt;
  final DateTime createdAt;

  const Contract({
    required this.id,
    required this.tenantId,
    this.currentVersionId,
    required this.status,
    this.unpaidInvoicesTotal,
    this.damageDeduction,
    this.refundAmount,
    this.settlementNote,
    this.settlementConfirmedAt,
    required this.createdAt,
  });

  factory Contract.fromMap(Map<String, dynamic> map) {
    return Contract(
      id: map['id'] as String,
      tenantId: map['tenant_id'] as String,
      currentVersionId: map['current_version_id'] as String?,
      status: ContractStatusX.fromDb(map['status'] as String),
      unpaidInvoicesTotal: map['unpaid_invoices_total'] as num?,
      damageDeduction: map['damage_deduction'] as num?,
      refundAmount: map['refund_amount'] as num?,
      settlementNote: map['settlement_note'] as String?,
      settlementConfirmedAt: map['settlement_confirmed_at'] == null
          ? null
          : DateTime.parse(map['settlement_confirmed_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// `tb_contract_version` (docs/DATABASE.md mục "tb_contract_version") — mỗi
/// lần tạo/gia hạn/sửa điều khoản sinh 1 bản ghi mới, giữ nguyên lịch sử.
/// `monthlyRent`/`depositAmount` là cho CẢ hợp đồng, không theo từng phòng
/// (BR-CTR-01/BR-CTR-06).
class ContractVersion {
  final String id;
  final String contractId;
  final int versionNo;
  final ChangeReason changeReason;
  final DateTime startDate;
  final DateTime endDate;
  final num monthlyRent;
  final num depositAmount;
  final num? electricityUnitPrice;
  final num? waterUnitPrice;
  final UtilityBillingMethod electricityBillingMethod;
  final UtilityBillingMethod waterBillingMethod;
  final num? electricityFlatAmount;
  final num? waterFlatAmount;
  final List<RecurringFee> recurringFees;
  final int rentCycleMonths;
  final DateTime rentCycleAnchorYm;
  final int paymentDueDayOfMonth;
  final num? serviceFeeRatePerSqm;
  final num contractAreaSqm;
  final num? serviceFeeAmount;
  final ServiceBillingMethod serviceBillingMethod;
  final String? lateFeeTerms;
  final RealEstateInfo? realEstate;
  final DateTime createdAt;

  const ContractVersion({
    required this.id,
    required this.contractId,
    required this.versionNo,
    required this.changeReason,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.depositAmount,
    this.electricityUnitPrice,
    this.waterUnitPrice,
    required this.electricityBillingMethod,
    required this.waterBillingMethod,
    this.electricityFlatAmount,
    this.waterFlatAmount,
    required this.recurringFees,
    required this.rentCycleMonths,
    required this.rentCycleAnchorYm,
    required this.paymentDueDayOfMonth,
    this.serviceFeeRatePerSqm,
    required this.contractAreaSqm,
    this.serviceFeeAmount,
    required this.serviceBillingMethod,
    this.lateFeeTerms,
    this.realEstate,
    required this.createdAt,
  });

  factory ContractVersion.fromMap(Map<String, dynamic> map) {
    return ContractVersion(
      id: map['id'] as String,
      contractId: map['contract_id'] as String,
      versionNo: map['version_no'] as int,
      changeReason: ChangeReasonX.fromDb(map['change_reason'] as String),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      monthlyRent: map['monthly_rent'] as num,
      depositAmount: map['deposit_amount'] as num,
      electricityUnitPrice: map['electricity_unit_price'] as num?,
      waterUnitPrice: map['water_unit_price'] as num?,
      electricityBillingMethod: UtilityBillingMethodX.fromDb(
          map['electricity_billing_method'] as String),
      waterBillingMethod:
          UtilityBillingMethodX.fromDb(map['water_billing_method'] as String),
      electricityFlatAmount: map['electricity_flat_amount'] as num?,
      waterFlatAmount: map['water_flat_amount'] as num?,
      recurringFees: (map['recurring_fees'] as List? ?? const [])
          .map((e) => RecurringFee.fromMap(e as Map<String, dynamic>))
          .toList(),
      rentCycleMonths: map['rent_cycle_months'] as int,
      rentCycleAnchorYm: DateTime.parse(map['rent_cycle_anchor_ym'] as String),
      paymentDueDayOfMonth: map['payment_due_day_of_month'] as int,
      serviceFeeRatePerSqm: map['service_fee_rate_per_sqm'] as num?,
      contractAreaSqm: map['contract_area_sqm'] as num,
      serviceFeeAmount: map['service_fee_amount'] as num?,
      serviceBillingMethod:
          ServiceBillingMethodX.fromDb(map['service_billing_method'] as String),
      lateFeeTerms: map['late_fee_terms'] as String?,
      realEstate: map['real_estate'] == null
          ? null
          : RealEstateInfo.fromMap(map['real_estate'] as Map<String, dynamic>),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Dùng cho insert — không gồm `id`/`created_at`/`contract_id` (gắn riêng
  /// lúc gọi repository vì cần biết `contractId` vừa tạo hoặc đã có sẵn).
  Map<String, dynamic> toInsertMap() => {
        'version_no': versionNo,
        'change_reason': changeReason.dbValue,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
        'monthly_rent': monthlyRent,
        'deposit_amount': depositAmount,
        'electricity_unit_price': electricityUnitPrice,
        'water_unit_price': waterUnitPrice,
        'electricity_billing_method': electricityBillingMethod.dbValue,
        'water_billing_method': waterBillingMethod.dbValue,
        'electricity_flat_amount': electricityFlatAmount,
        'water_flat_amount': waterFlatAmount,
        'recurring_fees': recurringFees.map((e) => e.toMap()).toList(),
        'rent_cycle_months': rentCycleMonths,
        'rent_cycle_anchor_ym':
            rentCycleAnchorYm.toIso8601String().split('T').first,
        'payment_due_day_of_month': paymentDueDayOfMonth,
        'service_fee_rate_per_sqm': serviceFeeRatePerSqm,
        'contract_area_sqm': contractAreaSqm,
        'service_fee_amount': serviceFeeAmount,
        'service_billing_method': serviceBillingMethod.dbValue,
        'late_fee_terms': lateFeeTerms,
        'real_estate': (realEstate == null || realEstate!.isEmpty)
            ? null
            : realEstate!.toMap(),
      };
}

import '../data/models/contract.dart';
import '../data/models/invoice.dart';
import '../data/models/reading.dart';
import '../data/models/room.dart';
import '../data/models/tenant.dart';
import 'app_strings.dart';

/// Nhãn hiển thị (đã dịch) cho các enum nghiệp vụ — cố tình KHÔNG đặt trực
/// tiếp trong `data/models/room.dart`/`reading.dart` (giữ tầng data thuần,
/// không phụ thuộc `AppStrings`/tầng UI-i18n). `.label`/`.dbValue` trên các
/// model đó vẫn giữ nguyên tiếng Anh — chỉ dùng nội bộ (VD ghi log, so khớp
/// giá trị DB), KHÔNG dùng để hiển thị cho người dùng nữa kể từ khi có file
/// này; mọi nơi hiển thị phải gọi qua đây.
String roomStatusLabel(RoomStatus status) => switch (status) {
      RoomStatus.empty => AppStrings.t('status.empty'),
      RoomStatus.occupied => AppStrings.t('status.occupied'),
      RoomStatus.underRepair => AppStrings.t('status.underRepair'),
    };

String utilityTypeLabel(UtilityType type) => switch (type) {
      UtilityType.electricity => AppStrings.t('status.electricity'),
      UtilityType.water => AppStrings.t('status.water'),
    };

String readingTypeLabel(ReadingType type) => switch (type) {
      ReadingType.periodic => AppStrings.t('status.periodic'),
      ReadingType.moveIn => AppStrings.t('status.moveIn'),
      ReadingType.moveOut => AppStrings.t('status.moveOut'),
    };

String tenantSexLabel(TenantSex sex) => switch (sex) {
      TenantSex.male => AppStrings.t('status.male'),
      TenantSex.female => AppStrings.t('status.female'),
    };

String contractStatusLabel(ContractStatus status) => switch (status) {
      ContractStatus.active => AppStrings.t('status.active'),
      ContractStatus.ended => AppStrings.t('status.ended'),
    };

String changeReasonLabel(ChangeReason reason) => switch (reason) {
      ChangeReason.newContract => AppStrings.t('status.newContract'),
      ChangeReason.renewal => AppStrings.t('status.renewal'),
      ChangeReason.amendment => AppStrings.t('status.amendment'),
    };

String utilityBillingMethodLabel(UtilityBillingMethod method) =>
    switch (method) {
      UtilityBillingMethod.byReading => AppStrings.t('status.byReading'),
      UtilityBillingMethod.flat => AppStrings.t('status.flat'),
      UtilityBillingMethod.notBilled => AppStrings.t('status.notBilled'),
    };

String serviceBillingMethodLabel(ServiceBillingMethod method) =>
    switch (method) {
      ServiceBillingMethod.flat => AppStrings.t('status.flat'),
      ServiceBillingMethod.byArea => AppStrings.t('status.byArea'),
    };

/// `Overdue` KHÔNG có trong [InvoiceStatus] (suy ra từ `dueDate` khi còn
/// `Sent` — xem `Invoice.isOverdue`), nên hàm này chỉ nhận đúng 3 trạng thái
/// thật lưu DB; nơi gọi tự kiểm tra `isOverdue` trước để hiện đúng label.
String invoiceStatusLabel(InvoiceStatus status) => switch (status) {
      InvoiceStatus.draft => AppStrings.t('status.draft'),
      InvoiceStatus.sent => AppStrings.t('status.sent'),
      InvoiceStatus.collected => AppStrings.t('status.collected'),
    };

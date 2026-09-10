import '../../core/text_format.dart';

/// 1 người được mời làm Manager — gộp từ nhiều dòng `tb_user_house_access`
/// (`role='manager'`, 1 dòng/nhà đã cấp) THEO CÙNG 1 SỐ ĐIỆN THOẠI, vì P-05/
/// P-06 hiển thị theo NGƯỜI chứ không theo từng dòng quyền. `fullName`/
/// `idNumber`/`isActive` do chính chủ nhà tự nhập ở P-06 — khi lưu, được ghi
/// ĐỒNG BỘ xuống mọi dòng `tb_user_house_access` của người này (xem
/// `UserRepository.saveManager`), nên luôn giống nhau giữa các dòng của cùng
/// 1 người — lấy đại diện từ dòng đầu tiên là đủ.
class ManagerAccount {
  final String phone;
  final String fullName;
  final String? idNumber;
  final String? note;
  final bool isActive;
  final DateTime joinedAt;
  final Set<String> houseIds;

  const ManagerAccount({
    required this.phone,
    required this.fullName,
    this.idNumber,
    this.note,
    required this.isActive,
    required this.joinedAt,
    required this.houseIds,
  });

  String get initials => initialsFromName(fullName);
}

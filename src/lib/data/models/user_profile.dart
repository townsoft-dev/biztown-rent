/// `tb_user` — hồ sơ tài khoản đang đăng nhập (docs/DATABASE.md mục "tb_user").
/// `phone` ở đây KHÔNG có dấu "+" — khớp `current_user_phone()`/
/// `tb_user_house_access.phone` (xem changelog 2026-09-10 vụ sửa lỗi lệch
/// định dạng SĐT).
class UserProfile {
  final String id;
  final String phone;
  final String fullName;
  final String? email;
  final String? idNumber;
  final String status;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.phone,
    required this.fullName,
    this.email,
    this.idNumber,
    required this.status,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      phone: map['phone'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String?,
      idNumber: map['id_number'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

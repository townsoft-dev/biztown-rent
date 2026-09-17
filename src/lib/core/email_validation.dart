import 'app_strings.dart';

/// Kiểm tra email — dùng chung cho mọi ô nhập email trong app.
///
/// Email của người thuê nay là **trường bắt buộc** (dungtv chốt 17/09/2026):
/// đây sẽ là kênh gửi hoá đơn chính thay cho SMS, vì SMS đòi đăng ký Brandname
/// với chi phí không hợp lý ở quy mô hiện tại. Thiếu email thì người thuê đó
/// không nhận được hoá đơn nào.
///
/// Cố ý dùng mẫu kiểm tra ĐƠN GIẢN (có `@`, có tên miền, có phần mở rộng) chứ
/// không đuổi theo RFC 5322: mẫu đầy đủ dài và vẫn không chặn được email gõ
/// sai nhưng hợp lệ về cú pháp. Sai sót thật sẽ lộ ra khi gửi thư bị trả về.
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$');

bool isValidEmail(String raw) => _emailPattern.hasMatch(raw.trim());

/// Trả câu lỗi để hiện dưới ô nhập, hoặc `null` nếu hợp lệ.
String? validateEmail(String? value, {bool required = true}) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) {
    return required ? AppStrings.t('common.emailRequired') : null;
  }
  if (!isValidEmail(raw)) return AppStrings.t('common.emailInvalid');
  return null;
}

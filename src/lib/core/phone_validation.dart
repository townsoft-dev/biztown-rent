import 'package:flutter/services.dart';

import 'app_strings.dart';

/// Kiểm tra số điện thoại di động Việt Nam — dùng chung cho MỌI ô nhập SĐT
/// trong app (đăng nhập, đăng ký, quên mật khẩu, hồ sơ cá nhân, chủ nhà ở
/// H-02, người thuê ở T-03, quản lý ở P-06).
///
/// Lý do gom về một chỗ (dungtv báo 16/09/2026): bản TestFlight cho nhập
/// `864316888181818` vào ô "SĐT chủ nhà" mà vẫn lưu được — không ô nào trong
/// app kiểm tra định dạng. Số rác lọt vào database thì SMS hoá đơn gửi đi
/// thất bại mà chủ trọ không biết vì sao.
///
/// Đầu số di động VN hợp lệ sau số 0 là 3, 5, 7, 8, 9 (Viettel 032-039/086/
/// 096-098, Vinaphone 081-085/088/091/094, Mobifone 070/076-079/089/090/093,
/// Vietnamobile 052/056/058/092, Gmobile 059/099, Itelecom 087). Đầu số cố
/// định (024, 028...) cố tình KHÔNG chấp nhận vì cả app dùng SĐT để gửi
/// SMS/OTP — số bàn không nhận được tin nhắn.
const _vnMobilePattern = r'^0[35789][0-9]{8}$';

/// Chuẩn hoá về dạng nội địa `0xxxxxxxxx` để kiểm tra. Người dùng có thể gõ
/// `+84...`, `84...`, hoặc dán số có dấu cách/gạch ngang từ danh bạ.
String normalizeVnPhoneInput(String raw) {
  final digits = raw.trim().replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+84')) return '0${digits.substring(3)}';
  if (digits.startsWith('84') && digits.length > 10) {
    return '0${digits.substring(2)}';
  }
  return digits;
}

bool isValidVnPhone(String raw) =>
    RegExp(_vnMobilePattern).hasMatch(normalizeVnPhoneInput(raw));

/// Trả về câu lỗi để hiện dưới ô nhập, hoặc `null` nếu hợp lệ.
///
/// [required] `false` dùng cho ô không bắt buộc (VD SĐT chủ nhà ở màn Sửa nhà
/// khi chủ trọ chưa muốn điền) — để trống thì bỏ qua, nhưng đã điền thì vẫn
/// phải đúng định dạng.
String? validateVnPhone(String? value, {bool required = true}) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) {
    return required ? AppStrings.t('common.phoneRequired') : null;
  }
  if (!isValidVnPhone(raw)) return AppStrings.t('common.phoneInvalid');
  return null;
}

/// Chặn ngay lúc gõ: chỉ cho số và dấu `+` đầu, tối đa 12 ký tự (đủ cho dạng
/// `+84` + 9 số). Chặn từ đầu vào thì người dùng biết sai ngay, không phải gõ
/// xong mới thấy báo lỗi — đây là lý do bản cũ lọt được số 15 chữ số.
class VnPhoneInputFormatter extends TextInputFormatter {
  const VnPhoneInputFormatter();

  static const _maxLength = 12;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    // Giữ dấu "+" chỉ khi nó ở vị trí đầu tiên.
    final hasLeadingPlus = text.startsWith('+');
    text = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (hasLeadingPlus) text = '+$text';
    if (text.length > _maxLength) text = text.substring(0, _maxLength);
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

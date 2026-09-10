import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _displayFormat = NumberFormat('#,##0.##');
final _integerFormat = NumberFormat('#,##0');

/// Format 1 số cho HIỂN THỊ: dấu phẩy phân cách hàng nghìn, tối đa 2 chữ số
/// thập phân (VD `1120` → `"1,120"`, `1216.5` → `"1,216.5"`). Dùng chung cho
/// mọi nơi hiện số lượng/tiền trong app (chỉ số điện nước, đơn giá, tiền
/// thuê, phí định kỳ...) — tránh mỗi màn tự viết logic format riêng.
String formatNumber(num value) => _displayFormat.format(value);

/// Bỏ dấu phẩy phân cách hàng nghìn trước khi `num.tryParse` — mọi field có
/// gắn [ThousandsInputFormatter] đều phải đi qua hàm này lúc đọc giá trị để
/// lưu, nếu không `num.tryParse("1,120")` sẽ trả `null` (dấu phẩy không phải
/// ký tự số hợp lệ).
num? parseFormattedNumber(String text) =>
    num.tryParse(text.trim().replaceAll(',', ''));

/// `TextInputFormatter` tự thêm dấu phẩy phân cách hàng nghìn khi gõ (VD gõ
/// "4000" tự hiện "4,000") — gắn vào mọi field nhập tiền/số lượng lớn (đơn
/// giá điện/nước, tiền thuê, phí định kỳ, chỉ số điện/nước...). Cho phép tối
/// đa 1 dấu chấm thập phân + 2 chữ số sau dấu chấm, khớp đúng định dạng
/// [formatNumber] dùng ở nơi HIỂN THỊ — đảm bảo lúc NHẬP và lúc HIỂN THỊ luôn
/// cùng 1 chuẩn.
class ThousandsInputFormatter extends TextInputFormatter {
  const ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    // Đếm số ký tự "số/dấu chấm" trước con trỏ ở text gốc (chưa định dạng
    // lại) để sau khi thêm/bớt dấu phẩy vẫn đặt con trỏ đúng vị trí tương
    // ứng, không bị nhảy về cuối ô mỗi lần gõ.
    final cursorIndex = newValue.selection.end.clamp(0, text.length);
    final digitsBeforeCursor = text
        .substring(0, cursorIndex)
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .length;

    // Chỉ giữ số và tối đa 1 dấu chấm thập phân (dấu chấm thứ 2 trở đi bị bỏ).
    var cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
    final firstDot = cleaned.indexOf('.');
    if (firstDot != -1) {
      cleaned = cleaned.substring(0, firstDot + 1) +
          cleaned.substring(firstDot + 1).replaceAll('.', '');
    }

    final parts = cleaned.split('.');
    final integerPart = parts[0];
    final hasDot = parts.length > 1;
    var decimalPart = hasDot ? parts[1] : '';
    if (decimalPart.length > 2) decimalPart = decimalPart.substring(0, 2);

    final formattedInteger = integerPart.isEmpty
        ? ''
        : _integerFormat.format(int.parse(integerPart));
    final formatted = formattedInteger + (hasDot ? '.$decimalPart' : '');

    var seen = 0;
    var cursor = formatted.length;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9.]').hasMatch(formatted[i])) seen++;
      if (seen >= digitsBeforeCursor) {
        cursor = i + 1;
        break;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

/// Luật mật khẩu dùng chung cho MỌI chỗ người dùng đặt/đổi mật khẩu: S-02
/// Đăng ký (Đặt mật khẩu), S-04 Quên mật khẩu (Đặt lại mật khẩu), P-04 Đổi
/// mật khẩu.
///
/// Lý do gom về một chỗ (dungtv báo 16/09/2026): P-04 bắt đủ 3 điều kiện
/// (≥8 ký tự, ≥1 số, ≥1 chữ hoa) và hiện checklist sống theo từng ký tự gõ,
/// trong khi S-02/S-04 chỉ kiểm tra `length < 6`. Tức người dùng đăng ký được
/// bằng mật khẩu `abc123`, nhưng sau đó vào P-04 lại không đổi nổi sang mật
/// khẩu cùng độ mạnh — hai màn cùng làm một việc mà bắt hai luật khác nhau.
///
/// Lấy luật CHẶT hơn (của P-04) làm chuẩn chung, không hạ P-04 xuống cho khớp
/// S-02: hạ xuống là làm yếu mật khẩu của toàn bộ tài khoản.
///
/// 3 điều kiện này lấy từ Figma P-04 (node 220:4985) — `DATABASE.md` và
/// `BUSINESS-RULES.md` không quy định luật mật khẩu.
const int passwordMinLength = 8;

bool passwordHasMinLength(String value) => value.length >= passwordMinLength;

bool passwordHasNumber(String value) => value.contains(RegExp(r'[0-9]'));

bool passwordHasUppercase(String value) => value.contains(RegExp(r'[A-Z]'));

/// Đúng khi mật khẩu thoả CẢ 3 điều kiện.
bool isValidPassword(String value) =>
    passwordHasMinLength(value) &&
    passwordHasNumber(value) &&
    passwordHasUppercase(value);

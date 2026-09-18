/// Máy chủ sinh ẢNH hoá đơn — cùng dự án Supabase mà app Flutter đang dùng.
///
/// Dùng chung đúng hàm `i` mà link SMS đang trỏ tới, không dựng endpoint
/// riêng cho Mini App. Tên hàm rút xuống một chữ là để link còn vừa ô tham số
/// 70 ký tự của mẫu SMS (xem `src/lib/core/invoice_message.dart` bên Flutter).
export const INVOICE_IMAGE_BASE =
  "https://rrtppoibjprlvasnbvwr.supabase.co/functions/v1/i";

/// Mã tra cứu hoá đơn: 12 ký tự, bảng chữ đã bỏ các ký tự dễ đọc nhầm (I, O, U).
export const CODE_PATTERN = /^[0-9A-HJ-NP-TV-Z]{12}$/;

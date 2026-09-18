// Máy chủ sinh ảnh hoá đơn. Cùng dự án Supabase mà app Flutter đang dùng.
//
// Cố ý để đường dẫn `/functions/v1/i/` khớp đúng hàm `i` — tên hàm rút xuống
// một chữ để link còn vừa ô tham số 70 ký tự của mẫu SMS; Mini App dùng chung
// hàm đó luôn, không dựng endpoint riêng.
export const INVOICE_IMAGE_BASE =
  "https://rrtppoibjprlvasnbvwr.supabase.co/functions/v1/i";

/// Mã tra cứu: 12 ký tự, bảng chữ đã bỏ các ký tự dễ đọc nhầm (I, O, U).
export const CODE_PATTERN = /^[0-9A-HJ-NP-TV-Z]{12}$/;

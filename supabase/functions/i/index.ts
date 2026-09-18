// Đường dẫn CHÍNH cho ảnh hoá đơn gửi trong SMS. Tên hàm chỉ một chữ `i` là
// CỐ Ý: mỗi ký tự trong link ăn thẳng vào ngân sách 160 ký tự của một đoạn SMS.
// Thân hàm nằm ở `_shared/invoice_image.ts`, dùng chung với `invoice`.
import { invoiceImageHandler } from "../_shared/invoice_image.ts";
export default invoiceImageHandler;

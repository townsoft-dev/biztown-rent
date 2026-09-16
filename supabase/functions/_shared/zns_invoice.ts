// _shared/zns_invoice.ts
//
// Map 1 hoá đơn (`tb_invoice`) sang đúng 10 tham số của ZNS template ĐÃ ĐƯỢC
// ZALO DUYỆT: "BizTown Rent-Manager : Hóa đơn định kỳ 2" (ID `636461`, loại
// "Mẫu phản hồi nhanh" — có nút "Chi tiết").
//
// Ghi chú kiểm duyệt của Zalo ghi rõ: "mẫu thông báo hóa đơn, không quảng
// cáo, KHÔNG MÃ QR BARCODE" — nên mã QR thanh toán KHÔNG được nằm trong tin
// ZNS này. QR sẽ gửi ở tin tư vấn riêng sau khi người thuê bấm "Chi tiết"
// (xem docs/DECISIONS.md Đợt 48).
//
// Giới hạn độ dài do Zalo đặt ra cho từng tham số (lấy từ bảng "Tham số"
// trong trang chi tiết template): ten_nha/ten_phong tối đa 30 ký tự, các
// tham số số tiền/số lượng tối đa 20 ký tự.

interface UtilityLine {
  utilityType: "electricity" | "water";
  usageAmount: number | null;
  totalAmount: number;
}

interface FeeLine {
  name?: string;
  amount?: number;
}

export interface ZnsInvoice {
  house_name: string;
  room_nos: string[];
  period_start: string;
  rent_amount: number;
  utility_lines: UtilityLine[] | null;
  service_fee_amount: number | null;
  recurring_fees: FeeLine[] | null;
  other_fees: FeeLine[] | null;
  total_amount: number;
}

function truncate(value: string, maxLength: number): string {
  return value.length <= maxLength ? value : `${value.slice(0, maxLength - 1)}…`;
}

// Tham số kiểu "Số lượng / Số tiền" của Zalo: gửi CHỮ SỐ THUẦN, không chấm/phẩy
// phân cách — Zalo tự định dạng lúc hiển thị cho người nhận.
function plainNumber(value: number | null | undefined): string {
  return String(Math.round(value ?? 0));
}

function sumUtility(
  lines: UtilityLine[] | null,
  type: "electricity" | "water",
  field: "usageAmount" | "totalAmount",
): number {
  return (lines ?? [])
    .filter((line) => line.utilityType === type)
    .reduce((sum, line) => sum + (line[field] ?? 0), 0);
}

function sumFees(fees: FeeLine[] | null): number {
  return (fees ?? []).reduce((sum, fee) => sum + (fee.amount ?? 0), 0);
}

/**
 * `so_ky` là tham số kiểu "Thời gian" của Zalo. Template khai báo giá trị mẫu
 * dạng "09/2026" (tháng/năm) nên gửi đúng định dạng đó. CHƯA verify thật với
 * Zalo — nếu Zalo báo lỗi định dạng ngày thì đổi sang "dd/MM/yyyy" (định dạng
 * trong đoạn "Mẫu code ví dụ" Zalo tự sinh ra), chỉ cần sửa đúng hàm này.
 */
function periodLabel(periodStart: string): string {
  const d = new Date(`${periodStart}T00:00:00Z`);
  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
  return `${mm}/${d.getUTCFullYear()}`;
}

export function buildZnsInvoiceData(invoice: ZnsInvoice): Record<string, string> {
  const otherFees = (invoice.service_fee_amount ?? 0) +
    sumFees(invoice.recurring_fees) +
    sumFees(invoice.other_fees);

  return {
    ten_nha: truncate(invoice.house_name, 30),
    ten_phong: truncate((invoice.room_nos ?? []).join(", "), 30),
    so_ky: periodLabel(invoice.period_start),
    tien_phong: plainNumber(invoice.rent_amount),
    so_kwh: plainNumber(sumUtility(invoice.utility_lines, "electricity", "usageAmount")),
    tien_dien: plainNumber(sumUtility(invoice.utility_lines, "electricity", "totalAmount")),
    so_khoi_nuoc: plainNumber(sumUtility(invoice.utility_lines, "water", "usageAmount")),
    tien_nuoc: plainNumber(sumUtility(invoice.utility_lines, "water", "totalAmount")),
    phi_khac: plainNumber(otherFees),
    tong_cong: plainNumber(invoice.total_amount),
  };
}

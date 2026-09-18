// _shared/zns_invoice.ts
//
// Map 1 hoá đơn (`tb_invoice`) sang đúng 13 tham số của mẫu ZBS "Hóa đơn định
// kỳ" — **ID `638179`**, gửi qua OA "Townsoft Vina - BizTown", nút thao tác
// "Chi tiết hóa đơn" mở Zalo Mini App (+0đ).
//
// Thay cho mẫu cũ `636461` (10 tham số): mẫu đó thiếu cặp định danh khách
// hàng nên Zalo TỪ CHỐI với mã `[CT_13]` — bắt buộc phải có TÊN KHÁCH HÀNG
// kèm một MÃ (đơn hàng/khách hàng/hợp đồng), mỗi tham số có chữ dẫn phía
// trước. Nay thêm `ten_khach_hang` + `ma_hoa_don`, và `ma_tra_cuu` cho nút
// CTA (xem docs/DECISIONS.md Đợt 66).
//
// Zalo CẤM mã QR trong mẫu ZBS — đó là lý do dùng Mini App: người thuê bấm
// nút, Mini App đọc `?code=<ma_tra_cuu>` rồi hiện ảnh hoá đơn kèm QR.
//
// Giới hạn và KIỂU DỮ LIỆU lấy từ bảng "Tham số" trong trang chi tiết mẫu:
//   string : ten_nha(30) ten_phong(30) ten_khach_hang(30) ma_hoa_don(30)
//            ma_tra_cuu(URL 200)
//   date   : so_ky(20)
//   number : tien_phong so_kwh tien_dien so_khoi_nuoc tien_nuoc phi_khac
//            tong_cong  (đều 20)
//
// ⚠️ 7 tham số kiểu `number` phải gửi đi là SỐ trong JSON, không bọc nháy.
// Bản trước trả mọi giá trị dạng chuỗi — cảnh báo này đã ghi ở
// `docs/ZALO-MESSAGING.md` mục 0 từ 15/09/2026, nay mới có mẫu thật để chốt.

import type { ZnsParamValue } from "./zalo.ts";

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
  tenant_name: string | null;
  public_code: string | null;
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

// Tham số kiểu "Số lượng / Số tiền" khai `number` trong mẫu — trả về số
// nguyên thật, để Zalo tự định dạng dấu phân cách lúc hiển thị.
function plainNumber(value: number | null | undefined): number {
  return Math.round(value ?? 0);
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

export function buildZnsInvoiceData(
  invoice: ZnsInvoice,
): Record<string, ZnsParamValue> {
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
    ten_khach_hang: truncate(invoice.tenant_name ?? "", 30),
    ma_hoa_don: invoice.public_code ?? "",
    // Cùng giá trị với `ma_hoa_don` nhưng PHẢI là tham số riêng: Zalo quy định
    // "các tham số trong CTA phải có tên khác với tham số trong nội dung".
    // Mã chỉ gồm A-Z và 0-9 nên không cần mã hoá URL.
    ma_tra_cuu: invoice.public_code ?? "",
  };
}

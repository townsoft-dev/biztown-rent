// _shared/invoice_message.ts
//
// Dựng nội dung SMS/Zalo gửi Tenant cho 1 hoá đơn — bản TypeScript, ĐỒNG BỘ
// với `src/lib/core/invoice_message.dart` (Flutter, dùng ở B-05 gửi đơn lẻ).
// Dùng ở đây cho `generate-invoice` (mode "batchSend" — tạo + gửi hàng loạt
// chạy hẳn phía backend, xem docs/DECISIONS.md 2026-09-14).
//
// BR-NOTI-07: nội dung LUÔN tiếng Việt, không phụ thuộc ngôn ngữ UI.

const VN_BANKS: { bin: string; name: string }[] = [
  { bin: "970436", name: "Vietcombank" },
  { bin: "970415", name: "VietinBank" },
  { bin: "970418", name: "BIDV" },
  { bin: "970405", name: "Agribank" },
  { bin: "970407", name: "Techcombank" },
  { bin: "970416", name: "ACB" },
  { bin: "970422", name: "MB Bank" },
  { bin: "970432", name: "VPBank" },
  { bin: "970423", name: "TPBank" },
  { bin: "970403", name: "Sacombank" },
  { bin: "970437", name: "HDBank" },
  { bin: "970443", name: "SHB" },
  { bin: "970441", name: "VIB" },
  { bin: "970448", name: "OCB" },
  { bin: "970426", name: "MSB" },
  { bin: "970440", name: "SeABank" },
  { bin: "970431", name: "Eximbank" },
];

function bankByBin(bin: string | null | undefined) {
  if (!bin) return null;
  return VN_BANKS.find((b) => b.bin === bin) ?? null;
}

function formatVndNumber(n: number): string {
  return Math.round(n).toLocaleString("en-US");
}

function formatDdMm(dateStr: string): string {
  const d = new Date(dateStr + "T00:00:00Z");
  const dd = String(d.getUTCDate()).padStart(2, "0");
  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
  return `${dd}/${mm}`;
}

function formatDdMmYyyy(dateStr: string): string {
  const d = new Date(dateStr + "T00:00:00Z");
  const dd = String(d.getUTCDate()).padStart(2, "0");
  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
  return `${dd}/${mm}/${d.getUTCFullYear()}`;
}

export function buildInvoiceSmsMessage(
  invoice: { room_nos: string[]; period_start: string; period_end: string; total_amount: number; due_date: string },
  house: { bank_bin?: string | null; bank_account_number?: string | null; bank_account_name?: string | null } | null,
): string {
  const bank = bankByBin(house?.bank_bin);
  const rooms = (invoice.room_nos ?? []).join(", ");
  const period = `${formatDdMm(invoice.period_start)}–${formatDdMmYyyy(invoice.period_end)}`;
  const amount = `${formatVndNumber(invoice.total_amount)} VND`;
  const due = formatDdMmYyyy(invoice.due_date);
  const payTo = bank && house?.bank_account_number
    ? ` Chuyển khoản ${bank.name} ${house.bank_account_number}${house.bank_account_name ? ` (${house.bank_account_name})` : ""}.`
    : "";
  return `BizTown Rent Manager: Hoá đơn phòng ${rooms}, kỳ ${period} là ${amount}.${payTo} Hạn thanh toán ${due}.`;
}

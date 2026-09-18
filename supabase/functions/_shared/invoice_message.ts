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

export function bankByBin(bin: string | null | undefined) {
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

/// Nội dung SMS hoá đơn gửi hàng loạt (B-03 → `generate-invoice` mode
/// "batchSend"). PHẢI giống hệt bản gửi đơn lẻ ở
/// `src/lib/core/invoice_message.dart` — đọc giải thích ngân sách ký tự ở đó
/// trước khi sửa một ký tự nào trong chuỗi dưới đây. Tin dài ĐÚNG 160 ký tự,
/// tức 1 đoạn SMS; thêm bất cứ thứ gì là thành 2 đoạn và đắt gấp đôi.
export function buildInvoiceSmsMessage(
  invoice: { period_start: string; public_code?: string | null },
): string {
  const ky = invoice.period_start.slice(5, 7) + "/" +
    invoice.period_start.slice(2, 4);
  const host = (Deno.env.get("SUPABASE_URL") ?? "").replace(/^https?:\/\//, "");
  const link = `${host}/functions/v1/i/${invoice.public_code ?? ""}`;
  return `Quy khach da den thoi gian bao tri lan ${ky} xe ${link}. ` +
    `Vui long lien he BT de duoc huong dan. Tran trong.`;
}

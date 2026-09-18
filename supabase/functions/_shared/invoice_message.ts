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
/// "batchSend"). PHẢI giống hệt bản gửi đơn lẻ ở `src/lib/core/invoice_message.dart`
/// — cùng một mẫu, cùng một brandname.
///
/// Bản trước 18/09/2026 dựng một câu hoàn toàn khác ("BizTown Rent Manager:
/// Hoá đơn phòng ..."), hỏng hai đường cùng lúc:
///   1. Không khớp mẫu của brandname mượn "Baotrixemay" → eSMS trả
///      `CodeResult 146 — Sai template`, không tin nào ra khỏi hệ thống.
///   2. Viết CÓ DẤU và có dấu gạch ngang `–` (U+2013) → bị đẩy sang UCS-2,
///      70 ký tự/đoạn thay vì 160, tiền tin nhắn tăng gấp bội. Đây đúng là cái
///      bẫy đã ghi ở `docs/SMS-HOA-DON.md` mục 6.1 mà chính chỗ này vẫn dính.
///
/// Tham số `_house` giữ lại cho khỏi phải sửa nơi gọi; mẫu brandname không có
/// chỗ nhét thông tin ngân hàng — người thuê xem trong ảnh hoá đơn mở từ link.
export function buildInvoiceSmsMessage(
  invoice: {
    room_nos: string[];
    period_start: string;
    total_amount: number;
    due_date: string;
    public_code?: string | null;
  },
  _house?: unknown,
): string {
  const ky = invoice.period_start.slice(5, 7) + "/" +
    invoice.period_start.slice(0, 4);
  const host = (Deno.env.get("SUPABASE_URL") ?? "").replace(/^https?:\/\//, "");
  const link = invoice.public_code
    ? `${host}/functions/v1/invoice/${invoice.public_code}`
    : host;
  const phong = (invoice.room_nos ?? []).join(",");
  const tien = formatVndNumber(invoice.total_amount);
  const han = formatDdMm(invoice.due_date);
  let tomTat = `BizTown P${phong} ${tien}d han ${han}`;
  if (tomTat.length > 50) tomTat = `BizTown ${tien}d han ${han}`;

  return `Quy khach da den thoi gian bao tri lan ${ky} xe ${link}. ` +
    `Vui long lien he ${tomTat} de duoc huong dan. Tran trong.`;
}

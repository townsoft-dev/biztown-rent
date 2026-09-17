// invoice-qr
//
// Trang xem hoá đơn cho NGƯỜI THUÊ, mở bằng đúng một đường dẫn sạch:
//
//   GET /functions/v1/invoice-qr/<ma_tra_cuu>
//
// Vì sao KHÔNG dùng tham số truy vấn (`?code=...`): test thật 17/09/2026 cho
// thấy nhà mạng CHẶN tin nhắn chứa link có `?` hoặc `&` — gửi 3 biến thể tới
// cùng một số, link có tham số thất bại, link đường dẫn sạch tới nơi và bấm
// được. Xem docs/SMS-HOA-DON.md mục 6.4.
//
// Khác `invoice-public` (trả JSON cho trang tĩnh gọi bằng AJAX, chỉ nhận POST):
// hàm này trả thẳng HTML để người thuê bấm link trong SMS là xem được ngay,
// không cần trang tĩnh và không cần tên miền riêng.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { buildVietQrPayload } from "../_shared/vietqr.ts";
import QRCode from "https://esm.sh/qrcode@1.5.3";

const CODE_PATTERN = /^[0-9A-HJ-NP-TV-Z]{12}$/;

function notFound(): Response {
  return new Response("Khong tim thay hoa don", {
    status: 404,
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}

const vnd = (n: number) => new Intl.NumberFormat("vi-VN").format(Math.round(n));
const day = (s: string) => s.split("-").reverse().join("/");

function esc(s: string): string {
  return s.replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!)
  );
}


/** CRC32 cho khung dữ liệu PNG. */
function crc32(buf: Uint8Array): number {
  let c = ~0;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xEDB88320 & -(c & 1));
  }
  return ~c >>> 0;
}

function pngChunk(type: string, data: Uint8Array): Uint8Array {
  const out = new Uint8Array(12 + data.length);
  const dv = new DataView(out.buffer);
  dv.setUint32(0, data.length);
  for (let i = 0; i < 4; i++) out[4 + i] = type.charCodeAt(i);
  out.set(data, 8);
  dv.setUint32(8 + data.length, crc32(out.subarray(4, 8 + data.length)));
  return out;
}

/** Vẽ ma trận QR thành ảnh PNG đen trắng, không cần canvas. */
async function qrToPng(matrix: { size: number; data: Uint8Array }, scale: number, quiet: number) {
  const px = (matrix.size + quiet * 2) * scale;
  // Mỗi hàng PNG bắt đầu bằng 1 byte filter (0 = None), sau đó là 1 byte/pixel
  // (ảnh xám 8-bit): 0 = đen, 255 = trắng.
  const raw = new Uint8Array((px + 1) * px);
  raw.fill(255);
  for (let y = 0; y < px; y++) raw[y * (px + 1)] = 0;
  for (let my = 0; my < matrix.size; my++) {
    for (let mx = 0; mx < matrix.size; mx++) {
      if (!matrix.data[my * matrix.size + mx]) continue;
      for (let dy = 0; dy < scale; dy++) {
        const y = (my + quiet) * scale + dy;
        const rowStart = y * (px + 1) + 1 + (mx + quiet) * scale;
        raw.fill(0, rowStart, rowStart + scale);
      }
    }
  }
  const deflated = new Uint8Array(
    await new Response(
      new Blob([raw]).stream().pipeThrough(new CompressionStream("deflate")),
    ).arrayBuffer(),
  );
  const ihdr = new Uint8Array(13);
  const dv = new DataView(ihdr.buffer);
  dv.setUint32(0, px);
  dv.setUint32(4, px);
  ihdr[8] = 8;  // bit depth
  ihdr[9] = 0;  // colour type 0 = greyscale
  const parts = [
    new Uint8Array([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
    pngChunk("IHDR", ihdr),
    pngChunk("IDAT", deflated),
    pngChunk("IEND", new Uint8Array(0)),
  ];
  const png = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
  let off = 0;
  for (const p of parts) { png.set(p, off); off += p.length; }
  return png;
}

export default {
  // "none": người thuê không có tài khoản nên không gửi được JWT nào.
  fetch: withSupabase({ auth: ["none"] }, async (req, ctx) => {
    if (req.method !== "GET") return notFound();

    // Mã nằm ở đoạn cuối đường dẫn: /functions/v1/invoice-qr/<ma>
    const code = new URL(req.url).pathname.split("/").filter(Boolean).pop() ?? "";
    if (!CODE_PATTERN.test(code)) return notFound();

    const { data: invoice } = await ctx.supabaseAdmin
      .from("tb_invoice")
      .select(
        "house_id, house_name, room_nos, tenant_name, period_start, period_end, due_date, total_amount",
      )
      .eq("public_code", code)
      .maybeSingle();
    if (!invoice) return notFound();

    const { data: house } = await ctx.supabaseAdmin
      .from("tb_house")
      .select("bank_bin, bank_account_number, bank_account_name")
      .eq("id", invoice.house_id)
      .maybeSingle();

    const rooms = ((invoice.room_nos ?? []) as string[]).join(", ");
    const total = Math.round(Number(invoice.total_amount));

    // Luôn sinh lại QR từ tài khoản HIỆN TẠI của chủ nhà — cùng lý do đã ghi ở
    // `invoice-public`: chuỗi QR lưu sẵn trong hoá đơn có thể trỏ tới tài khoản
    // chủ trọ đã đổi, người thuê quét là chuyển nhầm tiền.
    const qr = house?.bank_bin && house?.bank_account_number
      ? buildVietQrPayload({
        bankBin: house.bank_bin,
        accountNumber: house.bank_account_number,
        amount: total,
        message: code,
        merchantName: house.bank_account_name ?? undefined,
      })
      : null;

    if (!qr) return notFound();

    // Trả thẳng ẢNH QR dạng PNG.
    //
    // Đã thử 2 cách trước và đều hỏng trên máy thật (17/09/2026):
    //   - Trả trang HTML: cổng Supabase ép về `text/plain` + CSP
    //     `default-src 'none'; sandbox`, trình duyệt hiện mã nguồn rồi tải về
    //     thành file .txt.
    //   - Trả ảnh SVG: `Content-Type` giữ đúng nhưng máy mở ra trắng trơn,
    //     vì SVG là tài liệu nên vẫn dính CSP `sandbox` nói trên.
    // PNG là ảnh thuần, không phải tài liệu, nên không dính CSP.
    const matrix = QRCode.create(qr, { errorCorrectionLevel: "M" }).modules;
    const png = await qrToPng(matrix, 8, 2);

    return new Response(png, {
      headers: {
        "Content-Type": "image/png",
        "Cache-Control": "no-store",
      },
    });
  }),
};

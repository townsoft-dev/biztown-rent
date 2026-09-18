// invoice
//
// ẢNH hoá đơn chi tiết cho NGƯỜI THUÊ, mở bằng đúng một đường dẫn sạch:
//
//   GET /functions/v1/invoice/<ma_tra_cuu>
//
// Thay cho `invoice-qr` (chỉ trả mỗi ô mã QR trơ trọi — dungtv nhận xét
// 17/09/2026 là "cùi"). Dựng theo frame Figma `MOCK-IMG` (node `526:2485`).
//
// Không dùng tham số truy vấn vì nhà mạng chặn tin nhắn chứa `?`/`&`
// (xem docs/SMS-HOA-DON.md mục 6.4).
import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { initWasm, Resvg } from "npm:@resvg/resvg-wasm@2.6.2";
import QRCode from "https://esm.sh/qrcode@1.5.3";
import { buildVietQrPayload } from "../_shared/vietqr.ts";
import { bankByBin } from "../_shared/invoice_message.ts";
import { buildInvoiceSvg, type Fee, type InvoiceImageData } from "./render.ts";

const CODE_PATTERN = /^[0-9A-HJ-NP-TV-Z]{12}$/;

// wasm + font tải một lần rồi giữ lại trong isolate: lần gọi đầu ~3s, các lần
// sau ~0,8s (đo thật 18/09/2026).
let wasmReady = false;
let fontBuffers: Uint8Array[] | null = null;

async function boot() {
  if (!wasmReady) {
    await initWasm(
      await fetch("https://unpkg.com/@resvg/resvg-wasm@2.6.2/index_bg.wasm"),
    );
    wasmReady = true;
  }
  if (!fontBuffers) {
    // Be Vietnam Pro — font Google có đủ dấu tiếng Việt và chữ "đ".
    //
    // PHẢI nạp CẢ HAI nét 400 và 700. Bản đầu chỉ lấy link đầu tiên trong CSS
    // (nét thường) nên mọi chữ `font-weight="700"` vẫn ra nét thường —
    // resvg không tự làm đậm giả, thiếu file là thiếu luôn nét đậm.
    const css = await fetch(
      "https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;700",
      { headers: { "user-agent": "Mozilla/5.0" } },
    ).then((r) => r.text());
    const urls = [...css.matchAll(/url\((https:[^)]+)\)/g)].map((m) => m[1]);
    if (urls.length < 2) {
      throw new Error(`Google Fonts chi tra ve ${urls.length} file font`);
    }
    fontBuffers = await Promise.all(
      urls.map(async (u) => new Uint8Array(await (await fetch(u)).arrayBuffer())),
    );
  }
}

function notFound(): Response {
  return new Response("Khong tim thay hoa don", {
    status: 404,
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}

type UtilityLine = {
  utilityType: "electricity" | "water";
  usageAmount: number | null;
  totalAmount: number | null;
};

export default {
  // "none": người thuê không có tài khoản nên không gửi được JWT nào.
  fetch: withSupabase({ auth: ["none"] }, async (req, ctx) => {
    if (req.method !== "GET") return notFound();

    const code = new URL(req.url).pathname.split("/").filter(Boolean).pop() ?? "";
    if (!CODE_PATTERN.test(code)) return notFound();

    const { data: invoice } = await ctx.supabaseAdmin
      .from("tb_invoice")
      .select(
        "house_id, house_name, room_nos, tenant_name, period_start, due_date, status, rent_amount, utility_lines, service_fee_amount, recurring_fees, other_fees, total_amount, public_code",
      )
      .eq("public_code", code)
      .maybeSingle();
    if (!invoice) return notFound();

    const { data: house } = await ctx.supabaseAdmin
      .from("tb_house")
      .select("bank_bin, bank_account_number, bank_account_name")
      .eq("id", invoice.house_id)
      .maybeSingle();

    const total = Math.round(Number(invoice.total_amount));

    // Luôn sinh lại QR từ tài khoản HIỆN TẠI của chủ nhà — chuỗi lưu sẵn trong
    // hoá đơn có thể trỏ tới tài khoản đã đổi, người thuê quét là chuyển nhầm.
    const qrPayload = house?.bank_bin && house?.bank_account_number
      ? buildVietQrPayload({
        bankBin: house.bank_bin,
        accountNumber: house.bank_account_number,
        amount: total,
        message: code,
        merchantName: house.bank_account_name ?? undefined,
      })
      : null;

    const lines = (invoice.utility_lines ?? []) as UtilityLine[];
    const gop = (type: "electricity" | "water") => {
      const of = lines.filter((l) => l.utilityType === type);
      if (of.length === 0) return null;
      const usage = of.every((l) => l.usageAmount != null)
        ? of.reduce((n, l) => n + Number(l.usageAmount), 0)
        : null;
      return { usage, amount: of.reduce((n, l) => n + Number(l.totalAmount ?? 0), 0) };
    };

    const fees: Fee[] = [];
    if (Number(invoice.service_fee_amount ?? 0) > 0) {
      fees.push({ name: "Phí dịch vụ", amount: Number(invoice.service_fee_amount) });
    }
    for (
      const f of [...(invoice.recurring_fees ?? []), ...(invoice.other_fees ?? [])] as Fee[]
    ) {
      fees.push({ name: f.name, amount: Number(f.amount) });
    }

    let qrMatrix: InvoiceImageData["qrMatrix"] = null;
    if (qrPayload) {
      const m = QRCode.create(qrPayload, { errorCorrectionLevel: "M" }).modules;
      qrMatrix = { size: m.size, data: m.data };
    }

    const svg = buildInvoiceSvg({
      houseName: invoice.house_name ?? "",
      rooms: ((invoice.room_nos ?? []) as string[]).join(", "),
      tenantName: invoice.tenant_name ?? "",
      periodStart: invoice.period_start,
      dueDate: invoice.due_date,
      invoiceCode: invoice.public_code ?? code,
      rent: Number(invoice.rent_amount ?? 0),
      electricity: gop("electricity"),
      water: gop("water"),
      fees,
      total,
      paid: invoice.status === "Collected",
      bank: house?.bank_account_number
        ? {
          name: bankByBin(house.bank_bin)?.name ?? "",
          accountNumber: house.bank_account_number,
          accountName: house.bank_account_name ?? "",
        }
        : null,
      qrMatrix,
    });

    await boot();
    // zoom 2: ảnh 750px ngang, nét chữ mịn khi người thuê phóng to trên điện thoại.
    const png = new Resvg(svg, {
      font: { fontBuffers: fontBuffers!, defaultFontFamily: "Be Vietnam Pro" },
      fitTo: { mode: "zoom", value: 2 },
    }).render().asPng();

    return new Response(png, {
      headers: { "Content-Type": "image/png", "Cache-Control": "no-store" },
    });
  }),
};

// invoice-public
//
// Tra cứu 1 hoá đơn bằng MÃ CÔNG KHAI gửi kèm SMS, KHÔNG cần đăng nhập.
// Người thuê không có tài khoản BizTown (xem docs/CLAUDE.md mục 1) nên đây là
// đường duy nhất để họ xem chi tiết hoá đơn + mã QR thanh toán.
//
// Luồng: SMS `bill.<domain>/<mã>` → trang tĩnh đọc mã trong đường dẫn → gọi
// hàm này → trả JSON → trang tự vẽ bảng + vẽ QR từ chuỗi VietQR.
//
// VÌ SAO qua Edge Function mà không cho trang tĩnh query thẳng bảng: người
// thuê không có JWT, nếu mở policy đọc ẩn danh trên `tb_invoice` thì chỉ cần
// viết sai một điều kiện là lộ hoá đơn của người khác. Đi qua đây thì khoá bí
// mật nằm ở server, và hàm chỉ trả về ĐÚNG 1 hoá đơn khớp mã.
//
// Chống dò mã (xem thêm migration `20260916130000_invoice_lookup_throttle.sql`):
// - Mã 12 ký tự Crockford Base32 = ~1,15 tỷ tỷ tổ hợp, sinh bằng nguồn ngẫu
//   nhiên an toàn mật mã;
// - Đếm số lần TRƯỢT theo IP, vượt ngưỡng thì khoá tạm;
// - Mã sai luôn trả về CÙNG một phản hồi 404, không phân biệt sai định dạng
//   với không tồn tại — nếu phân biệt, kẻ dò biết mình đang đi đúng hướng.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { buildVietQrPayload } from "../_shared/vietqr.ts";

const CODE_PATTERN = /^[0-9A-HJKMNP-TV-Z]{12}$/;

// Ngưỡng chặn: quá 20 lần trượt trong 10 phút từ cùng 1 IP thì khoá.
const FAILURE_WINDOW_MINUTES = 10;
const FAILURE_LIMIT = 20;

const VN_BANKS: Record<string, string> = {
  "970436": "Vietcombank",
  "970415": "VietinBank",
  "970418": "BIDV",
  "970405": "Agribank",
  "970407": "Techcombank",
  "970416": "ACB",
  "970422": "MB Bank",
  "970432": "VPBank",
  "970423": "TPBank",
  "970403": "Sacombank",
  "970437": "HDBank",
  "970443": "SHB",
  "970441": "VIB",
  "970448": "OCB",
  "970426": "MSB",
  "970440": "SeABank",
  "970431": "Eximbank",
};

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type, authorization, apikey",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

/// Mọi trường hợp không tra được đều trả về ĐÚNG phản hồi này — cố ý không
/// nói rõ lý do để không giúp kẻ dò mã thu hẹp phạm vi.
function notFound(): Response {
  return json({ error: "not_found" }, 404);
}

function clientIp(req: Request): string {
  return req.headers.get("cf-connecting-ip") ??
    req.headers.get("x-forwarded-for")?.split(",")[0].trim() ??
    "unknown";
}

interface UtilityLine {
  utilityType: "electricity" | "water";
  previousReading: number | null;
  currentReading: number | null;
  usageAmount: number | null;
  unitPrice: number | null;
  totalAmount: number;
}

function utilitySummary(lines: UtilityLine[], type: "electricity" | "water") {
  const matching = lines.filter((l) => l.utilityType === type);
  if (matching.length === 0) return null;
  const sum = (pick: (l: UtilityLine) => number | null) =>
    matching.reduce((total, l) => total + (pick(l) ?? 0), 0);
  return {
    previousReading: matching.length === 1 ? matching[0].previousReading : null,
    currentReading: matching.length === 1 ? matching[0].currentReading : null,
    usageAmount: sum((l) => l.usageAmount),
    unitPrice: matching[0].unitPrice,
    amount: sum((l) => l.totalAmount),
  };
}

export default {
  // "none": người thuê không có tài khoản nên không thể gửi JWT nào.
  fetch: withSupabase({ auth: ["none"] }, async (req, ctx) => {
    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }
    if (req.method !== "POST") return notFound();

    const ip = clientIp(req);

    // Chặn trước khi tra, để kẻ dò không tốn tài nguyên database của mình.
    const since = new Date(Date.now() - FAILURE_WINDOW_MINUTES * 60_000)
      .toISOString();
    const { count: recentFailures } = await ctx.supabaseAdmin
      .from("tb_invoice_lookup_failure")
      .select("id", { count: "exact", head: true })
      .eq("ip", ip)
      .gte("attempted_at", since);
    if ((recentFailures ?? 0) >= FAILURE_LIMIT) {
      return json({ error: "too_many_requests" }, 429);
    }

    const recordFailure = () =>
      ctx.supabaseAdmin.from("tb_invoice_lookup_failure").insert({ ip });

    let code: unknown;
    try {
      code = (await req.json())?.code;
    } catch {
      await recordFailure();
      return notFound();
    }

    if (typeof code !== "string" || !CODE_PATTERN.test(code)) {
      await recordFailure();
      return notFound();
    }

    const { data: invoice } = await ctx.supabaseAdmin
      .from("tb_invoice")
      .select(
        "house_id, house_name, room_nos, tenant_name, period_start, period_end, due_date, rent_amount, utility_lines, service_fee_amount, recurring_fees, other_fees, total_amount, status",
      )
      .eq("public_code", code)
      .maybeSingle();

    if (!invoice) {
      await recordFailure();
      return notFound();
    }

    const { data: house } = await ctx.supabaseAdmin
      .from("tb_house")
      .select("bank_bin, bank_account_number, bank_account_name")
      .eq("id", invoice.house_id)
      .maybeSingle();

    const lines = (invoice.utility_lines ?? []) as UtilityLine[];
    const rooms = (invoice.room_nos ?? []) as string[];

    // LUÔN sinh lại QR từ tài khoản HIỆN TẠI của chủ nhà, cố ý KHÔNG dùng
    // `invoice.payment_qr_payload` đã lưu.
    //
    // Lý do (phát hiện khi test thật 16/09/2026): chuỗi lưu sẵn là ảnh chụp tại
    // thời điểm tạo hoá đơn, chủ trọ đổi số tài khoản sau đó thì nó KHÔNG được
    // cập nhật. Dữ liệu thật đang có đúng trường hợp này: hoá đơn giữ QR trỏ
    // tới `0071000112233 / LE THI MAI` trong khi nhà đó nay dùng
    // `9697354961 / TRAN VAN DUNG`. Người thuê quét QR cũ là chuyển tiền sang
    // tài khoản không còn dùng — hỏng nghiêm trọng, nên ở đây luôn lấy tài
    // khoản hiện hành.
    const qrPayload = house?.bank_bin && house?.bank_account_number
      ? buildVietQrPayload({
        bankBin: house.bank_bin,
        accountNumber: house.bank_account_number,
        amount: Math.round(Number(invoice.total_amount)),
        message: `Tien nha ${rooms.join(" ")}`.trim(),
        merchantName: house.bank_account_name ?? undefined,
      })
      : null;

    return json({
      houseName: invoice.house_name,
      rooms,
      tenantName: invoice.tenant_name,
      periodStart: invoice.period_start,
      periodEnd: invoice.period_end,
      dueDate: invoice.due_date,
      status: invoice.status,
      lines: {
        rent: Number(invoice.rent_amount),
        electricity: utilitySummary(lines, "electricity"),
        water: utilitySummary(lines, "water"),
        serviceFee: Number(invoice.service_fee_amount ?? 0),
        recurringFees: invoice.recurring_fees ?? [],
        otherFees: invoice.other_fees ?? [],
      },
      totalAmount: Number(invoice.total_amount),
      payment: house?.bank_account_number
        ? {
          bankBin: house.bank_bin,
          bankName: VN_BANKS[house.bank_bin ?? ""] ?? null,
          accountNumber: house.bank_account_number,
          accountName: house.bank_account_name,
          qrPayload,
        }
        : null,
    });
  }),
};

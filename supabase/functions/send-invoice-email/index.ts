// send-invoice-email
//
// Gửi hoá đơn cho người thuê qua EMAIL. dungtv chốt 17/09/2026: hoá đơn có 3
// kênh — SMS (số tiền + link mã QR), Email (mẫu do Hường thiết kế), Zalo (mua
// gói sau, tạm khoá). OTP KHÔNG đổi, vẫn đi SMS.
//
// Vì sao phải có function này: Supabase chỉ tự gửi được email XÁC THỰC TÀI
// KHOẢN (đăng ký, đặt lại mật khẩu), không gửi được email nghiệp vụ. Muốn gửi
// hoá đơn phải tự gọi một nhà cung cấp email.
//
// Nhà cung cấp: **Brevo** (`BREVO_API_KEY`). Chọn vì 2 lý do cụ thể:
//   1. Gửi được NGAY khi CHƯA CÓ TÊN MIỀN — chỉ cần xác thực một địa chỉ Gmail
//      bằng mã 6 số. Resend bắt buộc phải có tên miền nên không dùng được ở
//      thời điểm này (dungtv chưa mua tên miền, 17/09/2026).
//   2. Mức miễn phí rộng hơn: 300 thư/ngày (~9.000/tháng) so với 3.000/tháng
//      của Resend. Dự án cần ~66 thư/tháng nên miễn phí vĩnh viễn.
//
// Vì sao KHÔNG dùng SMTP cho gọn: Edge Function chạy trên Deno Deploy, môi
// trường này **chặn kết nối ra cổng 25 và 587** — đúng 2 cổng SMTP chuẩn — và
// thư viện SMTP cho Deno chạy chập chờn trong Edge Function. Gọi HTTP API là
// đường duy nhất ổn định.
//
// Đổi sang nhà cung cấp khác chỉ phải sửa `sendViaBrevo` bên dưới; mọi thứ còn
// lại (đọc hoá đơn, kiểm quyền, dựng nội dung thư) không phụ thuộc nhà cung cấp.
//
// ⚠️ CHƯA CHẠY ĐƯỢC cho tới khi có đủ 2 secret `BREVO_API_KEY` và
// `INVOICE_EMAIL_FROM` — hàm tự trả lỗi rõ ràng thay vì âm thầm bỏ qua.
//
// Mẫu email: Hường đang thiết kế. `renderInvoiceEmail()` bên dưới là bản tối
// giản để luồng chạy được ngay; khi có mẫu thật thì thay đúng hàm đó, phần còn
// lại không phải sửa.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

interface SendInvoiceEmailRequest {
  invoiceId: string;
}

const vnd = (n: number) => new Intl.NumberFormat("vi-VN").format(Math.round(n));
const day = (s: string) => s.split("-").reverse().join("/");

function esc(s: string): string {
  return s.replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!)
  );
}

/** Bản dựng tối giản — thay bằng mẫu của Hường khi có. */
function renderInvoiceEmail(inv: {
  houseName: string;
  rooms: string;
  tenantName: string;
  periodStart: string;
  periodEnd: string;
  dueDate: string;
  total: number;
  qrUrl: string | null;
}): string {
  return `<!doctype html><html lang="vi"><body style="margin:0;background:#F5F6F9;
 font:15px/1.5 -apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;color:#1B2440">
<div style="max-width:480px;margin:0 auto;padding:16px">
  <div style="background:#fff;border-radius:14px;padding:20px">
    <h1 style="font-size:18px;margin:0 0 4px">Hoá đơn tiền nhà</h1>
    <p style="color:#6B7392;font-size:13px;margin:0 0 16px">
      ${esc(inv.houseName)} &middot; Phòng ${esc(inv.rooms)} &middot; ${esc(inv.tenantName)}
    </p>
    <table style="width:100%;border-collapse:collapse;font-size:14px">
      <tr><td style="padding:6px 0;color:#6B7392">Kỳ</td>
          <td style="padding:6px 0;text-align:right;font-weight:600">${day(inv.periodStart)} - ${day(inv.periodEnd)}</td></tr>
      <tr><td style="padding:6px 0;color:#6B7392">Hạn thanh toán</td>
          <td style="padding:6px 0;text-align:right;font-weight:600">${day(inv.dueDate)}</td></tr>
      <tr><td style="padding:10px 0;color:#6B7392;border-top:1px solid #EDEFF5">Tổng cộng</td>
          <td style="padding:10px 0;text-align:right;font-size:20px;font-weight:700;border-top:1px solid #EDEFF5">${vnd(inv.total)}đ</td></tr>
    </table>
  </div>
  ${
    inv.qrUrl
      ? `<div style="background:#fff;border-radius:14px;padding:20px;margin-top:12px;text-align:center">
    <img src="${inv.qrUrl}" alt="Ma QR chuyen khoan" width="220" height="220" style="display:block;margin:0 auto">
    <p style="color:#6B7392;font-size:12px;margin:8px 0 0">Quét mã để chuyển khoản</p>
  </div>`
      : ""
  }
</div></body></html>`;
}

async function sendViaBrevo(to: string, subject: string, html: string) {
  const key = Deno.env.get("BREVO_API_KEY");
  const from = Deno.env.get("INVOICE_EMAIL_FROM");
  if (!key || !from) {
    throw new Error(
      "Thiếu secret BREVO_API_KEY hoặc INVOICE_EMAIL_FROM — chưa cấu hình gửi email",
    );
  }
  const res = await fetch("https://api.brevo.com/v3/smtp/email", {
    method: "POST",
    headers: {
      "api-key": key,
      "content-type": "application/json",
      accept: "application/json",
    },
    body: JSON.stringify({
      sender: { email: from, name: Deno.env.get("INVOICE_EMAIL_FROM_NAME") ?? "BizTown" },
      to: [{ email: to }],
      subject,
      htmlContent: html,
    }),
  });
  if (!res.ok) {
    throw new Error(`Brevo tu choi: ${res.status} ${await res.text()}`);
  }
  return (await res.json())?.messageId ?? null;
}

export default {
  // "user": app gọi bằng JWT chủ nhà/quản lý; `ctx.supabase` (có RLS) tự chặn
  // nếu người gọi không có quyền trên nhà của hoá đơn này.
  fetch: withSupabase({ auth: ["user", "secret"] }, async (req, ctx) => {
    const { invoiceId }: SendInvoiceEmailRequest = await req.json();
    if (!invoiceId) return Response.json({ error: "Thiếu invoiceId" }, { status: 400 });

    // Đọc qua client CÓ RLS để kiểm tra quyền, không dùng admin.
    const { data: invoice } = await ctx.supabase
      .from("tb_invoice")
      .select(
        "id, contract_id, house_name, room_nos, tenant_name, period_start, period_end, due_date, total_amount, public_code",
      )
      .eq("id", invoiceId)
      .maybeSingle();
    if (!invoice) return Response.json({ error: "Forbidden" }, { status: 403 });

    const { data: contract } = await ctx.supabase
      .from("tb_contract").select("tenant_id").eq("id", invoice.contract_id).maybeSingle();
    const { data: tenant } = await ctx.supabase
      .from("tb_tenant").select("mail, full_name").eq("id", contract?.tenant_id).maybeSingle();

    const to = (tenant?.mail ?? "").trim();
    if (!to) return Response.json({ error: "Người thuê chưa có email" }, { status: 400 });

    const rooms = ((invoice.room_nos ?? []) as string[]).join(", ");
    const qrUrl = invoice.public_code
      ? `${Deno.env.get("SUPABASE_URL")}/functions/v1/invoice-qr/${invoice.public_code}`
      : null;

    const html = renderInvoiceEmail({
      houseName: invoice.house_name ?? "",
      rooms,
      tenantName: invoice.tenant_name ?? tenant?.full_name ?? "",
      periodStart: invoice.period_start,
      periodEnd: invoice.period_end,
      dueDate: invoice.due_date,
      total: Number(invoice.total_amount),
      qrUrl,
    });

    try {
      const id = await sendViaBrevo(
        to,
        `Hoa don tien nha phong ${rooms} - ky ${day(invoice.period_start)}`,
        html,
      );
      return Response.json({ sent: true, channel: "email", to, messageId: id });
    } catch (e) {
      return Response.json({ error: `${e}` }, { status: 500 });
    }
  }),
};

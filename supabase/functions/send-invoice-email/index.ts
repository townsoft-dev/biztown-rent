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
// Dùng lại bảng tra tên ngân hàng đã có, không chép thêm bản thứ ba.
import { bankByBin } from "../_shared/invoice_message.ts";

interface UtilityLine {
  utilityType: "electricity" | "water";
  usageAmount: number | null;
  totalAmount: number | null;
}

interface SendInvoiceEmailRequest {
  invoiceId: string;
}

const vnd = (n: number) => new Intl.NumberFormat("vi-VN").format(Math.round(n));
const day = (s: string) => s.split("-").reverse().join("/");
// Kỳ hoá đơn LUÔN trọn 1 tháng dương lịch (BR-BILL-07) nên tiêu đề thư chỉ
// nêu tháng/năm. Bản đầu dùng `day()` nên chủ đề ra "ky 01/09/2026" — người
// thuê đọc tưởng là hạn ngày 01 (thấy khi test thật 17/09/2026).
const monthYear = (s: string) => {
  const [y, m] = s.split("-");
  return `${m}/${y}`;
};

function esc(s: string): string {
  return s.replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!)
  );
}

/// Mẫu thư theo thiết kế Figma "MOCK-EMAIL" của Hường (17/09/2026). Màu lấy
/// bằng cách đọc pixel từ bản render, không ước lượng bằng mắt:
///   navy `#1E2A51` · cam `#F29437` · nền tổng `#FDECE1` · viền `#EBEEF3`
///   nền thẻ `#F6F8FA` · đỏ hạn thanh toán `#B64D43`
///
/// Vì sao viết bằng `<table>` và CSS inline: Gmail/Outlook **cắt bỏ thẻ
/// `<style>`** và không hiểu flex/grid. Cũng vì vậy không dùng JavaScript,
/// không dùng font tải về, và mọi thông tin quan trọng (số tiền, số tài khoản)
/// đều là CHỮ chứ không nằm trong ảnh — nhiều hộp thư chặn ảnh mặc định.
///
/// Logo dựng bằng chữ thay vì ảnh, cùng lý do: ảnh bị chặn thì tiêu đề thư
/// trắng trơn.
interface InvoiceEmailData {
  houseName: string;
  rooms: string;
  tenantName: string;
  periodStart: string;
  periodEnd: string;
  dueDate: string;
  rent: number;
  electricity: { usage: number | null; amount: number } | null;
  water: { usage: number | null; amount: number } | null;
  fees: { name: string; amount: number }[];
  total: number;
  invoiceCode: string | null;
  qrUrl: string | null;
  bank: { name: string; accountNumber: string; accountName: string } | null;
}

const NAVY = "#1E2A51";
const CAM = "#F29437";
const VIEN = "#EBEEF3";
const MO = "#6B7392";

function hang(label: string, value: string, dam = true): string {
  return `<tr>
    <td style="padding:7px 0;color:${MO};font-size:13px">${label}</td>
    <td style="padding:7px 0;text-align:right;font-size:13px;color:${NAVY};font-weight:${dam ? 700 : 400}">${value}</td>
  </tr>`;
}

function renderInvoiceEmail(d: InvoiceEmailData): string {
  const ky = `${day(d.periodStart)} - ${day(d.periodEnd)}`;
  const dongPhi = d.fees.map((f) =>
    `<tr><td style="padding:5px 0 5px 16px;color:${MO};font-size:13px">&ndash; ${esc(f.name)}</td>
     <td style="padding:5px 0;text-align:right;font-size:13px;color:${NAVY};font-weight:700">${vnd(f.amount)}đ</td></tr>`
  ).join("");

  return `<!doctype html><html lang="vi"><body style="margin:0;padding:0;background:#EBEEF3">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#EBEEF3;padding:16px 0">
<tr><td align="center">
<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="width:600px;max-width:100%;background:#ffffff;border-radius:8px;overflow:hidden;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif">

  <tr><td style="height:4px;background:${CAM};font-size:0;line-height:0">&nbsp;</td></tr>

  <tr><td style="background:${NAVY};padding:40px 32px 34px">
    <!-- ⚠️ Đây là LOCKUP CŨ dựng lại, đang dùng CÓ CHỦ Ý — đừng thay bằng bộ
         logo mới của mr Han: logo mới là ô vuông nền navy trùng màu nền header
         này nên tan vào nền. dungtv chốt 18/09/2026 tạm giữ; gỡ khi có bản
         logo nền trong suốt (docs/DECISIONS.md Đợt 65).

         Cụm logo (biểu tượng 3 cột + chữ) dựng bằng ô bảng có nền màu thay vì
         ảnh: nhiều hộp thư chặn ảnh mặc định, dùng ảnh thì logo biến mất hẳn.
         Hình học + màu đo từng pixel trên bản render Figma MOCK-EMAIL (node
         584:2524) va doi chieu design/Logo/biztown-rent-manager-lockup-on-navy.svg:
         3 cột bo góc cao 31/47/38px, ĐỨNG TRÊN một thanh ngang xám nhô ra 2px
         mỗi bên — bản đầu 17/09/2026 thiếu thanh ngang này và xếp chữ xuống
         dưới biểu tượng nên dungtv báo "không giống Figma". -->
    <table role="presentation" cellpadding="0" cellspacing="0" style="border-collapse:collapse">
      <tr>
        <td style="vertical-align:middle;padding-right:40px">
          <table role="presentation" cellpadding="0" cellspacing="0" style="border-collapse:collapse">
            <tr>
              <td style="width:2px;font-size:0;line-height:0">&nbsp;</td>
              <td style="vertical-align:bottom;padding-right:6px">
                <div style="width:16px;height:31px;background:#B0B5C3;border-radius:3px;font-size:0;line-height:0">&nbsp;</div></td>
              <td style="vertical-align:bottom;padding-right:6px">
                <div style="width:16px;height:47px;background:#FFFFFF;border-radius:3px;font-size:0;line-height:0">&nbsp;</div></td>
              <td style="vertical-align:bottom">
                <div style="width:16px;height:38px;background:${CAM};border-radius:3px;font-size:0;line-height:0">&nbsp;</div></td>
              <td style="width:2px;font-size:0;line-height:0">&nbsp;</td>
            </tr>
            <tr><td colspan="5" style="font-size:0;line-height:0">
              <div style="width:64px;height:5px;background:#80889F;border-radius:2px;font-size:0;line-height:0">&nbsp;</div></td></tr>
          </table>
        </td>
        <td style="vertical-align:middle">
          <!-- Gạch cam phải rộng ĐÚNG bằng chữ "BizTown" (Figma). Không đặt
               width cố định vì mỗi hộp thư dựng chữ bằng một font khác nhau nên
               bề ngang chữ lệch đi — để bảng tự co theo chữ rồi cho gạch
               width:100% thì nó luôn khớp. -->
          <table role="presentation" cellpadding="0" cellspacing="0" style="border-collapse:collapse">
            <tr><td style="font-size:42px;line-height:44px;font-weight:700;color:#ffffff;letter-spacing:-1px;white-space:nowrap">Biz<span style="color:#8695B3;font-weight:400">Town</span></td></tr>
            <tr><td style="padding:10px 0 13px;font-size:0;line-height:0">
              <div style="width:100%;height:7px;background:${CAM};font-size:0;line-height:0">&nbsp;</div></td></tr>
            <tr><td style="font-size:15px;line-height:15px;letter-spacing:2.5px;color:#98A8C3;white-space:nowrap">RENT MANAGER</td></tr>
          </table>
        </td>
      </tr>
    </table>
    <div style="font-size:17px;font-weight:700;color:#ffffff;margin-top:28px">Hoá đơn tiền trọ hàng tháng của bạn</div>
    <div style="font-size:12px;color:#98A8C3;margin-top:5px">Xem chi tiết bên dưới hoặc thanh toán trực tiếp qua email</div>
  </td></tr>

  <tr><td style="padding:26px 32px 8px">
    <div style="font-size:15px;font-weight:700;color:${NAVY}">Xin chào ${esc(d.tenantName)},</div>
    <div style="font-size:13px;color:#4A5372;line-height:1.6;margin-top:8px">
      Hoá đơn tiền trọ kỳ ${ky} của bạn tại ${esc(d.houseName)} &middot; Phòng ${esc(d.rooms)}
      đã sẵn sàng. Vui lòng xem chi tiết bên dưới và thanh toán trước hạn.
    </div>
  </td></tr>

  <tr><td style="padding:14px 32px 0">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F6F8FA;border-radius:8px">
      <tr><td style="padding:14px 16px 4px">
        <span style="display:inline-block;background:${CAM};color:#ffffff;font-size:11px;font-weight:700;padding:5px 12px;border-radius:999px">Chưa thanh toán</span>
      </td></tr>
      <tr><td style="padding:2px 16px 12px">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
          ${hang("Người thuê", esc(d.tenantName))}
          ${d.invoiceCode ? hang("Mã hoá đơn", esc(d.invoiceCode)) : ""}
        </table>
      </td></tr>
    </table>
  </td></tr>

  <tr><td style="padding:18px 32px 0">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-top:1px solid ${VIEN}">
      ${hang("Tiền phòng", vnd(d.rent) + "đ")}
      ${
    d.electricity
      ? hang(
        d.electricity.usage != null ? `Tiền điện (${vnd(d.electricity.usage)} kWh)` : "Tiền điện",
        vnd(d.electricity.amount) + "đ",
      )
      : ""
  }
      ${
    d.water
      ? hang(
        d.water.usage != null ? `Tiền nước (${vnd(d.water.usage)} m³)` : "Tiền nước",
        vnd(d.water.amount) + "đ",
      )
      : ""
  }
      ${d.fees.length ? `<tr><td colspan="2" style="padding:7px 0 0;color:${MO};font-size:13px">Phí khác:</td></tr>${dongPhi}` : ""}
    </table>
  </td></tr>

  <tr><td style="padding:16px 32px 0">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#FDECE1;border:1px solid #F0D1B2;border-radius:8px">
      <tr>
        <td style="padding:14px 16px;font-size:13px;font-weight:700;color:${NAVY}">TỔNG CỘNG</td>
        <td style="padding:14px 16px;text-align:right;font-size:20px;font-weight:700;color:#C75A2F">${vnd(d.total)}đ</td>
      </tr>
    </table>
  </td></tr>

  <tr><td style="padding:14px 32px 0">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
      <tr>
        <td style="font-size:13px;font-weight:700;color:#B64D43">Hạn thanh toán</td>
        <td style="text-align:right;font-size:13px;font-weight:700;color:#B64D43">${day(d.dueDate)}</td>
      </tr>
    </table>
  </td></tr>

  ${
    d.qrUrl
      ? `<tr><td style="padding:16px 32px 0">
    <div style="text-align:center;font-size:11px;color:${MO};margin-bottom:10px">Hoặc quét mã QR bên dưới để chuyển khoản trực tiếp</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border:1px dashed #C9CFDD;border-radius:8px">
      <tr><td align="center" style="padding:16px 16px 6px">
        <div style="font-size:13px;font-weight:700;color:${NAVY};margin-bottom:12px">Quét mã để thanh toán qua VietQR</div>
        <img src="${d.qrUrl}" alt="Ma QR chuyen khoan" width="200" height="200" style="display:block;border:0">
      </td></tr>
      ${
        d.bank
          ? `<tr><td style="padding:6px 16px 14px">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F6F8FA;border-radius:6px">
          <tr><td style="padding:10px 12px 2px;color:${MO};font-size:12px">Ngân hàng</td>
              <td style="padding:10px 12px 2px;text-align:right;font-size:12px;font-weight:700;color:${NAVY}">${esc(d.bank.name)}</td></tr>
          <tr><td style="padding:2px 12px;color:${MO};font-size:12px">Số tài khoản</td>
              <td style="padding:2px 12px;text-align:right;font-size:12px;font-weight:700;color:${NAVY}">${esc(d.bank.accountNumber)}</td></tr>
          <tr><td style="padding:2px 12px;color:${MO};font-size:12px">Chủ tài khoản</td>
              <td style="padding:2px 12px;text-align:right;font-size:12px;font-weight:700;color:${NAVY}">${esc(d.bank.accountName)}</td></tr>
          ${
            d.invoiceCode
              ? `<tr><td style="padding:2px 12px 10px;color:${MO};font-size:12px">Nội dung CK</td>
              <td style="padding:2px 12px 10px;text-align:right;font-size:12px;font-weight:700;color:${NAVY}">${esc(d.invoiceCode)}</td></tr>`
              : ""
          }
        </table>
      </td></tr>`
          : ""
      }
    </table>
  </td></tr>`
      : ""
  }

  <tr><td style="padding:18px 32px 0">
    <div style="text-align:center;font-size:11px;color:${MO};line-height:1.6">
      Quý khách vui lòng chuyển khoản đúng số tiền, đúng hạn để tránh phí trễ hạn.<br>
      Sau khi chuyển khoản, vui lòng thông báo cho chủ nhà qua Zalo/SMS.
    </div>
    <div style="text-align:center;font-size:11px;color:${MO};margin-top:10px">
      Đây là email tự động, vui lòng không trả lời trực tiếp email này.
    </div>
  </td></tr>

  <tr><td style="padding:18px 32px 24px;text-align:center;border-top:1px solid ${VIEN}">
    <div style="font-size:11px;color:${MO}">BizTown Rent Manager &copy; ${new Date().getFullYear()}</div>
  </td></tr>

</table>
</td></tr></table>
</body></html>`;
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
        "id, contract_id, house_id, house_name, room_nos, tenant_name, period_start, period_end, due_date, rent_amount, utility_lines, service_fee_amount, recurring_fees, other_fees, total_amount, public_code",
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

    // Tài khoản nhận tiền lấy từ nhà, KHÔNG lấy bản lưu trong hoá đơn — chủ trọ
    // đổi số tài khoản sau khi tạo hoá đơn thì bản lưu đã cũ (xem `invoice-qr`).
    const { data: house } = await ctx.supabaseAdmin
      .from("tb_house")
      .select("bank_bin, bank_account_number, bank_account_name")
      .eq("id", invoice.house_id)
      .maybeSingle();

    const lines = (invoice.utility_lines ?? []) as UtilityLine[];
    const gop = (type: "electricity" | "water") => {
      const of = lines.filter((l) => l.utilityType === type);
      if (of.length === 0) return null;
      const usage = of.every((l) => l.usageAmount != null)
        ? of.reduce((n, l) => n + Number(l.usageAmount), 0)
        : null;
      return { usage, amount: of.reduce((n, l) => n + Number(l.totalAmount ?? 0), 0) };
    };

    // "Phí khác" gộp phí dịch vụ + phí định kỳ + phí phát sinh, đúng thứ tự mẫu.
    const fees: { name: string; amount: number }[] = [];
    if (Number(invoice.service_fee_amount ?? 0) > 0) {
      fees.push({ name: "Phí dịch vụ", amount: Number(invoice.service_fee_amount) });
    }
    for (const f of [...(invoice.recurring_fees ?? []), ...(invoice.other_fees ?? [])] as
      { name: string; amount: number }[]) {
      fees.push({ name: f.name, amount: Number(f.amount) });
    }

    const html = renderInvoiceEmail({
      houseName: invoice.house_name ?? "",
      rooms,
      tenantName: invoice.tenant_name ?? tenant?.full_name ?? "",
      periodStart: invoice.period_start,
      periodEnd: invoice.period_end,
      dueDate: invoice.due_date,
      rent: Number(invoice.rent_amount ?? 0),
      electricity: gop("electricity"),
      water: gop("water"),
      fees,
      total: Number(invoice.total_amount),
      invoiceCode: invoice.public_code ?? null,
      qrUrl,
      bank: house?.bank_account_number
        ? {
          name: bankByBin(house.bank_bin)?.name ?? "",
          accountNumber: house.bank_account_number,
          accountName: house.bank_account_name ?? "",
        }
        : null,
    });

    try {
      const id = await sendViaBrevo(
        to,
        `Hoa don tien nha phong ${rooms} - ky ${monthYear(invoice.period_start)}`,
        html,
      );
      return Response.json({ sent: true, channel: "email", to, messageId: id });
    } catch (e) {
      return Response.json({ error: `${e}` }, { status: 500 });
    }
  }),
};

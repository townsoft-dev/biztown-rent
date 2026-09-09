// generate-payment-qr
//
// Sinh lại mã QR thanh toán (VietQR/NAPAS-247) cho 1 hoá đơn đã có — dùng khi cần
// gửi lại hoá đơn (resend) mà không muốn tính lại toàn bộ qua generate-invoice.
// generate-invoice cũng dùng chung module _shared/vietqr.ts để sinh QR lúc tạo mới.
//
// Xem docs/BUSINESS-RULES.md BR-BILL-10.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { buildVietQrPayload } from "../_shared/vietqr.ts";

export default {
  fetch: withSupabase({ auth: ["secret"] }, async (req, ctx) => {
    const { invoiceId } = await req.json();

    const { data: invoice, error: invoiceError } = await ctx.supabaseAdmin
      .from("tb_invoice")
      .select("id, house_id, total_amount, house_name, period_start")
      .eq("id", invoiceId)
      .single();
    if (invoiceError || !invoice) {
      return Response.json({ error: "Invoice not found" }, { status: 404 });
    }

    const { data: house, error: houseError } = await ctx.supabaseAdmin
      .from("tb_house")
      .select("bank_bin, bank_account_number, bank_account_name")
      .eq("id", invoice.house_id)
      .single();
    if (houseError || !house?.bank_bin || !house?.bank_account_number) {
      return Response.json({ error: "House chưa cấu hình tài khoản ngân hàng" }, { status: 400 });
    }

    const payload = buildVietQrPayload({
      bankBin: house.bank_bin,
      accountNumber: house.bank_account_number,
      amount: invoice.total_amount,
      merchantName: house.bank_account_name ?? undefined,
      message: `${invoice.house_name ?? ""} ${invoice.period_start ?? ""}`.trim(),
    });

    const { error: updateError } = await ctx.supabaseAdmin
      .from("tb_invoice")
      .update({ payment_qr_payload: payload })
      .eq("id", invoiceId);
    if (updateError) return Response.json({ error: updateError.message }, { status: 500 });

    return Response.json({ paymentQrPayload: payload });
  }),
};

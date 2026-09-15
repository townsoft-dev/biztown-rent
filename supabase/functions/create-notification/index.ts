// create-notification
//
// Ghi 1 thông báo (S-03 Notification Center) cho 2 loại hành động chạy trực
// tiếp từ app (Flutter tự update bảng qua RLS, không qua Edge Function nào
// khác) nên cần 1 endpoint riêng để fan-out sau khi hành động đó thành công:
// - "invoice_collected" (BR-NOTI-03): sau khi B-04 "Mark as collected".
// - "manager_invited" (BR-NOTI-06): sau khi P-06 mời quản lý mới cho 1 nhà.
//
// "invoice_sent" (BR-NOTI-01) KHÔNG qua đây — đã chạy thẳng trong
// generate-invoice (server tự tạo hoá đơn xong là tự biết house_id luôn,
// không cần round-trip riêng).

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { fanOutNotification } from "../_shared/notifications.ts";

type Payload =
  | { type: "invoice_collected"; invoiceId: string; actorPhone?: string }
  | { type: "manager_invited"; houseId: string; recipientPhone: string };

export default {
  // "user": app gọi thật bằng JWT chủ nhà/quản lý ngay sau khi hành động
  // chính (Mark as collected / mời quản lý) đã ghi xong ở phía client.
  fetch: withSupabase({ auth: ["user", "secret"] }, async (req, ctx) => {
    const body: Payload = await req.json();

    if (body.type === "invoice_collected") {
      const { data: allowed } = await ctx.supabase
        .from("tb_invoice")
        .select("id")
        .eq("id", body.invoiceId)
        .maybeSingle();
      if (!allowed) return Response.json({ error: "Forbidden" }, { status: 403 });

      const { data: invoice } = await ctx.supabaseAdmin
        .from("tb_invoice")
        .select("house_id, room_nos, tenant_name, total_amount")
        .eq("id", body.invoiceId)
        .single();
      if (!invoice) return Response.json({ error: "Invoice not found" }, { status: 404 });

      await fanOutNotification(ctx.supabaseAdmin, {
        houseId: invoice.house_id,
        type: "invoice_collected",
        payload: {
          roomNos: invoice.room_nos,
          tenantName: invoice.tenant_name,
          amount: invoice.total_amount,
        },
        targetInvoiceId: body.invoiceId,
        excludePhone: body.actorPhone,
      });
      return Response.json({ ok: true });
    }

    if (body.type === "manager_invited") {
      const { data: allowed } = await ctx.supabase
        .from("tb_house")
        .select("id, name")
        .eq("id", body.houseId)
        .maybeSingle();
      if (!allowed) return Response.json({ error: "Forbidden" }, { status: 403 });

      await ctx.supabaseAdmin.from("tb_notification").insert({
        recipient_phone: body.recipientPhone,
        house_id: body.houseId,
        type: "manager_invited",
        payload: { houseName: allowed.name },
      });
      return Response.json({ ok: true });
    }

    return Response.json({ error: "type không hợp lệ" }, { status: 400 });
  }),
};

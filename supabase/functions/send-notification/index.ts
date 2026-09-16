// send-notification
//
// Gửi Push (cho người có quyền trên 1 Nhà/Dãy trọ) + SMS/Zalo (một chiều tới Tenant,
// không có tài khoản) — theo docs/BUSINESS-RULES.md mục 5 (BR-NOTI-01..07).
//
// Trạng thái implement (2026-09-14, B-05 Send Invoice):
// - SMS tới Tenant: ĐÃ nối eSMS.vn thật qua `_shared/esms.ts` (dùng chung với
//   `generate-invoice` mode "batchSend") — SmsType "1" (tin thường qua đầu số/
//   tổng đài, KHÔNG cần đăng ký Brandname/mẫu tin trước) vì dungtv xác nhận
//   CHƯA có Brandname CSKH riêng (SmsType "8") cho eSMS. Đổi sang Brandname
//   CSKH sau khi có — chỉ cần sửa `_shared/esms.ts`, không đổi luồng gọi.
// - Push Android + iOS (FCM HTTP v1, `_shared/fcm.ts`): ĐÃ bật thật (Đợt 46) —
//   FCM v1 tự chuyển `notification: {title, body}` sang đúng định dạng APNs cho
//   token iOS, dùng chung 1 API cho cả 2 nền tảng, miễn Firebase project đã có
//   APNs Authentication Key (dungtv tự upload qua Firebase Console, ngoài phạm
//   vi code — xem docs/DECISIONS.md Đợt 46). Thiếu secret FCM_SERVICE_ACCOUNT
//   thì tự trả cảnh báo, không gửi được gì, không ảnh hưởng SMS Tenant.
// - Zalo ZNS/OA: vẫn TODO — đang chờ dungtv cung cấp OA ID/App ID/Secret/Access+Refresh
//   token/Template ID (xem docs/DECISIONS.md).
//
// Đã cập nhật theo schema Version 3: đọc người nhận push qua `tb_user_house_access`
// (theo house_id, không phân biệt owner/manager — BR-NOTI-01/02/05 gửi cho "người có
// quyền trên nhà đó" không phân role) + `tb_device_token`. Tenant không có
// `auth.users`/`tb_user` row nên chỉ nhận qua SMS/Zalo, không có push.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { sendSmsViaEsms } from "../_shared/esms.ts";
import { sendFcmPush } from "../_shared/fcm.ts";
import { sendZns } from "../_shared/zalo.ts";
import { buildZnsInvoiceData } from "../_shared/zns_invoice.ts";

interface SendNotificationRequest {
  houseId: string;
  event: string; // "invoice_created" | "payment_reminder" | "request_created" | ...
  title: string;
  body: string;
  // Push đi kèm cho mọi người có quyền trên houseId (owner + manager, BR-NOTI-01/02/05).
  push?: boolean;
  // SMS/Zalo một chiều tới Tenant — nội dung PHẢI tiếng Việt (BR-NOTI-07), độc lập
  // với ngôn ngữ UI của Landlord/Manager.
  tenant?: {
    phone: string;
    message: string; // tiếng Việt, có thể kèm link mã QR
  };
  // Gửi ZNS Zalo cho 1 hoá đơn, dùng template ĐÃ được Zalo duyệt (secret
  // ZALO_ZNS_TEMPLATE_ID). Tách hẳn khỏi `tenant` (SMS) để bật/tắt độc lập —
  // giai đoạn này đang test nên chưa gắn tự động vào luồng gửi hoá đơn.
  zalo?: {
    phone: string;
    invoiceId: string;
  };
}

export default {
  // "user": B-05 (Send invoice) gọi thật từ app bằng JWT chủ nhà/quản lý — tự kiểm
  // tra quyền qua `ctx.supabase` (RLS-scoped, policy "House ... has_house_access")
  // trước khi gửi. "secret" giữ cho test/script nội bộ.
  fetch: withSupabase({ auth: ["user", "secret"] }, async (req, ctx) => {
    const payload: SendNotificationRequest = await req.json();

    const { data: allowed } = await ctx.supabase
      .from("tb_house")
      .select("id")
      .eq("id", payload.houseId)
      .maybeSingle();
    if (!allowed) {
      return Response.json({ error: "Forbidden" }, { status: 403 });
    }

    const results: Record<string, unknown> = {};

    if (payload.push !== false) {
      const { data: accessRows } = await ctx.supabaseAdmin
        .from("tb_user_house_access")
        .select("phone")
        .eq("house_id", payload.houseId);
      const phones = [...new Set((accessRows ?? []).map((r: any) => r.phone))];

      const { data: users } = await ctx.supabaseAdmin.from("tb_user").select("id").in("phone", phones);
      const userIds = (users ?? []).map((u: any) => u.id);

      const { data: tokens } = await ctx.supabaseAdmin
        .from("tb_device_token")
        .select("token, platform")
        .in("user_id", userIds);

      // Android + iOS đều qua cùng 1 API FCM v1 (thật, chờ secret
      // FCM_SERVICE_ACCOUNT — xem docs/DECISIONS.md Đợt 41/46); tự bỏ qua với
      // cảnh báo nếu chưa cấu hình, không chặn phần SMS Tenant bên dưới.
      const allTokens = tokens ?? [];
      const pushResults = await Promise.all(
        allTokens.map((t: any) => sendFcmPush(t.token, payload.title, payload.body)),
      );
      const sentCount = pushResults.filter((r) => r.ok).length;
      const errors = pushResults.filter((r) => !r.ok).map((r: any) => r.reason);
      results.push = {
        recipientCount: allTokens.length,
        sent: sentCount,
        ...(errors.length > 0 ? { errors: [...new Set(errors)] } : {}),
      };
    }

    if (payload.tenant) {
      try {
        await sendSmsViaEsms(payload.tenant.phone, payload.tenant.message);
        results.tenantMessage = { sent: true, channel: "sms", phone: payload.tenant.phone };
      } catch (e) {
        return Response.json({ error: `${e}` }, { status: 500 });
      }
    }

    if (payload.zalo) {
      const templateId = Deno.env.get("ZALO_ZNS_TEMPLATE_ID");
      if (!templateId) {
        results.zalo = { sent: false, reason: "Thiếu secret ZALO_ZNS_TEMPLATE_ID" };
      } else {
        try {
          const { data: invoice, error } = await ctx.supabaseAdmin
            .from("tb_invoice")
            .select(
              "house_name, room_nos, period_start, rent_amount, utility_lines, service_fee_amount, recurring_fees, other_fees, total_amount",
            )
            .eq("id", payload.zalo.invoiceId)
            .single();
          if (error || !invoice) throw new Error(`Không tìm thấy hoá đơn: ${error?.message}`);

          const templateData = buildZnsInvoiceData(invoice);
          const sendResult = await sendZns(ctx.supabaseAdmin, {
            phone: payload.zalo.phone,
            templateId,
            templateData,
          });
          // Trả cả templateData + msgId ra response: đang giai đoạn test thật,
          // cần nhìn được chính xác giá trị đã gửi để đối chiếu với tin nhận được.
          results.zalo = { sent: true, msgId: sendResult.msgId, templateData };
        } catch (e) {
          results.zalo = { sent: false, reason: `${e}` };
        }
      }
    }

    return Response.json({ event: payload.event, ...results });
  }),
};

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
// - Push Android (FCM): code sẵn (`_shared/fcm.ts`), chờ dungtv tạo Firebase
//   project + gửi file service account JSON để set secret FCM_SERVICE_ACCOUNT
//   (xem docs/DECISIONS.md Đợt 41) — chưa có secret thì tự trả cảnh báo, không
//   gửi được gì, không ảnh hưởng SMS Tenant. Push iOS (APNs) vẫn TODO riêng.
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

      // Android qua FCM (thật, chờ secret FCM_SERVICE_ACCOUNT — xem
      // docs/DECISIONS.md Đợt 41); tự bỏ qua với cảnh báo nếu chưa cấu hình,
      // không chặn phần SMS Tenant bên dưới. iOS/APNs vẫn TODO riêng (cần
      // Apple Developer account + APNs key, ngoài phạm vi FCM).
      const androidTokens = (tokens ?? []).filter((t: any) => t.platform === "android");
      const pushResults = await Promise.all(
        androidTokens.map((t: any) => sendFcmPush(t.token, payload.title, payload.body)),
      );
      const sentCount = pushResults.filter((r) => r.ok).length;
      const errors = pushResults.filter((r) => !r.ok).map((r: any) => r.reason);
      results.push = {
        recipientCount: androidTokens.length,
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
      // TODO: Zalo ZNS/OA — đang chờ dungtv cung cấp OA ID/App ID/Secret/token/Template ID.
    }

    return Response.json({ event: payload.event, ...results });
  }),
};

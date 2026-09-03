// send-notification
//
// Gửi thông báo qua Push (FCM/APNs) + SMS/Zalo song song, theo docs/BUSINESS-RULES.md mục 5
// (BR-NOTI-01..08) — áp dụng cho cả Landlord và Tenant.
//
// CHƯA IMPLEMENT — đang chờ quyết định/tài khoản trước khi code thật:
// - Firebase project cho FCM (push Android) chưa tạo.
// - Nhà cung cấp SMS Việt Nam (eSMS hay Speedsms) chưa chọn.
// - Zalo ZNS/OA chưa đăng ký + duyệt mẫu tin nhắn.
//
// Khi có đủ, hàm này sẽ: ghi 1 row vào bảng `notifications` (cho Trung tâm thông báo S-03),
// rồi gọi song song FCM/APNs + SMS/Zalo API tuỳ theo `channel` được truyền vào.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

interface SendNotificationRequest {
  user_id: string;
  type: string; // vd: "invoice_created", "payment_reminder", "request_created"...
  title: string;
  body: string;
  channel: ("push" | "sms" | "zalo")[];
  related_entity_type?: string;
  related_entity_id?: string;
}

export default {
  fetch: withSupabase({ auth: ["secret"] }, async (req, ctx) => {
    const payload: SendNotificationRequest = await req.json();

    const { data: notification, error } = await ctx.supabaseAdmin
      .from("notifications")
      .insert({
        user_id: payload.user_id,
        type: payload.type,
        title: payload.title,
        body: payload.body,
        channel: payload.channel,
        related_entity_type: payload.related_entity_type,
        related_entity_id: payload.related_entity_id,
      })
      .select()
      .single();

    if (error) {
      return Response.json({ error: error.message }, { status: 500 });
    }

    // TODO: gọi FCM/APNs nếu channel bao gồm "push".
    // TODO: gọi SMS provider (eSMS/Speedsms) nếu channel bao gồm "sms".
    // TODO: gọi Zalo ZNS/OA nếu channel bao gồm "zalo".

    return Response.json({ notification, warning: "push/sms/zalo delivery not implemented yet" });
  }),
};

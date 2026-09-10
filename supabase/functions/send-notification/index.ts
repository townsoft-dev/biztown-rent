// send-notification
//
// Gửi Push (cho người có quyền trên 1 Nhà/Dãy trọ) + SMS/Zalo (một chiều tới Tenant,
// không có tài khoản) — theo docs/BUSINESS-RULES.md mục 5 (BR-NOTI-01..07).
//
// CHƯA IMPLEMENT phần gửi thật — đang chờ quyết định/tài khoản trước khi code:
// - Firebase project cho FCM (push Android) chưa tạo.
// - eSMS.vn đã chọn cho OTP (xem send-otp-sms), nhưng kênh gửi hoá đơn/nhắc thanh toán
//   Tenant ở đây vẫn chưa nối (cần Brandname CSKH thật, khác brandname demo dùng để test
//   OTP). Zalo ZNS/OA cũng chưa chọn/duyệt.
//
// Đã cập nhật theo schema Version 3: đọc người nhận push qua `tb_user_house_access`
// (theo house_id, không phân biệt owner/manager — BR-NOTI-01/02/05 gửi cho "người có
// quyền trên nhà đó" không phân role) + `tb_device_token`. Tenant không có
// `auth.users`/`tb_user` row nên chỉ nhận qua SMS/Zalo, không có push.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

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
  fetch: withSupabase({ auth: ["secret"] }, async (req, ctx) => {
    const payload: SendNotificationRequest = await req.json();

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

      // TODO: gọi FCM (Android) / APNs (iOS) thật với payload.title/payload.body cho từng token.
      results.push = { warning: "FCM/APNs chưa implement", recipientCount: (tokens ?? []).length };
    }

    if (payload.tenant) {
      // TODO: gọi eSMS.vn (cần Brandname CSKH thật, khác brandname demo dùng test OTP)
      // và/hoặc Zalo ZNS/OA với payload.tenant.message.
      results.tenantMessage = { warning: "SMS/Zalo chưa implement", phone: payload.tenant.phone };
    }

    return Response.json({ event: payload.event, ...results });
  }),
};

// send-otp-sms
//
// Supabase Auth "Send SMS" Hook — thay thế nhà cung cấp SMS mặc định của Supabase
// (Twilio/MessageBird/Vonage, không phải SMS brandname VN) bằng eSMS/Speedsms.
// Xem docs/DECISIONS.md (2026-08-28) và docs/REQUIREMENTS.md INT-02/INT-03.
//
// Setup khi implement thật:
// 1. Đăng ký hook này trong Supabase Dashboard > Authentication > Hooks > Send SMS hook,
//    trỏ tới URL của function này.
// 2. Cấu hình bí mật ký hook (Supabase ký request bằng HMAC — cần verify trong function thật).
//
// CHƯA IMPLEMENT — đang chờ chọn nhà cung cấp (eSMS hay Speedsms) + đăng ký tài khoản.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

interface SendSmsHookPayload {
  user: { phone: string };
  sms: { otp: string };
}

export default {
  fetch: withSupabase({ auth: ["secret"] }, async (req) => {
    const payload: SendSmsHookPayload = await req.json();

    // TODO: verify webhook signature từ Supabase trước khi tin payload (bắt buộc cho production).
    // TODO: gọi API eSMS/Speedsms để gửi payload.sms.otp tới payload.user.phone.

    console.log(`[send-otp-sms] TODO: send OTP ${payload.sms.otp} to ${payload.user.phone}`);

    // Trả 200 rỗng để báo Supabase là đã xử lý (theo spec Send SMS Hook).
    return new Response(null, { status: 200 });
  }),
};

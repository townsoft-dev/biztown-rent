// send-otp-sms
//
// Supabase Auth "Send SMS" Hook — thay thế nhà cung cấp SMS mặc định của Supabase
// (Twilio/MessageBird/Vonage, không phải SMS brandname VN) bằng SpeedSMS.
// Xem docs/DECISIONS.md (2026-08-28, 2026-09-09) và docs/REQUIREMENTS.md INT-02/INT-03.
//
// Setup:
// 1. Đăng ký hook này trong Supabase Dashboard > Authentication > Hooks > Send SMS hook,
//    trỏ tới URL của function này.
// 2. Secret `SPEEDSMS_ACCESS_TOKEN` đã set qua `supabase secrets set` — lấy tại
//    connect.speedsms.vn > Settings > Profile. Đổi tài khoản (bàn giao khách) chỉ cần
//    set lại secret này, không sửa code.
//
// TODO: chưa đăng ký Brandname (đang dùng type=2 — số gửi ngẫu nhiên, không cần duyệt
// trước). Khi có Brandname đã duyệt, đổi SPEEDSMS_TYPE bên dưới sang "4".
// TODO: verify webhook signature (header `webhook-signature`, ký bằng hook_send_sms_secrets)
// trước khi tin payload — bắt buộc cho production, hiện auth: "none" nên ai gọi cũng
// được (nhưng nội dung request phải đúng shape SendSmsHookPayload GoTrue mới gửi được;
// rủi ro: ai đó có thể tự gọi function này gửi SMS lung tung nếu biết URL — cần vá sớm).

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

interface SendSmsHookPayload {
  user: { phone: string };
  sms: { otp: string };
}

// type=4 + sender=Verify: brandname mặc định có sẵn của SpeedSMS dành cho OTP,
// không cần đăng ký/duyệt Brandname riêng. Khi có Brandname riêng đã duyệt, đổi
// sang type=3 + sender=<tên Brandname đã duyệt>.
const SPEEDSMS_TYPE = "4";
const SPEEDSMS_SENDER = "Verify";

async function sendViaSpeedSms(phone: string, otp: string): Promise<void> {
  const accessToken = Deno.env.get("SPEEDSMS_ACCESS_TOKEN");
  if (!accessToken) throw new Error("Thiếu secret SPEEDSMS_ACCESS_TOKEN");

  const content = `Ma xac thuc BizTown Rent Manager cua ban la: ${otp}`;
  const url = new URL("https://api.speedsms.vn/index.php/sms/send");
  url.searchParams.set("access-token", accessToken);
  url.searchParams.set("to", phone);
  url.searchParams.set("content", content);
  url.searchParams.set("type", SPEEDSMS_TYPE);
  url.searchParams.set("sender", SPEEDSMS_SENDER);

  const res = await fetch(url.toString());
  const body = await res.json();
  // SpeedSMS trả status: "success" khi gửi thành công, xem docs/API.md.
  if (body.status !== "success") {
    throw new Error(`SpeedSMS gửi thất bại: ${JSON.stringify(body)}`);
  }
}

export default {
  fetch: withSupabase({ auth: ["none"] }, async (req) => {
    const payload: SendSmsHookPayload = await req.json();

    try {
      await sendViaSpeedSms(payload.user.phone, payload.sms.otp);
    } catch (e) {
      console.error(`[send-otp-sms] lỗi gửi OTP tới ${payload.user.phone}:`, e);
      // Trả lỗi đúng format Send SMS Hook để Supabase Auth báo lỗi rõ cho client
      // (thay vì âm thầm coi như đã gửi thành công).
      return Response.json(
        { error: { http_code: 500, message: "Không gửi được SMS OTP" } },
        { status: 500 },
      );
    }

    // Trả 200 rỗng để báo Supabase là đã xử lý (theo spec Send SMS Hook).
    return new Response(null, { status: 200 });
  }),
};

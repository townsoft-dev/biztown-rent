// send-otp-sms
//
// Supabase Auth "Send SMS" Hook — thay thế nhà cung cấp SMS mặc định của Supabase
// (Twilio/MessageBird/Vonage, không phải SMS brandname VN) bằng eSMS.vn.
// Xem docs/DECISIONS.md (2026-08-28, 2026-09-09) và docs/REQUIREMENTS.md INT-02/INT-03.
//
// Setup:
// 1. Đăng ký hook này trong Supabase Dashboard > Authentication > Hooks > Send SMS hook,
//    trỏ tới URL của function này.
// 2. Secret `ESMS_API_KEY`/`ESMS_SECRET_KEY` đã set qua `supabase secrets set` — lấy tại
//    esms.vn > Tiện ích > Quản lý API. Đổi tài khoản (bàn giao khách) chỉ cần set lại 2
//    secret này, không sửa code.
//
// ⚠️ ĐANG DÙNG BRANDNAME DEMO "Baotrixemay" của eSMS (test miễn phí, không cần đăng ký) —
// bắt buộc đúng template "{code} la ma xac minh dang ky Baotrixemay cua ban", không thể
// đổi thành nội dung có tên BizTown. CHỈ dùng để test luồng, PHẢI đổi sang Brandname thật
// (SmsType "8" + Template riêng, hoặc đăng ký Brandname CSKH thật) trước khi lên production.
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

const ESMS_BRANDNAME = "Baotrixemay"; // DEMO — xem cảnh báo ở đầu file
const ESMS_SMS_TYPE = "2";

// Supabase gửi payload SĐT dạng E.164 (+84...) — eSMS cần dạng nội địa (0...).
function toLocalVnPhone(e164: string): string {
  return e164.startsWith("+84") ? `0${e164.slice(3)}` : e164;
}

async function sendViaEsms(phone: string, otp: string): Promise<void> {
  const apiKey = Deno.env.get("ESMS_API_KEY");
  const secretKey = Deno.env.get("ESMS_SECRET_KEY");
  if (!apiKey || !secretKey) throw new Error("Thiếu secret ESMS_API_KEY/ESMS_SECRET_KEY");

  const content = `${otp} la ma xac minh dang ky ${ESMS_BRANDNAME} cua ban`;
  const res = await fetch("https://rest.esms.vn/MainService.svc/json/SendMultipleMessage_V4_post_json/", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      ApiKey: apiKey,
      SecretKey: secretKey,
      Phone: toLocalVnPhone(phone),
      Content: content,
      Brandname: ESMS_BRANDNAME,
      SmsType: ESMS_SMS_TYPE,
      IsUnicode: "0",
    }),
  });
  const body = await res.json();
  // eSMS trả CodeResult "100" khi gửi thành công, xem docs/API.md.
  if (body.CodeResult !== "100") {
    throw new Error(`eSMS gửi thất bại: ${JSON.stringify(body)}`);
  }
}

export default {
  fetch: withSupabase({ auth: ["none"] }, async (req) => {
    const payload: SendSmsHookPayload = await req.json();

    try {
      await sendViaEsms(payload.user.phone, payload.sms.otp);
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

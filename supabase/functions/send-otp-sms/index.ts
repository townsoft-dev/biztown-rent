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
// Verify chữ ký webhook bằng thư viện chính thức `standardwebhooks` (Supabase Auth Hooks
// theo chuẩn Standard Webhooks) — secret `SEND_SMS_HOOK_SECRET` phải khớp đúng với
// `hook_send_sms_secrets` đã cấu hình trong Supabase Auth (Dashboard/Management API).
// Không verify được (thiếu secret/sai chữ ký) → từ chối request, không gửi SMS.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

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
    const rawBody = await req.text();
    const hookSecret = Deno.env.get("SEND_SMS_HOOK_SECRET");
    if (!hookSecret) {
      console.error("[send-otp-sms] thiếu secret SEND_SMS_HOOK_SECRET, từ chối request");
      return Response.json({ error: { http_code: 500, message: "Thiếu cấu hình xác thực hook" } }, { status: 500 });
    }

    let payload: SendSmsHookPayload;
    try {
      const wh = new Webhook(hookSecret.replace("v1,whsec_", ""));
      const headers = Object.fromEntries(req.headers);
      payload = wh.verify(rawBody, headers) as SendSmsHookPayload;
    } catch (e) {
      console.error("[send-otp-sms] chữ ký webhook không hợp lệ, từ chối request:", e);
      return Response.json({ error: { http_code: 401, message: "Chữ ký webhook không hợp lệ" } }, { status: 401 });
    }

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

    // Trả 200 kèm body JSON rỗng (không phải null) — GoTrue validate Content-Type của
    // response hook, response rỗng không có header này từng gây lỗi
    // "hook_payload_invalid_content_type" phía client dù function thực ra đã chạy đúng.
    return Response.json({}, { status: 200 });
  }),
};

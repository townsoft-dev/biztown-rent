// _shared/esms.ts
//
// Gửi SMS qua eSMS.vn — dùng chung cho send-notification (SMS hoá đơn) và
// generate-invoice (mode "batchSend", tạo + gửi hàng loạt phía backend). Tách
// ra đây vì cả 2 nơi cần đúng 1 logic gọi eSMS giống hệt nhau.
//
// SmsType "1" = tin thường qua đầu số/tổng đài dùng chung của eSMS — gửi
// được nội dung TỰ DO ngay, không cần đăng ký/duyệt Brandname trước (dungtv
// xác nhận CHƯA có Brandname CSKH riêng, 2026-09-14). Nâng cấp lên Brandname
// CSKH thật (SmsType "8") sau chỉ cần đổi trong hàm này.

// Supabase gửi SĐT dạng E.164 (+84...) — eSMS cần dạng nội địa (0...).
function toLocalVnPhone(phone: string): string {
  return phone.startsWith("+84") ? `0${phone.slice(3)}` : phone;
}

/** Kết quả thô từ eSMS — `smsId` dùng để tra cứu tình trạng giao tin sau đó. */
export interface EsmsSendResult {
  smsId: string | null;
  raw: Record<string, unknown>;
}

export async function sendSmsViaEsms(phone: string, message: string): Promise<EsmsSendResult> {
  const apiKey = Deno.env.get("ESMS_API_KEY");
  const secretKey = Deno.env.get("ESMS_SECRET_KEY");
  if (!apiKey || !secretKey) throw new Error("Thiếu secret ESMS_API_KEY/ESMS_SECRET_KEY");

  const res = await fetch("https://rest.esms.vn/MainService.svc/json/SendMultipleMessage_V4_post_json/", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      ApiKey: apiKey,
      SecretKey: secretKey,
      Phone: toLocalVnPhone(phone),
      Content: message,
      SmsType: "1",
      IsUnicode: "1", // nội dung tiếng Việt có dấu (BR-NOTI-07)
    }),
  });
  const body = await res.json();
  // eSMS trả CodeResult "100" khi gửi thành công, xem docs/API.md.
  if (body.CodeResult !== "100") {
    throw new Error(`eSMS gửi thất bại: ${JSON.stringify(body)}`);
  }
  // CHÚ Ý: "100" chỉ nghĩa là eSMS ĐÃ NHẬN đơn, KHÔNG phải nhà mạng đã giao
  // tới máy người nhận. Trước 17/09/2026 hàm này vứt luôn phản hồi nên khi
  // dungtv không nhận được tin, không còn gì để tra cứu — không biết tin có
  // tồn tại trên hệ thống eSMS hay không. Trả `smsId` ra để tra tình trạng
  // giao tin (và đối chiếu trong trang quản trị eSMS).
  return { smsId: (body.SMSID ?? null) as string | null, raw: body };
}

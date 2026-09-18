// _shared/esms.ts
//
// Gửi SMS qua eSMS.vn — dùng chung cho send-notification (SMS hoá đơn) và
// generate-invoice (mode "batchSend", tạo + gửi hàng loạt phía backend). Tách
// ra đây vì cả 2 nơi cần đúng 1 logic gọi eSMS giống hệt nhau.
//
// ⚠️ PHẢI gửi bằng BRANDNAME (`SmsType "2"` + `Brandname`), KHÔNG dùng
// SmsType "1" (đầu số/tổng đài dùng chung): eSMS nhận đơn và VẪN TRỪ TIỀN,
// nhưng nhà mạng KHÔNG GIAO. Kiểm chứng 2 lần: 17/09/2026 (gửi song song tới
// cùng một số, tin SmsType "1" không tới, tin brandname tới ngay) và
// 18/09/2026 (dungtv báo không nhận được tin hoá đơn nào, trong khi OTP —
// vốn đã dùng brandname ở `send-otp-sms` — vẫn tới bình thường).
//
// Nội dung đã được nắn theo đúng mẫu của brandname mượn "Baotrixemay" ở
// `src/lib/core/invoice_message.dart`; trước 18/09 phần nội dung nắn đúng mẫu
// nhưng chỗ GỬI lại vẫn để SmsType "1" nên công nắn mẫu thành vô ích.
//
// `IsUnicode` phải là "0": nội dung hoá đơn cố tình viết KHÔNG DẤU để nằm
// trong bảng mã GSM-7 (160 ký tự/đoạn). Để "1" là ép sang UCS-2, tụt xuống
// 70 ký tự/đoạn, tin 199 ký tự nhảy từ 2 lên 3 đoạn — trả tiền gấp rưỡi cho
// đúng một nội dung không có lấy một dấu tiếng Việt.
//
// Khi đăng ký được BRANDNAME CSKH riêng thì đổi `ESMS_BRANDNAME` bên dưới và
// viết lại nội dung theo mẫu mới đã duyệt.

// Brandname đang MƯỢN của eSMS (mẫu demo nhắc bảo trì xe máy) — giống hệt
// `send-otp-sms`. Đổi ở đây là đổi cho cả SMS hoá đơn đơn lẻ lẫn gửi hàng loạt.
const ESMS_BRANDNAME = "Baotrixemay";
const ESMS_SMS_TYPE = "2";

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
      Brandname: ESMS_BRANDNAME,
      SmsType: ESMS_SMS_TYPE,
      IsUnicode: "0", // nội dung viết không dấu để ở lại GSM-7, xem đầu file
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

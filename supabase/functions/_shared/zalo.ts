// _shared/zalo.ts
//
// Gửi tin nhắn qua Zalo ZNS (Zalo Notification Service) — CHUẨN BỊ SẴN cho
// khi có Template ID (đang chờ Zalo duyệt, xem docs/DECISIONS.md Đợt 41).
// CHƯA gọi thật ở đâu trong app — không có `templateId` thì không gửi được
// gì cả, đây chỉ là hạ tầng dựng sẵn.
//
// Khác với eSMS (API key/secret tĩnh, không đổi) — access token của Zalo
// OA hết hạn sau vài giờ, và MỖI LẦN làm mới bằng refresh token thì Zalo trả
// về 1 CẶP access+refresh token MỚI (refresh token cũ mất hiệu lực ngay).
// Vì vậy KHÔNG thể lưu tĩnh trong Supabase Secrets (không sửa được từ Edge
// Function) — phải lưu trong bảng `tb_zalo_token` (1 dòng duy nhất,
// `id='default'`), tự làm mới khi gần hết hạn.

const ZALO_OAUTH_REFRESH_URL = "https://oauth.zaloapp.com/v4/oa/access_token";
const ZALO_ZNS_SEND_URL = "https://business.openapi.zalo.me/message/template";

interface ZaloTokenRow {
  access_token: string;
  refresh_token: string;
  expires_at: string;
}

// deno-lint-ignore no-explicit-any
async function refreshZaloToken(supabaseAdmin: any): Promise<ZaloTokenRow> {
  const appId = Deno.env.get("ZALO_APP_ID");
  const appSecret = Deno.env.get("ZALO_APP_SECRET");
  if (!appId || !appSecret) {
    throw new Error("Thiếu secret ZALO_APP_ID/ZALO_APP_SECRET");
  }

  const { data: row } = await supabaseAdmin
    .from("tb_zalo_token")
    .select("refresh_token")
    .eq("id", "default")
    .single();
  if (!row) throw new Error("Chưa có token Zalo nào trong tb_zalo_token — cần dungtv cung cấp lại");

  const res = await fetch(ZALO_OAUTH_REFRESH_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "secret_key": appSecret,
    },
    body: new URLSearchParams({
      app_id: appId,
      refresh_token: row.refresh_token,
      grant_type: "refresh_token",
    }),
  });
  const body = await res.json();
  if (!body.access_token || !body.refresh_token) {
    throw new Error(`Làm mới token Zalo thất bại: ${JSON.stringify(body)}`);
  }

  // expires_in tính bằng giây, trừ 60s cho an toàn (tránh race condition sát hạn).
  const expiresAt = new Date(Date.now() + (Number(body.expires_in ?? 3600) - 60) * 1000);
  const updated: ZaloTokenRow = {
    access_token: body.access_token,
    refresh_token: body.refresh_token,
    expires_at: expiresAt.toISOString(),
  };
  await supabaseAdmin.from("tb_zalo_token").update(updated).eq("id", "default");
  return updated;
}

// deno-lint-ignore no-explicit-any
async function getValidZaloAccessToken(supabaseAdmin: any): Promise<string> {
  const { data: row } = await supabaseAdmin
    .from("tb_zalo_token")
    .select("access_token, refresh_token, expires_at")
    .eq("id", "default")
    .single();
  if (!row) throw new Error("Chưa có token Zalo nào trong tb_zalo_token — cần dungtv cung cấp lại");

  if (new Date(row.expires_at).getTime() <= Date.now()) {
    const refreshed = await refreshZaloToken(supabaseAdmin);
    return refreshed.access_token;
  }
  return row.access_token;
}

/**
 * Gửi 1 tin ZNS. CHƯA dùng ở đâu trong app — cần `templateId` thật (đang chờ
 * Zalo duyệt) trước khi bật tính năng "Gửi qua Zalo" ở B-03/B-05.
 */
// deno-lint-ignore no-explicit-any
export async function sendZns(
  supabaseAdmin: any,
  opts: { phone: string; templateId: string; templateData: Record<string, string> },
): Promise<void> {
  const accessToken = await getValidZaloAccessToken(supabaseAdmin);
  const res = await fetch(ZALO_ZNS_SEND_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json", "access_token": accessToken },
    body: JSON.stringify({
      phone: opts.phone, // dạng 84xxxxxxxxx — khớp sẵn convention của app, không cần đổi như eSMS.
      template_id: opts.templateId,
      template_data: opts.templateData,
    }),
  });
  const body = await res.json();
  if (body.error !== 0) {
    throw new Error(`Zalo ZNS gửi thất bại: ${JSON.stringify(body)}`);
  }
}

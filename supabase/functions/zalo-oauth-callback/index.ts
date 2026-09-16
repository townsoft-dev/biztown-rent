// zalo-oauth-callback
//
// Nhận `code` từ luồng cấp quyền OA của Zalo rồi tự đổi ra cặp token OA và
// lưu vào `tb_zalo_token`. Mục đích: dungtv chỉ cần bấm 1 đường link, chọn OA,
// bấm đồng ý — không phải copy/dán token bằng tay nữa (xem docs/DECISIONS.md
// Đợt 48).
//
// VÌ SAO CẦN CÁI NÀY: Zalo có 2 loại token dễ nhầm lẫn — token APP (chỉ cần
// App ID + Secret là lấy được) và token OA (phải qua bước OA cấp quyền cho
// app). ZNS CHỈ chấp nhận token OA. Cặp token lấy nhầm loại sẽ báo `-124
// Access token invalid` lúc gửi và `-14014 Invalid refresh token` lúc làm
// mới — đúng 2 lỗi đã gặp ngày 16/09/2026.
//
// `auth: ["none"]` vì Zalo chuyển hướng trình duyệt tới đây, không gửi kèm
// JWT nào được. Bù lại có 2 lớp kiểm tra bên dưới: `state` phải khớp secret,
// và `oa_id` Zalo trả về phải đúng OA của BizTown — nếu không, bất kỳ ai biết
// URL này cũng có thể cấp quyền OA CỦA HỌ và ghi đè token của mình.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

const ZALO_OA_TOKEN_URL = "https://oauth.zaloapp.com/v4/oa/access_token";

function page(title: string, detail: string, ok: boolean): Response {
  return new Response(
    `<!doctype html><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<div style="font-family:system-ui,sans-serif;max-width:600px;margin:60px auto;padding:0 20px">
  <h2 style="color:${ok ? "#137333" : "#c5221f"}">${title}</h2>
  <p style="color:#444;line-height:1.6">${detail}</p>
</div>`,
    { status: ok ? 200 : 400, headers: { "Content-Type": "text/html; charset=utf-8" } },
  );
}

// Zalo bắt xác thực quyền sở hữu đường dẫn callback trước khi cho dùng: phải
// đặt được 1 file `zalo_verifier<mã>.html` ngay tại đường dẫn đó. Vì callback
// là Edge Function chứ không phải web tĩnh, ta tự trả file này ra.
//
// Tự dựng nội dung từ chính mã trong tên file (thay vì ghi cứng 1 mã) để nếu
// Zalo cấp lại mã khác thì không phải sửa code + deploy lại. Không có rủi ro
// đáng kể: kẻ khác "xác thực" được đường dẫn này cũng không làm gì được, vì
// luồng cấp quyền bên dưới còn kiểm tra `state` khớp secret và `oa_id` đúng OA
// của BizTown.
const VERIFIER_PREFIX = "zalo_verifier";

function zaloVerifierFile(pathname: string): Response | null {
  const fileName = pathname.split("/").pop() ?? "";
  if (!fileName.startsWith(VERIFIER_PREFIX) || !fileName.endsWith(".html")) return null;
  const code = fileName.slice(VERIFIER_PREFIX.length, -".html".length);
  if (!/^[A-Za-z0-9_-]{8,128}$/.test(code)) return null;
  return new Response(
    `<!DOCTYPE html>
<html lang="en">

<head>
    <meta property="zalo-platform-site-verification" content="${code}" />
</head>

<body>
There Is No Limit To What You Can Accomplish Using Zalo!
</body>

</html>`,
    { status: 200, headers: { "Content-Type": "text/html; charset=utf-8" } },
  );
}

export default {
  fetch: withSupabase({ auth: ["none"] }, async (req, ctx) => {
    const url = new URL(req.url);

    const verifier = zaloVerifierFile(url.pathname);
    if (verifier) return verifier;

    const code = url.searchParams.get("code");
    const oaId = url.searchParams.get("oa_id");
    const state = url.searchParams.get("state");

    const expectedState = Deno.env.get("ZALO_OAUTH_STATE");
    if (!expectedState || state !== expectedState) {
      return page("Từ chối", "Tham số <code>state</code> không khớp — link không hợp lệ hoặc đã hết hiệu lực.", false);
    }

    const expectedOaId = Deno.env.get("ZALO_OA_ID");
    if (expectedOaId && oaId && oaId !== expectedOaId) {
      return page(
        "Sai Official Account",
        `Bạn vừa cấp quyền cho OA <code>${oaId}</code>, nhưng hệ thống đang cấu hình cho OA <code>${expectedOaId}</code>. Hãy chọn đúng OA "Townsoft Vina - BizTown".`,
        false,
      );
    }

    if (!code) return page("Thiếu code", "Zalo không trả về tham số <code>code</code>.", false);

    const appId = Deno.env.get("ZALO_APP_ID");
    const appSecret = Deno.env.get("ZALO_APP_SECRET");
    if (!appId || !appSecret) {
      return page("Thiếu cấu hình", "Chưa có secret ZALO_APP_ID/ZALO_APP_SECRET.", false);
    }

    const res = await fetch(ZALO_OA_TOKEN_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "secret_key": appSecret,
      },
      body: new URLSearchParams({
        code,
        app_id: appId,
        grant_type: "authorization_code",
      }),
    });
    const body = await res.json();
    if (!body.access_token || !body.refresh_token) {
      return page("Đổi code thất bại", `Zalo trả về: <code>${JSON.stringify(body)}</code>`, false);
    }

    // Trừ 60s cho an toàn, giống logic tự làm mới ở `_shared/zalo.ts`.
    const expiresAt = new Date(Date.now() + (Number(body.expires_in ?? 3600) - 60) * 1000);
    const { error } = await ctx.supabaseAdmin
      .from("tb_zalo_token")
      .update({
        access_token: body.access_token,
        refresh_token: body.refresh_token,
        expires_at: expiresAt.toISOString(),
        refresh_lock_until: null,
      })
      .eq("id", "default");
    if (error) {
      return page("Lưu token thất bại", `Lỗi ghi database: <code>${JSON.stringify(error)}</code>`, false);
    }

    return page(
      "Đã kết nối Zalo OA thành công",
      `Token OA đã được lưu, hạn dùng tới <b>${expiresAt.toISOString()}</b>. Hệ thống sẽ tự làm mới định kỳ — bạn không cần làm gì thêm. Có thể đóng trang này.`,
      true,
    );
  }),
};

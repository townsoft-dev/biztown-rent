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

// Thời gian giữ khoá làm mới. Đủ dài để 1 lượt gọi Zalo + ghi DB xong, đủ
// ngắn để nếu tiến trình giữ khoá chết giữa chừng thì lần gửi sau vẫn tự
// khôi phục được (không cần can thiệp tay).
const REFRESH_LOCK_SECONDS = 30;

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Giành quyền làm mới token. Trả `null` nếu tiến trình khác đang giữ khoá.
 *
 * Cập nhật có ĐIỀU KIỆN ngay trong câu lệnh (`refresh_lock_until` đã hết hạn
 * hoặc rỗng) nên 2 tiến trình chạy song song thì chỉ đúng 1 cái nhận được
 * dòng trả về — đây là điểm mấu chốt để không bao giờ có 2 lượt gọi Zalo
 * cùng lúc bằng cùng 1 refresh token (xem migration
 * `20260916100000_zalo_token_refresh_lock.sql`).
 */
// deno-lint-ignore no-explicit-any
async function acquireRefreshLock(supabaseAdmin: any): Promise<string | null> {
  const lockUntil = new Date(Date.now() + REFRESH_LOCK_SECONDS * 1000).toISOString();
  const { data } = await supabaseAdmin
    .from("tb_zalo_token")
    .update({ refresh_lock_until: lockUntil })
    .eq("id", "default")
    .or(`refresh_lock_until.is.null,refresh_lock_until.lt.${new Date().toISOString()}`)
    .select("refresh_token");
  if (!data || data.length === 0) return null;
  return data[0].refresh_token as string;
}

// deno-lint-ignore no-explicit-any
async function readTokenRow(supabaseAdmin: any): Promise<ZaloTokenRow> {
  const { data: row } = await supabaseAdmin
    .from("tb_zalo_token")
    .select("access_token, refresh_token, expires_at")
    .eq("id", "default")
    .single();
  if (!row) throw new Error("Chưa có token Zalo nào trong tb_zalo_token — cần dungtv cung cấp lại");
  return row as ZaloTokenRow;
}

/**
 * Gọi Zalo làm mới token. CHỈ gọi khi đã giành được khoá — mỗi lần gọi là
 * Zalo huỷ refresh token cũ ngay, gọi trùng sẽ làm chết token.
 */
// deno-lint-ignore no-explicit-any
async function refreshZaloToken(supabaseAdmin: any, refreshToken: string): Promise<ZaloTokenRow> {
  const appId = Deno.env.get("ZALO_APP_ID");
  const appSecret = Deno.env.get("ZALO_APP_SECRET");
  if (!appId || !appSecret) {
    throw new Error("Thiếu secret ZALO_APP_ID/ZALO_APP_SECRET");
  }

  const res = await fetch(ZALO_OAUTH_REFRESH_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "secret_key": appSecret,
    },
    body: new URLSearchParams({
      app_id: appId,
      refresh_token: refreshToken,
      grant_type: "refresh_token",
    }),
  });
  const body = await res.json();
  if (!body.access_token || !body.refresh_token) {
    throw new Error(`Làm mới token Zalo thất bại: ${JSON.stringify(body)}`);
  }

  // expires_in tính bằng giây, trừ 60s cho an toàn (tránh dùng token sát hạn).
  const expiresAt = new Date(Date.now() + (Number(body.expires_in ?? 3600) - 60) * 1000);
  const updated: ZaloTokenRow = {
    access_token: body.access_token,
    refresh_token: body.refresh_token,
    expires_at: expiresAt.toISOString(),
  };

  // Tới đây Zalo ĐÃ huỷ token cũ — ghi hỏng là mất token vĩnh viễn, phải xin
  // cấp lại tay. Thử lại vài lần trước khi chịu thua, và báo lỗi thật rõ để
  // biết ngay phải làm gì (không nuốt lỗi).
  let lastError: unknown = null;
  for (let attempt = 1; attempt <= 3; attempt++) {
    const { error } = await supabaseAdmin
      .from("tb_zalo_token")
      .update({ ...updated, refresh_lock_until: null })
      .eq("id", "default");
    if (!error) return updated;
    lastError = error;
    await sleep(300 * attempt);
  }
  throw new Error(
    `NGHIÊM TRỌNG: Zalo đã cấp token mới nhưng ghi vào tb_zalo_token thất bại sau 3 lần thử ` +
      `(${JSON.stringify(lastError)}). Token cũ đã bị Zalo huỷ — phải xin cấp lại cặp token mới bằng tay.`,
  );
}

/**
 * Trả access token còn hiệu lực, tự làm mới khi cần. An toàn khi gọi song
 * song (VD B-03 gửi hàng loạt): chỉ 1 tiến trình thực sự gọi Zalo, số còn lại
 * chờ rồi đọc token mới.
 */
// deno-lint-ignore no-explicit-any
async function getValidZaloAccessToken(supabaseAdmin: any): Promise<string> {
  const row = await readTokenRow(supabaseAdmin);
  if (new Date(row.expires_at).getTime() > Date.now()) return row.access_token;

  const refreshToken = await acquireRefreshLock(supabaseAdmin);
  if (refreshToken) {
    const refreshed = await refreshZaloToken(supabaseAdmin, refreshToken);
    return refreshed.access_token;
  }

  // Tiến trình khác đang làm mới — chờ nó ghi xong rồi dùng token mới.
  for (let attempt = 0; attempt < 30; attempt++) {
    await sleep(500);
    const latest = await readTokenRow(supabaseAdmin);
    if (new Date(latest.expires_at).getTime() > Date.now()) return latest.access_token;
  }
  throw new Error("Chờ tiến trình khác làm mới token Zalo quá 15s mà chưa xong — thử gửi lại sau");
}

// Zalo yêu cầu SĐT dạng `84xxxxxxxxx`. Trong DB có 2 quy ước khác nhau tuỳ
// bảng: `tb_user.phone` lưu sẵn `84...` nhưng `tb_tenant.phone` lưu `09...`
// (do người dùng nhập tay ở form Tenant) — chuẩn hoá tại đây để nơi gọi khỏi
// phải nhớ bảng nào dùng quy ước nào.
function toZaloPhone(phone: string): string {
  const digits = phone.trim().replace(/[^0-9+]/g, "");
  if (digits.startsWith("+84")) return digits.slice(1);
  if (digits.startsWith("84")) return digits;
  if (digits.startsWith("0")) return `84${digits.slice(1)}`;
  return `84${digits}`;
}

/**
 * Làm mới token NGAY kể cả khi access token còn hạn — dùng cho lịch chạy tự
 * động hàng tuần (`refresh-zalo-token`). Mục đích không phải lấy access token
 * mới, mà là GIA HẠN refresh token: refresh token Zalo sống ~3 tháng, nếu
 * suốt 3 tháng không ai gửi hoá đơn qua Zalo thì nó chết hẳn và phải xin cấp
 * lại bằng tay. Mỗi lần làm mới, Zalo cấp cặp mới nên đồng hồ 3 tháng được
 * đặt lại từ đầu.
 */
// deno-lint-ignore no-explicit-any
export async function forceRefreshZaloToken(supabaseAdmin: any): Promise<{ expiresAt: string }> {
  const refreshToken = await acquireRefreshLock(supabaseAdmin);
  if (!refreshToken) {
    throw new Error("Tiến trình khác đang làm mới token Zalo — bỏ qua lượt này");
  }
  const refreshed = await refreshZaloToken(supabaseAdmin, refreshToken);
  return { expiresAt: refreshed.expires_at };
}

/**
 * Gửi 1 tin ZNS theo template đã được Zalo duyệt. Trả về `msg_id` Zalo cấp
 * cho tin vừa gửi — cần giữ lại để đối chiếu khi người thuê bấm nút "Chi
 * tiết" trên tin đó (webhook chỉ trả về Zalo UID, không trả SĐT).
 */
// deno-lint-ignore no-explicit-any
/**
 * Giá trị một tham số ZNS. PHẢI cho phép cả `number`, không chỉ `string`.
 *
 * Mẫu hoá đơn `638179` khai 7 tham số kiểu **number** (`tien_phong`, `so_kwh`,
 * `tien_dien`, `so_khoi_nuoc`, `tien_nuoc`, `phi_khac`, `tong_cong`) và 1 kiểu
 * **date** (`so_ky`) — xem bảng "Loại dữ liệu" trong trang chi tiết mẫu. Bản
 * trước khai `Record<string, string>` nên mọi giá trị bị bọc trong dấu nháy;
 * cảnh báo này đã ghi ở `docs/ZALO-MESSAGING.md` mục 0 từ 15/09/2026 nhưng
 * chưa ai sửa vì lúc đó chưa có mẫu thật để đối chiếu.
 */
export type ZnsParamValue = string | number;

export async function sendZns(
  supabaseAdmin: any,
  opts: {
    phone: string;
    templateId: string;
    templateData: Record<string, ZnsParamValue>;
  },
): Promise<{ msgId: string | null; raw: unknown }> {
  const accessToken = await getValidZaloAccessToken(supabaseAdmin);
  const res = await fetch(ZALO_ZNS_SEND_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json", "access_token": accessToken },
    body: JSON.stringify({
      phone: toZaloPhone(opts.phone),
      template_id: opts.templateId,
      template_data: opts.templateData,
    }),
  });
  const body = await res.json();
  if (body.error !== 0) {
    throw new Error(`Zalo ZNS gửi thất bại: ${JSON.stringify(body)}`);
  }
  return { msgId: body.data?.msg_id ?? null, raw: body };
}

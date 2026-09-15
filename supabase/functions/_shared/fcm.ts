// _shared/fcm.ts
//
// Gửi push notification thật qua Firebase Cloud Messaging (FCM HTTP v1 API)
// — CHUẨN BỊ SẴN, chờ dungtv tạo Firebase project + gửi file service account
// JSON (xem docs/DECISIONS.md Đợt 41). Cho tới lúc đó, `FCM_SERVICE_ACCOUNT`
// (secret) không tồn tại → `sendFcmPush()` không được gọi, `send-notification`
// vẫn trả cảnh báo "chưa cấu hình" y như trước, KHÔNG ảnh hưởng gì tới các
// tính năng đang chạy thật.
//
// FCM v1 dùng OAuth2 (không còn "Server Key" cũ đã deprecated) — phải tự ký
// JWT bằng private key trong service account rồi đổi lấy access token ngắn
// hạn (~1h) trước khi gọi API gửi thật. Không dùng thư viện ngoài (Deno
// `crypto.subtle` tự ký RS256 được).

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

function base64UrlEncode(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const clean = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = atob(clean);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function getFcmAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const encoder = new TextEncoder();
  const unsigned = `${base64UrlEncode(encoder.encode(JSON.stringify(header)))}.${
    base64UrlEncode(encoder.encode(JSON.stringify(claims)))
  }`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(unsigned),
  );
  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(signature))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const body = await res.json();
  if (!body.access_token) throw new Error(`Đổi FCM access token thất bại: ${JSON.stringify(body)}`);
  return body.access_token;
}

/**
 * Gửi push tới 1 device token. Trả `{ok: true}` nếu thành công, `{ok: false,
 * reason}` nếu lỗi (VD token hết hạn/gỡ app) — không throw, để 1 token lỗi
 * không chặn các token còn lại trong `send-notification`.
 */
export async function sendFcmPush(
  deviceToken: string,
  title: string,
  body: string,
): Promise<{ ok: true } | { ok: false; reason: string }> {
  const raw = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!raw) return { ok: false, reason: "Thiếu secret FCM_SERVICE_ACCOUNT — chưa cấu hình Firebase" };

  let account: ServiceAccount;
  try {
    account = JSON.parse(raw);
  } catch {
    return { ok: false, reason: "FCM_SERVICE_ACCOUNT không phải JSON hợp lệ" };
  }

  try {
    const accessToken = await getFcmAccessToken(account);
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: { token: deviceToken, notification: { title, body } },
        }),
      },
    );
    if (!res.ok) {
      const errBody = await res.json();
      return { ok: false, reason: JSON.stringify(errBody) };
    }
    return { ok: true };
  } catch (e) {
    return { ok: false, reason: `${e}` };
  }
}

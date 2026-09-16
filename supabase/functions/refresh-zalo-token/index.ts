// refresh-zalo-token
//
// Gia hạn refresh token Zalo theo lịch, KHÔNG phụ thuộc việc có ai gửi hoá
// đơn hay không.
//
// Lý do tồn tại (xem docs/DECISIONS.md Đợt 48): refresh token của Zalo sống
// ~3 tháng và mỗi lần dùng thì Zalo cấp cặp mới (đồng hồ 3 tháng đặt lại từ
// đầu). Nếu chỉ làm mới lúc gửi tin, mà suốt 3 tháng không chủ nhà nào gửi
// hoá đơn qua Zalo, thì token chết hẳn và phải xin cấp lại bằng tay — đúng
// tình huống đã xảy ra thật ngày 16/09/2026. pg_cron gọi hàm này mỗi tuần để
// chuyện đó không lặp lại.
//
// Chỉ cho gọi bằng secret key (pg_cron gọi từ trong database, không phải
// người dùng app) — không mở cho JWT người dùng.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { forceRefreshZaloToken } from "../_shared/zalo.ts";

export default {
  fetch: withSupabase({ auth: ["secret"] }, async (_req, ctx) => {
    try {
      const { expiresAt } = await forceRefreshZaloToken(ctx.supabaseAdmin);
      return Response.json({ refreshed: true, expiresAt });
    } catch (e) {
      // Trả 200 kèm cờ lỗi thay vì 500: pg_cron không có ai đọc lỗi HTTP, ghi
      // rõ lý do vào response/log hữu ích hơn cho lúc truy vết sau này.
      return Response.json({ refreshed: false, reason: `${e}` });
    }
  }),
};

// zalo-miniapp-webhook
//
// Webhook Zalo BẮT BUỘC khai khi phát hành Zalo Mini App (bước "Thiết lập
// chung" của luồng xét duyệt phiên bản). Zalo gọi vào đây khi người dùng
// **rút lại sự đồng ý** hoặc **yêu cầu xoá dữ liệu cá nhân**.
//
// ⚠️ Điểm mấu chốt: Mini App "Hoá đơn BizTown" KHÔNG LƯU BẤT KỲ DỮ LIỆU NGƯỜI
// DÙNG NÀO.
//
// Nó không đăng nhập, không xin quyền nào, không đọc thông tin tài khoản Zalo,
// không ghi gì xuống máy người dùng lẫn máy chủ. Toàn bộ việc nó làm là đọc mã
// tra cứu hoá đơn trên đường dẫn rồi hiện một tấm ảnh do Supabase sinh ra.
//
// Vì vậy sự kiện "xoá dữ liệu" KHÔNG CÓ GÌ ĐỂ XOÁ. Hàm này xác nhận đã nhận
// (HTTP 200 — Zalo cần thấy 200, nếu không sẽ gọi lại nhiều lần) và ghi log để
// còn đối chiếu khi cần chứng minh đã xử lý.
//
// Nếu sau này Mini App có lưu dữ liệu người dùng thật (VD ánh xạ Zalo ID ↔
// người thuê để tự nhận diện), PHẢI viết lại hàm này cho xoá thật.
import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

export default {
  // "none": Zalo gọi từ máy chủ của họ, không mang JWT của dự án này.
  fetch: withSupabase({ auth: ["none"] }, async (req) => {
    // Zalo có thể gọi GET để kiểm tra đường dẫn sống trước khi lưu cấu hình.
    if (req.method === "GET") {
      return Response.json({ ok: true, service: "zalo-miniapp-webhook" });
    }

    let body: unknown = null;
    try {
      body = await req.json();
    } catch {
      // Thân rỗng hoặc không phải JSON — vẫn trả 200, đừng để Zalo gọi lại mãi.
    }

    console.log(
      "[zalo-miniapp-webhook] nhan su kien:",
      JSON.stringify({ method: req.method, body }),
    );

    // Không có dữ liệu người dùng nào được lưu ⇒ không có gì để xoá.
    return Response.json({ ok: true, deleted: false, reason: "no user data stored" });
  }),
};

import { useEffect, useState } from "react";
import { getRouteParams } from "zmp-sdk";
import { Box, Page, Spinner, Text } from "zmp-ui";

import { CODE_PATTERN, INVOICE_IMAGE_BASE } from "@/config";

/// Mini App chỉ hiện ẢNH hoá đơn do Supabase sinh ra — cố ý KHÔNG dựng lại bố
/// cục hoá đơn ở đây.
///
/// Lý do (dungtv chốt 18/09/2026): sửa hoá đơn thì chỉ sửa phía Supabase, Mini
/// App tự đổi theo — không phải build lại, không phải xin Zalo duyệt lại. Ảnh
/// cũng luôn sinh từ dữ liệu mới nhất nên mã QR luôn trỏ đúng tài khoản ngân
/// hàng hiện tại của chủ nhà.
///
/// Mini App KHÔNG cần biết người đang xem là ai: mã tra cứu trên URL đã gắn
/// sẵn người thuê/phòng/kỳ. Nút CTA trong tin ZBS mở Mini App kèm `?code=...`,
/// `getRouteParams()` đọc ra (zmp-sdk ≥ 2.11.0).
type TrangThai = "dang-tai" | "xong" | "loi";

function HomePage() {
  const { code } = getRouteParams();
  const maHopLe = typeof code === "string" && CODE_PATTERN.test(code);
  const [trangThai, setTrangThai] = useState<TrangThai>("dang-tai");

  useEffect(() => {
    // Mã đổi (người thuê mở tin khác) thì phải tải lại từ đầu.
    setTrangThai("dang-tai");
  }, [code]);

  if (!maHopLe) {
    return (
      <ThongBao
        tieuDe="Không mở được hoá đơn"
        noiDung="Đường dẫn thiếu mã hoá đơn. Vui lòng mở lại từ tin nhắn chủ nhà đã gửi."
      />
    );
  }

  return (
    <Page style={{ background: "#EBEEF3", padding: 12, overflowX: "hidden" }}>
      {trangThai === "dang-tai" && (
        <Box flex justifyContent="center" className="py-10">
          <Spinner />
        </Box>
      )}

      {trangThai === "loi" && (
        <ThongBao
          tieuDe="Không tải được hoá đơn"
          noiDung="Hoá đơn có thể đã bị xoá, hoặc mạng đang chậm. Vui lòng thử lại sau ít phút."
        />
      )}

      {/* Luôn gắn thẻ ảnh vào cây (chỉ ẩn đi) để `onLoad`/`onError` chạy được —
          render có điều kiện thì ảnh không bao giờ bắt đầu tải. */}
      <img
        src={`${INVOICE_IMAGE_BASE}/${code}`}
        alt="Hoá đơn tiền trọ"
        onLoad={() => setTrangThai("xong")}
        onError={() => setTrangThai("loi")}
        // Đặt bề rộng bằng style trực tiếp thay vì lớp Tailwind: template sinh
        // sẵn còn cảnh báo cấu hình `content` của Tailwind v3, lớp tiện ích có
        // thể bị loại khi build.
        style={{
          display: trangThai === "xong" ? "block" : "none",
          width: "100%",
          maxWidth: "100%",
          height: "auto",
          borderRadius: 8,
        }}
      />
    </Page>
  );
}

function ThongBao({ tieuDe, noiDung }: { tieuDe: string; noiDung: string }) {
  return (
    <Page
      style={{
        background: "#EBEEF3",
        padding: "48px 24px",
        textAlign: "center",
      }}
    >
      <Text.Title size="normal" style={{ marginBottom: 8 }}>
        {tieuDe}
      </Text.Title>
      <Text size="small" style={{ color: "#5A6386" }}>
        {noiDung}
      </Text>
    </Page>
  );
}

export default HomePage;

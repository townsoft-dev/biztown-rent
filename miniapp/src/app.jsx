import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { getRouteParams } from "zmp-sdk";
import { INVOICE_IMAGE_BASE, CODE_PATTERN } from "./config";

/// Mini App chỉ hiện ẢNH hoá đơn do Supabase sinh ra.
///
/// Không dựng lại bố cục hoá đơn ở đây: sửa hoá đơn thì chỉ sửa phía Supabase,
/// Mini App tự đổi theo, không phải build lại và không phải xin duyệt lại.
function App() {
  // Nút CTA trong tin ZBS mở Mini App kèm `?code=<ma_tra_cuu>`.
  // `getRouteParams()` trả Record<string,string> các tham số truy vấn.
  const { code } = getRouteParams();
  const [state, setState] = useState("loading");

  const hopLe = typeof code === "string" && CODE_PATTERN.test(code);

  useEffect(() => {
    if (!hopLe) setState("bad-code");
  }, [hopLe]);

  if (!hopLe) {
    return (
      <Khung>
        Không đọc được mã hoá đơn. Vui lòng mở lại từ tin nhắn chủ nhà gửi.
      </Khung>
    );
  }

  return (
    <div style={{ background: "#EBEEF3", minHeight: "100vh", padding: 12 }}>
      {state === "loading" && <Khung>Đang tải hoá đơn…</Khung>}
      {state === "error" && (
        <Khung>
          Không tải được hoá đơn. Hoá đơn có thể đã bị xoá, hoặc mạng đang chậm —
          thử mở lại sau ít phút.
        </Khung>
      )}
      <img
        src={`${INVOICE_IMAGE_BASE}/${code}`}
        alt="Hoá đơn tiền trọ"
        onLoad={() => setState("ok")}
        onError={() => setState("error")}
        style={{
          display: state === "ok" ? "block" : "none",
          width: "100%",
          height: "auto",
          borderRadius: 8,
        }}
      />
    </div>
  );
}

function Khung({ children }) {
  return (
    <div
      style={{
        padding: 24,
        textAlign: "center",
        color: "#5A6386",
        fontSize: 14,
        lineHeight: 1.5,
        fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
      }}
    >
      {children}
    </div>
  );
}

createRoot(document.getElementById("app")).render(<App />);

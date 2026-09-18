// Dựng ẢNH hoá đơn (PNG) theo đúng frame Figma `MOCK-IMG` (node `526:2485`).
//
// Vì sao là ảnh chứ không phải trang web: cổng Supabase ép mọi phản hồi về
// `text/plain` kèm CSP `default-src 'none'; sandbox`, nên HTML hiện ra mã
// nguồn và SVG mở ra trắng trơn (đã thử thật 17/09/2026, xem `invoice-qr`).
// PNG là ảnh thuần nên không dính CSP — đây là thứ DUY NHẤT phục vụ được.
//
// Cách dựng: ghép chuỗi SVG rồi rasterise bằng `resvg` bản WASM. Toàn bộ toạ
// độ/cỡ chữ lấy từ metadata của frame Figma, màu đọc pixel trực tiếp trên bản
// render — không ước lượng bằng mắt.
import { LOGO_ON_NAVY, LOGO_VIEWBOX } from "./invoice_image_logo.ts";

// ---- Màu, đọc pixel từ bản render Figma `526:2485` (18/09/2026) ----
export const NAVY = "#23305E";
const CAM = "#EF9F27";
const NHAN = "#6F7D99"; // nhãn cột trái
const NHAN_PHU = "#5A6B8A"; // dòng phí con "– Phí dịch vụ"
const KE = "#EEF0F5"; // đường kẻ ngang
const TONG_NEN = "#FCEFE4";
const TONG_CHU = "#C9662A";
const HAN_DO = "#B0402E";
const QR_VIEN = "#D6DAE6";
const THE_NEN = "#F3F4F8";
const FOOTER_CHU = "#A4A9BD";

const W = 375; // bề ngang frame Figma
const FONT = "Be Vietnam Pro";

const esc = (s: string) =>
  s.replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!)
  );

const vnd = (n: number) =>
  new Intl.NumberFormat("vi-VN").format(Math.round(n)) + "đ";
const day = (s: string) => s.split("-").reverse().join("/");

/** 1 dòng nhãn–giá trị: nhãn canh trái, giá trị canh phải. */
function row(
  y: number,
  label: string,
  value: string,
  o: {
    size?: number;
    labelColor?: string;
    valueColor?: string;
    indent?: number;
    valueSize?: number;
  } = {},
): string {
  const size = o.size ?? 13;
  return `<text x="${24 + (o.indent ?? 0)}" y="${y}" font-size="${size}" fill="${
    o.labelColor ?? NHAN
  }">${esc(label)}</text>` +
    (value
      ? `<text x="${W - 24}" y="${y}" font-size="${
        o.valueSize ?? size
      }" font-weight="700" fill="${
        o.valueColor ?? NAVY
      }" text-anchor="end">${esc(value)}</text>`
      : "");
}

export type Fee = { name: string; amount: number };

export type InvoiceImageData = {
  houseName: string;
  rooms: string;
  tenantName: string;
  periodStart: string;
  dueDate: string;
  invoiceCode: string;
  rent: number;
  electricity: { usage: number | null; amount: number } | null;
  water: { usage: number | null; amount: number } | null;
  fees: Fee[];
  total: number;
  paid: boolean;
  bank: { name: string; accountNumber: string; accountName: string } | null;
  qrMatrix: { size: number; data: Uint8Array } | null;
};

/** Vẽ ma trận QR thành các ô vuông SVG, vừa khít hộp `box` pixel. */
function qrSvg(
  m: { size: number; data: Uint8Array },
  x0: number,
  y0: number,
  box: number,
): string {
  const cell = box / m.size;
  let d = "";
  for (let r = 0; r < m.size; r++) {
    for (let c = 0; c < m.size; c++) {
      if (m.data[r * m.size + c]) {
        // +0.5 để các ô liền nhau không hở đường chỉ trắng khi rasterise.
        d += `M${(x0 + c * cell).toFixed(2)},${(y0 + r * cell).toFixed(2)}h${
          (cell + 0.5).toFixed(2)
        }v${(cell + 0.5).toFixed(2)}h-${(cell + 0.5).toFixed(2)}z`;
      }
    }
  }
  return `<rect x="${x0 - 6}" y="${y0 - 6}" width="${box + 12}" height="${
    box + 12
  }" fill="#ffffff"/><path d="${d}" fill="#000000"/>`;
}

export function buildInvoiceSvg(d: InvoiceImageData): string {
  const badge = d.paid ? "Đã thanh toán" : "Chưa thanh toán";
  const badgeW = d.paid ? 104 : 117;

  // --- Khối chi tiết tính tiền: cao bao nhiêu tuỳ số dòng phí ---
  const lines: { label: string; value: string; indent?: number }[] = [];
  lines.push({ label: "Tiền phòng", value: vnd(d.rent) });
  if (d.electricity) {
    lines.push({
      label: d.electricity.usage != null
        ? `Tiền điện (${d.electricity.usage} kWh)`
        : "Tiền điện",
      value: vnd(d.electricity.amount),
    });
  }
  if (d.water) {
    lines.push({
      label: d.water.usage != null
        ? `Tiền nước (${d.water.usage} m³)`
        : "Tiền nước",
      value: vnd(d.water.amount),
    });
  }
  if (d.fees.length) {
    lines.push({ label: "Phí khác", value: "" });
    for (const f of d.fees) {
      lines.push({ label: `– ${f.name}`, value: vnd(f.amount), indent: 16 });
    }
  }

  // Figma: các dòng chính cách nhau 24px, dòng phí con cách 23px.
  //
  // Đường cơ sở dòng đầu = 264 chứ không phải 285 như Figma: khối thông tin
  // phía trên của ta chỉ có 2 dòng (Người thuê, Mã hoá đơn) trong khi Figma có
  // 3 — dòng "Mã hợp đồng" bị bỏ vì schema chưa có trường này (đã ghi ở
  // DECISIONS Đợt 60). Giữ nguyên 285 thì thừa ra một mảng trắng giữa đường kẻ
  // và bảng tiền. Khoảng cách 22px (dòng cuối → đường kẻ) và 28px (đường kẻ →
  // dòng tiền đầu) vẫn đúng như Figma.
  let y = 264;
  let body = "";
  for (const l of lines) {
    body += row(y, l.label, l.value, {
      indent: l.indent,
      labelColor: l.indent ? NHAN_PHU : NHAN,
      size: l.indent ? 12.5 : 13,
    });
    y += l.indent ? 23 : 24;
  }

  const tongY = y + 8; // đỉnh hộp TỔNG CỘNG
  const hanY = tongY + 53 + 24; // dòng "Hạn thanh toán"
  const qrTop = hanY + 12;
  const qrH = d.bank ? 355 : 240;
  // Figma: khung QR kết thúc y=875, chữ chân trang có đường cơ sở y≈962,
  // hết ảnh ở y=997 — tức cách 87px bên trên và 35px bên dưới.
  const footY = qrTop + qrH + 87;
  const H = footY + 35;

  const qrBox = 176;
  const qrX = 24 + 75.5;
  const qrY = qrTop + 49.5;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" font-family="${FONT}">
  <rect width="${W}" height="${H}" fill="#ffffff"/>

  <rect width="${W}" height="165" fill="${NAVY}"/>
  <svg x="24" y="20" width="164" height="55" viewBox="${LOGO_VIEWBOX}" preserveAspectRatio="xMinYMid meet">${LOGO_ON_NAVY}</svg>
  <text x="24" y="105" font-size="18" font-weight="700" fill="#ffffff">Hoá đơn tiền trọ</text>
  <text x="24" y="127" font-size="12" fill="#AEBBD4">${
    esc(`${d.houseName} · Phòng ${d.rooms}`)
  }</text>
  <text x="24" y="143" font-size="12" fill="#AEBBD4">${
    esc(`Kỳ ${d.periodStart.slice(5, 7)}/${d.periodStart.slice(0, 4)}`)
  }</text>
  <rect x="${W - 24 - badgeW}" y="88" width="${badgeW}" height="24" rx="12" fill="${CAM}"/>
  <text x="${W - 24 - badgeW / 2}" y="104" font-size="11" font-weight="700" fill="${NAVY}" text-anchor="middle">${badge}</text>

  ${row(193, "Người thuê", d.tenantName)}
  ${row(214, "Mã hoá đơn", d.invoiceCode)}

  <rect x="24" y="236" width="${W - 48}" height="1" fill="${KE}"/>

  ${body}

  <rect x="24" y="${tongY}" width="${W - 48}" height="53" rx="10" fill="${TONG_NEN}"/>
  <text x="40" y="${tongY + 32}" font-size="13" font-weight="700" fill="${NAVY}">TỔNG CỘNG</text>
  <text x="${W - 40}" y="${tongY + 34}" font-size="20" font-weight="700" fill="${TONG_CHU}" text-anchor="end">${
    vnd(d.total)
  }</text>

  <text x="24" y="${hanY}" font-size="13" font-weight="700" fill="${HAN_DO}">Hạn thanh toán</text>
  <text x="${W - 24}" y="${hanY}" font-size="13" font-weight="700" fill="${HAN_DO}" text-anchor="end">${
    day(d.dueDate)
  }</text>

  <rect x="24" y="${qrTop}" width="${W - 48}" height="${qrH}" rx="10" fill="none" stroke="${QR_VIEN}" stroke-width="1" stroke-dasharray="4 3"/>
  <text x="${W / 2}" y="${qrTop + 34}" font-size="13" font-weight="700" fill="${NAVY}" text-anchor="middle">Quét mã để thanh toán qua VietQR</text>
  ${d.qrMatrix ? qrSvg(d.qrMatrix, qrX, qrY, qrBox) : ""}
  ${
    d.bank
      ? `<rect x="44" y="${qrTop + 237}" width="287" height="96" rx="8" fill="${THE_NEN}"/>
  ${bankRow(qrTop + 261, "Ngân hàng", d.bank.name)}
  ${bankRow(qrTop + 280, "Số tài khoản", d.bank.accountNumber)}
  ${bankRow(qrTop + 299, "Chủ tài khoản", d.bank.accountName)}
  ${bankRow(qrTop + 318, "Nội dung CK", d.invoiceCode)}`
      : ""
  }

  <text x="24" y="${footY}" font-size="11" fill="${FOOTER_CHU}">BizTown Rent Manager · townsoftvina.com</text>
</svg>`;
}

function bankRow(y: number, label: string, value: string): string {
  return `<text x="58" y="${y}" font-size="12" fill="${NHAN}">${
    esc(label)
  }</text><text x="317" y="${y}" font-size="12" font-weight="700" fill="${NAVY}" text-anchor="end">${
    esc(value)
  }</text>`;
}

// Static VietQR / NAPAS-247 payload builder (EMVCo Merchant Presented QR).
// Public open standard — no third-party account/API needed for a static QR,
// unlike SMS/Zalo. Xem docs/BUSINESS-RULES.md BR-BILL-10.
//
// Verify against a real bank's official VietQR sample before relying on this
// in production — implemented from the published EMVCo/NAPAS TLV spec, not
// tested against a live bank QR reader yet.

interface VietQrInput {
  bankBin: string; // NAPAS bank BIN, e.g. "970436" for Vietcombank
  accountNumber: string;
  amount: number; // VND, whole number (no decimals)
  message?: string; // optional purpose / bill reference, shown to payer
  merchantName?: string; // beneficiary account name, uppercase no diacritics recommended
}

function tlv(id: string, value: string): string {
  const length = value.length.toString().padStart(2, '0');
  return `${id}${length}${value}`;
}

// CRC-16/CCITT-FALSE: poly 0x1021, init 0xFFFF, no reflect, xorout 0x0000.
function crc16CcittFalse(input: string): string {
  let crc = 0xffff;
  for (let i = 0; i < input.length; i++) {
    crc ^= input.charCodeAt(i) << 8;
    for (let bit = 0; bit < 8; bit++) {
      crc = (crc & 0x8000) !== 0 ? ((crc << 1) ^ 0x1021) & 0xffff : (crc << 1) & 0xffff;
    }
  }
  return crc.toString(16).toUpperCase().padStart(4, '0');
}

export function buildVietQrPayload(input: VietQrInput): string {
  const beneficiaryOrg = tlv('00', input.bankBin) + tlv('01', input.accountNumber);
  const merchantAccountInfo =
    tlv('00', 'A000000727') + // NAPAS AID
    tlv('01', beneficiaryOrg) +
    tlv('02', 'QRIBFTTA'); // transfer-to-account service code

  let payload =
    tlv('00', '01') + // Payload Format Indicator
    tlv('01', '11') + // Point of Initiation Method: 11 = static
    tlv('38', merchantAccountInfo) +
    tlv('52', '0000') + // Merchant Category Code, generic
    tlv('53', '704') + // Currency: VND
    tlv('54', String(Math.round(input.amount))) +
    tlv('58', 'VN') +
    tlv('59', (input.merchantName ?? 'BIZTOWN RENT MANAGER').slice(0, 25)) +
    tlv('60', 'HO CHI MINH');

  if (input.message) {
    payload += tlv('62', tlv('08', input.message.slice(0, 25)));
  }

  const payloadWithCrcTag = payload + '6304'; // CRC tag id "63" + length "04", value appended next
  const crc = crc16CcittFalse(payloadWithCrcTag);
  return payloadWithCrcTag + crc;
}

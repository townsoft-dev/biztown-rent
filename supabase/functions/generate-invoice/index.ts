// generate-invoice
//
// Tạo Invoice (đơn lẻ hoặc hàng loạt) từ chỉ số điện/nước đã ghi sẵn + điều khoản
// hợp đồng hiện hành. Công thức theo docs/BUSINESS-RULES.md mục 1 (BR-BILL-01..13).
//
// Request:
//   { mode: "single", contractId: string, periodYm: string ("YYYY-MM-01") }
//   { mode: "batch", houseId: string, periodYm: string }
//
// BR-BILL-11: hàng loạt bỏ qua hoàn toàn hợp đồng thiếu chỉ số kỳ đó, không ước lượng.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { buildVietQrPayload } from "../_shared/vietqr.ts";

type BillingMethod = "BY_READING" | "FLAT" | "NOT_BILLED";

interface ContractVersion {
  id: string;
  contract_id: string;
  monthly_rent: number;
  electricity_unit_price: number | null;
  water_unit_price: number | null;
  electricity_billing_method: BillingMethod;
  water_billing_method: BillingMethod;
  electricity_flat_amount: number | null;
  water_flat_amount: number | null;
  recurring_fees: { name: string; amount: number }[];
  rent_cycle_months: number;
  rent_cycle_anchor_ym: string;
  payment_due_day_of_month: number;
  service_fee_amount: number | null;
}

interface UtilityLine {
  roomId: string;
  roomNo: string;
  utilityType: "electricity" | "water";
  previousReading: number | null;
  currentReading: number | null;
  usageAmount: number | null;
  unitPrice: number | null;
  totalAmount: number;
  readingId: string | null;
}

function addMonths(ymDate: string, months: number): string {
  const d = new Date(ymDate + "T00:00:00Z");
  d.setUTCMonth(d.getUTCMonth() + months);
  return d.toISOString().slice(0, 10);
}

function monthsBetween(fromYm: string, toYm: string): number {
  const a = new Date(fromYm + "T00:00:00Z");
  const b = new Date(toYm + "T00:00:00Z");
  return (b.getUTCFullYear() - a.getUTCFullYear()) * 12 + (b.getUTCMonth() - a.getUTCMonth());
}

function isRentCyclePeriod(version: ContractVersion, periodYm: string): boolean {
  const diff = monthsBetween(version.rent_cycle_anchor_ym, periodYm);
  return diff >= 0 && diff % version.rent_cycle_months === 0;
}

function dueDateForPeriod(periodYm: string, dayOfMonth: number): string {
  const d = new Date(periodYm + "T00:00:00Z");
  const lastDay = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)).getUTCDate();
  d.setUTCDate(Math.min(dayOfMonth, lastDay));
  return d.toISOString().slice(0, 10);
}

function periodBounds(periodYm: string): { start: string; end: string; daysInMonth: number } {
  const start = new Date(periodYm + "T00:00:00Z");
  const daysInMonth = new Date(Date.UTC(start.getUTCFullYear(), start.getUTCMonth() + 1, 0)).getUTCDate();
  const end = new Date(Date.UTC(start.getUTCFullYear(), start.getUTCMonth(), daysInMonth));
  return { start: start.toISOString().slice(0, 10), end: end.toISOString().slice(0, 10), daysInMonth };
}

/** Tìm chỉ số "đóng kỳ" cho 1 phòng trong 1 kỳ: ưu tiên PERIODIC của đúng kỳ, hoặc
 * MOVE_OUT của chính hợp đồng này nếu hợp đồng kết thúc trong kỳ đó. */
async function findClosingReading(
  supabaseAdmin: any,
  table: "tb_electricity_reading" | "tb_water_reading",
  roomId: string,
  contractId: string,
  periodYm: string,
) {
  const { data: periodic } = await supabaseAdmin
    .from(table)
    .select("id, current_reading, previous_reading_id")
    .eq("room_id", roomId)
    .eq("period_ym", periodYm)
    .eq("reading_type", "PERIODIC")
    .maybeSingle();
  if (periodic) return periodic;

  const { data: moveOut } = await supabaseAdmin
    .from(table)
    .select("id, current_reading, previous_reading_id")
    .eq("room_id", roomId)
    .eq("contract_id", contractId)
    .eq("reading_type", "MOVE_OUT")
    .eq("period_ym", periodYm)
    .maybeSingle();
  return moveOut ?? null;
}

async function previousReadingValue(supabaseAdmin: any, table: string, previousReadingId: string | null) {
  if (!previousReadingId) return null;
  const { data } = await supabaseAdmin.from(table).select("current_reading").eq("id", previousReadingId).single();
  return data?.current_reading ?? null;
}

/** Sinh 1 hoá đơn cho 1 hợp đồng + 1 kỳ. Trả về { invoice } hoặc { skipped: reason }. */
async function generateSingleInvoice(supabaseAdmin: any, contractId: string, periodYm: string) {
  const { data: contract } = await supabaseAdmin
    .from("tb_contract")
    .select("id, current_version_id, status")
    .eq("id", contractId)
    .single();
  if (!contract || contract.status !== "Active") {
    return { skipped: { contractId, reason: "Hợp đồng không tồn tại hoặc không Active" } };
  }

  const { data: version } = await supabaseAdmin
    .from("tb_contract_version")
    .select("*")
    .eq("id", contract.current_version_id)
    .single<ContractVersion>();
  if (!version) return { skipped: { contractId, reason: "Không tìm thấy điều khoản hợp đồng hiện hành" } };

  const { data: contractRooms } = await supabaseAdmin
    .from("tb_contract_room")
    .select("room_id, tb_room(id, room_no, house_id)")
    .eq("contract_id", contractId);
  if (!contractRooms || contractRooms.length === 0) {
    return { skipped: { contractId, reason: "Hợp đồng không có phòng nào" } };
  }

  const utilityLines: UtilityLine[] = [];
  const missing: string[] = [];
  const readingUpdates: { table: string; id: string }[] = [];

  for (const cr of contractRooms) {
    const room = cr.tb_room;
    for (const [utilityType, table, method, unitPrice, flatAmount] of [
      ["electricity", "tb_electricity_reading", version.electricity_billing_method, version.electricity_unit_price, version.electricity_flat_amount],
      ["water", "tb_water_reading", version.water_billing_method, version.water_unit_price, version.water_flat_amount],
    ] as const) {
      if (method === "NOT_BILLED") continue;

      if (method === "FLAT") {
        utilityLines.push({
          roomId: room.id,
          roomNo: room.room_no,
          utilityType,
          previousReading: null,
          currentReading: null,
          usageAmount: null,
          unitPrice: null,
          totalAmount: flatAmount ?? 0,
          readingId: null,
        });
        continue;
      }

      // BY_READING
      const closing = await findClosingReading(supabaseAdmin, table, room.id, contractId, periodYm);
      if (!closing) {
        missing.push(`Phòng ${room.room_no} — thiếu chỉ số ${utilityType === "electricity" ? "điện" : "nước"} kỳ ${periodYm}`);
        continue;
      }
      const previous = await previousReadingValue(supabaseAdmin, table, closing.previous_reading_id);
      const usage = previous !== null ? closing.current_reading - previous : null;
      const total = usage !== null && unitPrice !== null ? usage * unitPrice : 0;
      utilityLines.push({
        roomId: room.id,
        roomNo: room.room_no,
        utilityType,
        previousReading: previous,
        currentReading: closing.current_reading,
        usageAmount: usage,
        unitPrice,
        totalAmount: total,
        readingId: closing.id,
      });
      readingUpdates.push({ table, id: closing.id });
    }
  }

  // BR-BILL-11: thiếu bất kỳ chỉ số nào của hợp đồng này -> bỏ qua toàn bộ, không tạo.
  if (missing.length > 0) {
    return { skipped: { contractId, reason: missing.join("; ") } };
  }

  // BR-BILL-07/08: tiền nhà chỉ ở đúng chu kỳ, prorate nếu MOVE_IN/MOVE_OUT rơi trong kỳ.
  let rentAmount = 0;
  if (isRentCyclePeriod(version, periodYm)) {
    const { start, end, daysInMonth } = periodBounds(periodYm);
    // TODO: prorate chính xác cần biết ngày MOVE_IN/MOVE_OUT thực tế của contract trong kỳ này
    // (tra qua tb_electricity_reading/tb_water_reading reading_type=MOVE_IN|MOVE_OUT, reading_date).
    // Bản này tạm tính trọn tháng — bổ sung prorate khi có UI xác nhận cách làm tròn ngày.
    rentAmount = version.monthly_rent;
    void start;
    void end;
    void daysInMonth;
  }

  // BR-BILL-08: phí dịch vụ + phí định kỳ tính trọn 100%, không chia ngày, chỉ khi hợp đồng Active.
  const serviceFeeAmount = version.service_fee_amount ?? 0;
  const recurringFeesTotal = (version.recurring_fees ?? []).reduce((sum, f) => sum + f.amount, 0);
  const utilityTotal = utilityLines.reduce((sum, l) => sum + l.totalAmount, 0);
  const totalAmount = rentAmount + utilityTotal + serviceFeeAmount + recurringFeesTotal;

  const { start, end } = periodBounds(periodYm);
  const dueDate = dueDateForPeriod(periodYm, version.payment_due_day_of_month);

  const { data: house } = await supabaseAdmin
    .from("tb_house")
    .select("id, name, bank_bin, bank_account_number, bank_account_name")
    .eq("id", contractRooms[0].tb_room.house_id)
    .single();

  const { data: tenant } = await supabaseAdmin
    .from("tb_tenant")
    .select("full_name")
    .eq(
      "id",
      (await supabaseAdmin.from("tb_contract").select("tenant_id").eq("id", contractId).single()).data.tenant_id,
    )
    .single();

  const paymentQrPayload = house?.bank_bin && house?.bank_account_number
    ? buildVietQrPayload({
        bankBin: house.bank_bin,
        accountNumber: house.bank_account_number,
        amount: totalAmount,
        merchantName: house.bank_account_name ?? undefined,
        message: `${house.name ?? ""} ${periodYm}`.trim(),
      })
    : null;

  const { data: invoice, error: insertError } = await supabaseAdmin
    .from("tb_invoice")
    .insert({
      contract_id: contractId,
      contract_version_id: version.id,
      house_id: house.id,
      house_name: house.name,
      room_nos: contractRooms.map((cr: any) => cr.tb_room.room_no),
      tenant_name: tenant?.full_name ?? "",
      period_start: start,
      period_end: end,
      due_date: dueDate,
      rent_amount: rentAmount,
      utility_lines: utilityLines,
      service_fee_amount: serviceFeeAmount,
      recurring_fees: version.recurring_fees ?? [],
      other_fees: [],
      total_amount: totalAmount,
      payment_qr_payload: paymentQrPayload,
      status: "Draft",
    })
    .select()
    .single();

  if (insertError) return { skipped: { contractId, reason: insertError.message } };

  // Đóng vai trò "to" cho các chỉ số vừa dùng — BR-READ-04 (isLocked derived qua invoice_id).
  for (const u of readingUpdates) {
    await supabaseAdmin.from(u.table).update({ invoice_id: invoice.id }).eq("id", u.id);
  }

  return { invoice };
}

export default {
  fetch: withSupabase({ auth: ["secret"] }, async (req, ctx) => {
    const body = await req.json();

    if (body.mode === "single") {
      const result = await generateSingleInvoice(ctx.supabaseAdmin, body.contractId, body.periodYm);
      return Response.json(result);
    }

    if (body.mode === "batch") {
      // BR-BILL-11: mọi hợp đồng Active của 1 nhà, trong 1 kỳ.
      const { data: rooms } = await ctx.supabaseAdmin.from("tb_room").select("id").eq("house_id", body.houseId);
      const roomIds: string[] = (rooms ?? []).map((r: any) => r.id);
      const { data: contractRoomRows } = await ctx.supabaseAdmin
        .from("tb_contract_room")
        .select("contract_id")
        .in("room_id", roomIds)
        .eq("is_active", true);
      const contractIds = [...new Set((contractRoomRows ?? []).map((cr: any) => cr.contract_id))];

      const created = [];
      const skipped = [];
      for (const contractId of contractIds) {
        const result = await generateSingleInvoice(ctx.supabaseAdmin, contractId, body.periodYm);
        if ("invoice" in result) created.push(result.invoice);
        else skipped.push(result.skipped);
      }
      return Response.json({ created, skipped });
    }

    return Response.json({ error: "mode phải là 'single' hoặc 'batch'" }, { status: 400 });
  }),
};

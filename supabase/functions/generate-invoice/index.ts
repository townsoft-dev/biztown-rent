// generate-invoice
//
// Tạo Invoice (đơn lẻ hoặc hàng loạt) từ chỉ số điện/nước đã ghi sẵn + điều khoản
// hợp đồng hiện hành. Công thức theo docs/BUSINESS-RULES.md mục 1 (BR-BILL-01..13).
//
// Request:
//   { mode: "single", contractId: string, periodYm: string ("YYYY-MM-01") }
//   { mode: "batch", houseId: string, periodYm: string }
//   { mode: "previewBatch", houseId: string, periodYm: string } — B-03: tính thử
//     số tiền + trạng thái từng hợp đồng, KHÔNG ghi DB (xem `generateSingleInvoice`).
//   { mode: "batchSend", houseId, periodYm, contractIds: string[], send: boolean }
//     — B-03 "Save all as draft"/"Create & send all": tạo hoá đơn cho ĐÚNG danh
//     sách hợp đồng đã chọn (không phải toàn bộ nhà như "batch"), rồi nếu
//     `send=true` gửi SMS thật + cập nhật status→Sent — chạy HẲN phía backend
//     (dungtv xác nhận 2026-09-14: không để frontend giữ vòng lặp, vì app có
//     thể bị hệ điều hành tạm dừng giữa chừng nếu người dùng khoá màn hình/
//     chuyển app lúc đang chạy — xem docs/DECISIONS.md).
//
// BR-BILL-11: hàng loạt bỏ qua hoàn toàn hợp đồng thiếu chỉ số kỳ đó, không ước lượng.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { sendSmsViaEsms } from "../_shared/esms.ts";
import { buildInvoiceSmsMessage } from "../_shared/invoice_message.ts";
import { fanOutNotification } from "../_shared/notifications.ts";

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

  // period_ym của MOVE_OUT lưu đúng ngày trả phòng thật (không phải ngày 1
  // đầu tháng) — lọc theo khoảng ngày của tháng, không `eq` thẳng periodYm.
  const { start, end } = periodBounds(periodYm);
  const { data: moveOut } = await supabaseAdmin
    .from(table)
    .select("id, current_reading, previous_reading_id")
    .eq("room_id", roomId)
    .eq("contract_id", contractId)
    .eq("reading_type", "MOVE_OUT")
    .gte("reading_date", start)
    .lte("reading_date", end)
    .maybeSingle();
  return moveOut ?? null;
}

/** Ngày sớm nhất ghi nhận MOVE_IN/MOVE_OUT của hợp đồng này trong kỳ (nếu có) —
 * dò cả 2 bảng điện/nước vì phòng có thể NOT_BILLED ở 1 trong 2 loại.
 * Lọc theo KHOẢNG ngày của tháng (`reading_date`), KHÔNG so `period_ym` bằng
 * `eq` — `period_ym` của MOVE_IN/MOVE_OUT lưu đúng NGÀY sự kiện thật (xem
 * `reading_repository.dart` `_createMoveInOrOut`), không phải ngày 1 đầu
 * tháng như PERIODIC, nên so `eq` với `periodYm` ("YYYY-MM-01") sẽ luôn trật
 * trừ khi tenant dọn vào/ra đúng ngày 1. */
async function findContractEventDate(
  supabaseAdmin: any,
  contractId: string,
  periodYm: string,
  eventType: "MOVE_IN" | "MOVE_OUT",
): Promise<string | null> {
  const { start, end } = periodBounds(periodYm);
  let earliest: string | null = null;
  for (const table of ["tb_electricity_reading", "tb_water_reading"]) {
    const { data } = await supabaseAdmin
      .from(table)
      .select("reading_date")
      .eq("contract_id", contractId)
      .eq("reading_type", eventType)
      .gte("reading_date", start)
      .lte("reading_date", end)
      .order("reading_date", { ascending: true })
      .limit(1)
      .maybeSingle();
    const date = data?.reading_date ?? null;
    if (date && (!earliest || date < earliest)) earliest = date;
  }
  return earliest;
}

async function previousReadingValue(supabaseAdmin: any, table: string, previousReadingId: string | null) {
  if (!previousReadingId) return null;
  const { data } = await supabaseAdmin.from(table).select("current_reading").eq("id", previousReadingId).single();
  return data?.current_reading ?? null;
}

/** Sinh 1 hoá đơn cho 1 hợp đồng + 1 kỳ.
 * Trả về `{ invoice }` (tạo thật), `{ invoice, alreadyExisted: true }` (kỳ này
 * đã có hoá đơn từ trước — KHÔNG tạo trùng), `{ skipped: reason }` (thiếu chỉ
 * số/hợp đồng không hợp lệ), hoặc — khi `opts.dryRun` — `{ preview }` (tính
 * thử số tiền, KHÔNG ghi DB, dùng cho B-03 xem trước trước khi chọn tạo).
 */
async function generateSingleInvoice(
  supabaseAdmin: any,
  contractId: string,
  periodYm: string,
  opts: { dryRun?: boolean } = {},
) {
  const { data: contract } = await supabaseAdmin
    .from("tb_contract")
    .select("id, current_version_id, status, tenant_id")
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
  const roomNos = contractRooms.map((cr: any) => cr.tb_room.room_no);

  const { data: tenant } = await supabaseAdmin
    .from("tb_tenant")
    .select("full_name")
    .eq("id", contract.tenant_id)
    .single();
  const tenantName = tenant?.full_name ?? "";

  // Kỳ này đã có hoá đơn rồi (bất kể trạng thái) -> không tạo trùng, trả về
  // hoá đơn đã có luôn (B-02 mở lại màn cho kỳ đã tạo cũng đi qua nhánh này).
  const { start, end } = periodBounds(periodYm);
  const { data: existingInvoice } = await supabaseAdmin
    .from("tb_invoice")
    .select()
    .eq("contract_id", contractId)
    .eq("period_start", start)
    .maybeSingle();
  if (existingInvoice) {
    return { invoice: existingInvoice, alreadyExisted: true };
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
    return { skipped: { contractId, reason: missing.join("; "), roomNos, tenantName } };
  }

  // BR-BILL-07/08: tiền nhà chỉ ở đúng chu kỳ, prorate theo ngày ở thực tế nếu
  // MOVE_IN/MOVE_OUT rơi trong kỳ này (kỳ đầu tính từ ngày MOVE_IN, kỳ cuối tính
  // đến ngày MOVE_OUT — cả 2 có thể cùng rơi vào 1 kỳ với hợp đồng ngắn hạn).
  let rentAmount = 0;
  if (isRentCyclePeriod(version, periodYm)) {
    const { daysInMonth } = periodBounds(periodYm);
    const moveInDate = await findContractEventDate(supabaseAdmin, contractId, periodYm, "MOVE_IN");
    const moveOutDate = await findContractEventDate(supabaseAdmin, contractId, periodYm, "MOVE_OUT");

    if (!moveInDate && !moveOutDate) {
      rentAmount = version.monthly_rent;
    } else {
      const startDay = moveInDate ? new Date(moveInDate + "T00:00:00Z").getUTCDate() : 1;
      const endDay = moveOutDate ? new Date(moveOutDate + "T00:00:00Z").getUTCDate() : daysInMonth;
      const daysOccupied = Math.max(0, endDay - startDay + 1);
      rentAmount = Math.round((version.monthly_rent * daysOccupied) / daysInMonth);
    }
  }

  // BR-BILL-08: phí dịch vụ + phí định kỳ tính trọn 100%, không chia ngày, chỉ khi hợp đồng Active.
  const serviceFeeAmount = version.service_fee_amount ?? 0;
  const recurringFeesTotal = (version.recurring_fees ?? []).reduce((sum, f) => sum + f.amount, 0);
  const utilityTotal = utilityLines.reduce((sum, l) => sum + l.totalAmount, 0);
  const totalAmount = rentAmount + utilityTotal + serviceFeeAmount + recurringFeesTotal;

  // B-03 preview: chỉ cần số tiền ước tính, KHÔNG ghi DB (không tính QR/due
  // date/nhà — những thứ đó chỉ cần khi tạo thật).
  if (opts.dryRun) {
    return { preview: { contractId, roomNos, tenantName, totalAmount } };
  }

  const dueDate = dueDateForPeriod(periodYm, version.payment_due_day_of_month);

  const { data: house } = await supabaseAdmin
    .from("tb_house")
    .select("id, name, bank_bin, bank_account_number, bank_account_name")
    .eq("id", contractRooms[0].tb_room.house_id)
    .single();

  // KHÔNG lưu sẵn chuỗi QR vào hoá đơn nữa (bỏ từ 16/09/2026).
  //
  // Chuỗi QR chứa số tài khoản chủ nhà. Lưu sẵn tức là chụp lại tài khoản tại
  // thời điểm tạo hoá đơn — chủ trọ đổi số tài khoản sau đó thì chuỗi cũ KHÔNG
  // được cập nhật, người thuê quét vào là chuyển tiền sang tài khoản đã bỏ.
  // Dữ liệu thật đã dính đúng lỗi này (xem changelog/2026-09-16.md).
  //
  // Thay vào đó, QR được sinh TẠI THỜI ĐIỂM NGƯỜI THUÊ XEM, trong Edge Function
  // `invoice-public` — luôn lấy tài khoản hiện hành. Sinh chuỗi QR chỉ là phép
  // ghép chuỗi, gần như không tốn gì, nên không có lý do phải lưu sẵn.

  const { data: invoice, error: insertError } = await supabaseAdmin
    .from("tb_invoice")
    .insert({
      contract_id: contractId,
      contract_version_id: version.id,
      house_id: house.id,
      house_name: house.name,
      room_nos: roomNos,
      tenant_name: tenantName,
      period_start: start,
      period_end: end,
      due_date: dueDate,
      rent_amount: rentAmount,
      utility_lines: utilityLines,
      service_fee_amount: serviceFeeAmount,
      recurring_fees: version.recurring_fees ?? [],
      other_fees: [],
      total_amount: totalAmount,
      status: "Draft",
    })
    .select()
    .single();

  if (insertError) return { skipped: { contractId, reason: insertError.message } };

  // Đóng vai trò "to" cho các chỉ số vừa dùng — BR-READ-04 (isLocked derived qua invoice_id).
  for (const u of readingUpdates) {
    await supabaseAdmin.from(u.table).update({ invoice_id: invoice.id }).eq("id", u.id);
  }

  // BR-NOTI-01: báo cho mọi người có quyền trên nhà đó biết hoá đơn mới vừa
  // tạo (không phụ thuộc việc có gửi SMS cho Tenant hay không).
  await fanOutNotification(supabaseAdmin, {
    houseId: house.id,
    type: "invoice_sent",
    payload: { roomNos, tenantName, amount: totalAmount },
    targetInvoiceId: invoice.id,
  });

  return { invoice };
}

/** Mọi hợp đồng Active của 1 Nhà — dùng chung cho `mode: "batch"`/`"previewBatch"`. */
async function activeContractIdsForHouse(supabaseAdmin: any, houseId: string): Promise<string[]> {
  const { data: rooms } = await supabaseAdmin.from("tb_room").select("id").eq("house_id", houseId);
  const roomIds: string[] = (rooms ?? []).map((r: any) => r.id);
  const { data: contractRoomRows } = await supabaseAdmin
    .from("tb_contract_room")
    .select("contract_id")
    .in("room_id", roomIds)
    .eq("is_active", true);
  return [...new Set((contractRoomRows ?? []).map((cr: any) => cr.contract_id))] as string[];
}

export default {
  // "user": app gọi thật bằng JWT chủ nhà/quản lý (mobile không được nhúng
  // secret key) — tự kiểm tra quyền qua `ctx.supabase` (RLS-scoped, policy
  // "Contract visible/manageable via room's house"/"House ... has_house_access"
  // đã có sẵn) trước khi dùng `ctx.supabaseAdmin` ghi đặc quyền bên dưới.
  // "secret" giữ lại cho script/test nội bộ (curl bằng service-role key).
  fetch: withSupabase({ auth: ["user", "secret"] }, async (req, ctx) => {
    const body = await req.json();

    if (body.mode === "single") {
      const { data: allowed } = await ctx.supabase
        .from("tb_contract")
        .select("id")
        .eq("id", body.contractId)
        .maybeSingle();
      if (!allowed) {
        return Response.json({ error: "Forbidden" }, { status: 403 });
      }
      const result = await generateSingleInvoice(ctx.supabaseAdmin, body.contractId, body.periodYm);
      return Response.json(result);
    }

    if (body.mode === "batch") {
      const { data: allowedHouse } = await ctx.supabase
        .from("tb_house")
        .select("id")
        .eq("id", body.houseId)
        .maybeSingle();
      if (!allowedHouse) {
        return Response.json({ error: "Forbidden" }, { status: 403 });
      }
      // BR-BILL-11: mọi hợp đồng Active của 1 nhà, trong 1 kỳ.
      const contractIds = await activeContractIdsForHouse(ctx.supabaseAdmin, body.houseId);

      const created = [];
      const skipped = [];
      for (const contractId of contractIds) {
        const result = await generateSingleInvoice(ctx.supabaseAdmin, contractId, body.periodYm);
        if ("invoice" in result) created.push(result.invoice);
        else skipped.push(result.skipped);
      }
      return Response.json({ created, skipped });
    }

    // B-03: xem trước số tiền ước tính + trạng thái từng hợp đồng Active của 1
    // Nhà trong 1 kỳ (Ready/No reading/Already created) TRƯỚC khi tạo thật —
    // KHÔNG ghi DB. Người dùng chọn (checkbox) trong số các hợp đồng "ready"
    // rồi app gọi lại `mode: "single"` cho từng hợp đồng đã chọn để tạo thật.
    if (body.mode === "previewBatch") {
      const { data: allowedHouse } = await ctx.supabase
        .from("tb_house")
        .select("id")
        .eq("id", body.houseId)
        .maybeSingle();
      if (!allowedHouse) {
        return Response.json({ error: "Forbidden" }, { status: 403 });
      }
      const contractIds = await activeContractIdsForHouse(ctx.supabaseAdmin, body.houseId);

      // Chạy song song theo LÔ NHỎ (không phải tuần tự từng cái, không phải tất
      // cả cùng lúc) — nhà càng nhiều phòng thì chạy tuần tự càng dễ vượt quá
      // thời gian cho phép của 1 lần gọi Edge Function (test thật 28 hợp đồng
      // tuần tự mất ~40s — nhà 50-100 phòng có nguy cơ timeout giữa chừng, lỗi
      // trắng cả preview). Song song theo lô giữ đúng kết quả, chỉ nhanh hơn.
      const CONCURRENCY = 6;
      const items = [];
      for (let i = 0; i < contractIds.length; i += CONCURRENCY) {
        const chunk = contractIds.slice(i, i + CONCURRENCY);
        const results = await Promise.all(
          chunk.map((contractId) =>
            generateSingleInvoice(ctx.supabaseAdmin, contractId, body.periodYm, { dryRun: true })
          ),
        );
        for (let j = 0; j < chunk.length; j++) {
          const contractId = chunk[j];
          const result = results[j];
          if ("preview" in result) {
            items.push({ contractId, status: "ready", ...result.preview });
          } else if ("invoice" in result) {
            items.push({
              contractId,
              status: "already_created",
              roomNos: result.invoice.room_nos,
              tenantName: result.invoice.tenant_name,
              totalAmount: result.invoice.total_amount,
            });
          } else {
            items.push({
              contractId,
              status: "missing_reading",
              roomNos: result.skipped.roomNos ?? [],
              tenantName: result.skipped.tenantName ?? "",
              reason: result.skipped.reason,
            });
          }
        }
      }
      return Response.json({ items });
    }

    // B-03 "Save all as draft"/"Create & send all" — tạo hoá đơn cho ĐÚNG danh
    // sách hợp đồng người dùng đã tick chọn (không phải toàn bộ nhà), rồi nếu
    // `send=true` gửi SMS thật ngay trong cùng request. Chạy HẲN phía backend
    // (không phải frontend tự lặp gọi từng hợp đồng) — xem comment đầu file.
    if (body.mode === "batchSend") {
      const { data: allowedHouse } = await ctx.supabase
        .from("tb_house")
        .select("id")
        .eq("id", body.houseId)
        .maybeSingle();
      if (!allowedHouse) {
        return Response.json({ error: "Forbidden" }, { status: 403 });
      }

      const contractIds: string[] = Array.isArray(body.contractIds) ? body.contractIds : [];
      const shouldSend = body.send === true;

      const { data: house } = await ctx.supabaseAdmin
        .from("tb_house")
        .select("bank_bin, bank_account_number, bank_account_name")
        .eq("id", body.houseId)
        .single();

      const CONCURRENCY = 6;
      let createdCount = 0;
      let sentCount = 0;
      const errors: { contractId: string; reason: string }[] = [];

      for (let i = 0; i < contractIds.length; i += CONCURRENCY) {
        const chunk = contractIds.slice(i, i + CONCURRENCY);
        await Promise.all(
          chunk.map(async (contractId) => {
            const result = await generateSingleInvoice(ctx.supabaseAdmin, contractId, body.periodYm);
            if (!("invoice" in result)) {
              errors.push({ contractId, reason: result.skipped.reason });
              return;
            }
            createdCount++;
            if (!shouldSend) return;
            try {
              const { data: contract } = await ctx.supabaseAdmin
                .from("tb_contract")
                .select("tenant_id")
                .eq("id", contractId)
                .single();
              const { data: tenant } = await ctx.supabaseAdmin
                .from("tb_tenant")
                .select("phone")
                .eq("id", contract.tenant_id)
                .single();
              const message = buildInvoiceSmsMessage(result.invoice);
              await sendSmsViaEsms(tenant.phone, message);
              await ctx.supabaseAdmin
                .from("tb_invoice")
                .update({ status: "Sent", sent_at: new Date().toISOString() })
                .eq("id", result.invoice.id);
              sentCount++;
            } catch (e) {
              errors.push({ contractId, reason: `Gửi SMS thất bại: ${e}` });
            }
          }),
        );
      }

      return Response.json({ created: createdCount, sent: sentCount, errors });
    }

    return Response.json({ error: "mode phải là 'single', 'batch', 'previewBatch', hoặc 'batchSend'" }, { status: 400 });
  }),
};

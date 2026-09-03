// generate-invoice
//
// Sinh Invoice cho 1 contract từ meter_reading của kỳ hiện tại.
// Công thức theo docs/BUSINESS-RULES.md mục 1 (BR-BILL-01..04):
//   Tổng = Tiền phòng (contract.rent_price)
//        + Tiền điện = (chỉ số điện mới - chỉ số cũ) * electricity_unit_price
//        + Tiền nước = (chỉ số nước mới - chỉ số cũ) * water_unit_price
//        + Tổng phí khác (room.other_fees, snapshot lúc tạo — Landlord có thể sửa khi preview ở L-13)
//
// Gọi bởi: Landlord bấm "Xem trước & Gửi Hoá đơn" (L-13) sau khi ghi chỉ số (Flow #5 -> #6),
// hoặc Scheduled Trigger hàng tháng (TODO: cấu hình pg_cron sau khi chốt lịch cụ thể với Dream).
//
// Chưa làm trong bản này (cần quyết định thêm trước khi code):
// - Gửi hoá đơn qua Push/SMS/Zalo sau khi tạo — xem hàm send-notification.
// - Due date mặc định = N ngày sau khi gửi (BR-PAY-01), N hiện chưa chốt cụ thể.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

interface GenerateInvoiceRequest {
  contract_id: string;
  period: string; // "YYYY-MM-01"
}

export default {
  fetch: withSupabase({ auth: ["secret"] }, async (req, ctx) => {
    const { contract_id, period }: GenerateInvoiceRequest = await req.json();

    const { data: contract, error: contractError } = await ctx.supabaseAdmin
      .from("contracts")
      .select("id, room_id, rent_price, electricity_unit_price, water_unit_price")
      .eq("id", contract_id)
      .single();

    if (contractError || !contract) {
      return Response.json({ error: "Contract not found" }, { status: 404 });
    }

    const { data: room, error: roomError } = await ctx.supabaseAdmin
      .from("rooms")
      .select("other_fees")
      .eq("id", contract.room_id)
      .single();

    if (roomError || !room) {
      return Response.json({ error: "Room not found" }, { status: 404 });
    }

    const { data: readings, error: readingsError } = await ctx.supabaseAdmin
      .from("meter_readings")
      .select("period, electricity_reading, water_reading")
      .eq("room_id", contract.room_id)
      .lte("period", period)
      .order("period", { ascending: false })
      .limit(2);

    if (readingsError || !readings || readings.length < 2) {
      return Response.json(
        { error: "Not enough meter readings to calculate this period (need current + previous)" },
        { status: 400 },
      );
    }

    const [current, previous] = readings;

    // BR-BILL-05: chỉ số mới phải >= chỉ số cũ.
    if (current.electricity_reading < previous.electricity_reading || current.water_reading < previous.water_reading) {
      return Response.json({ error: "Invalid meter reading: new < previous" }, { status: 400 });
    }

    const electricityCharge =
      (current.electricity_reading - previous.electricity_reading) * (contract.electricity_unit_price ?? 0);
    const waterCharge = (current.water_reading - previous.water_reading) * (contract.water_unit_price ?? 0);
    const otherFees: { name: string; amount: number }[] = room.other_fees ?? [];
    const otherFeesTotal = otherFees.reduce((sum, fee) => sum + fee.amount, 0);
    const totalAmount = contract.rent_price + electricityCharge + waterCharge + otherFeesTotal;

    // TODO: due_date = period + N ngày (BR-PAY-01) — N cụ thể chưa chốt, tạm +7 ngày.
    const dueDate = new Date(period);
    dueDate.setDate(dueDate.getDate() + 7);

    const { data: invoice, error: insertError } = await ctx.supabaseAdmin
      .from("invoices")
      .insert({
        contract_id,
        period,
        room_charge: contract.rent_price,
        electricity_charge: electricityCharge,
        water_charge: waterCharge,
        other_fees: otherFees,
        total_amount: totalAmount,
        due_date: dueDate.toISOString().slice(0, 10),
        status: "unpaid",
      })
      .select()
      .single();

    if (insertError) {
      return Response.json({ error: insertError.message }, { status: 500 });
    }

    return Response.json({ invoice });
  }),
};

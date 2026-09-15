// _shared/notifications.ts
//
// Ghi thông báo vào `tb_notification` (S-03 Notification Center) — dùng
// chung cho mọi Edge Function cần báo cho người có quyền trên 1 Nhà/Dãy
// trọ. Chỉ lưu `type` + `payload` (jsonb), KHÔNG dựng sẵn câu chữ — Flutter
// tự dựng câu qua AppStrings.t() theo đúng ngôn ngữ UI người xem đang chọn
// (title/body cố định sẵn ở đây sẽ chỉ 1 ngôn ngữ, sai với FR-MGR-05).
//
// Đợt này (2026-09-15) chỉ làm 3 loại tức thời: invoice_sent, invoice_collected,
// manager_invited — BR-NOTI-02/04/05 chạy theo lịch (cron), để đợt sau.

export type NotificationType = "invoice_sent" | "invoice_collected" | "manager_invited";

interface FanOutOptions {
  houseId: string;
  type: NotificationType;
  payload: Record<string, unknown>;
  targetInvoiceId?: string;
  // Bỏ qua chính người vừa thực hiện hành động (VD người vừa đánh dấu đã thu
  // tiền không cần tự báo cho mình) — chỉ để tiện UX, không phải kiểm tra quyền.
  excludePhone?: string;
}

// deno-lint-ignore no-explicit-any
export async function fanOutNotification(supabaseAdmin: any, opts: FanOutOptions): Promise<void> {
  const { data: accessRows } = await supabaseAdmin
    .from("tb_user_house_access")
    .select("phone")
    .eq("house_id", opts.houseId)
    .eq("is_active", true);

  const phones = [...new Set((accessRows ?? []).map((r: { phone: string }) => r.phone))]
    .filter((phone) => phone !== opts.excludePhone);

  if (phones.length === 0) return;

  await supabaseAdmin.from("tb_notification").insert(
    phones.map((phone) => ({
      recipient_phone: phone,
      house_id: opts.houseId,
      type: opts.type,
      payload: opts.payload,
      target_invoice_id: opts.targetInvoiceId ?? null,
    })),
  );
}

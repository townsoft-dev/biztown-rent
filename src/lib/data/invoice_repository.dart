import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import 'models/invoice.dart';
import 'models/recurring_fee.dart';

/// Kết quả tạo hàng loạt (B-03) — mỗi hợp đồng thiếu chỉ số bị bỏ qua hoàn
/// toàn (BR-BILL-11), không ước lượng thay.
class BatchInvoiceResult {
  final List<Invoice> created;
  final List<({String contractId, String reason})> skipped;

  const BatchInvoiceResult({required this.created, required this.skipped});
}

/// `tb_invoice` — đọc qua Postgrest như mọi repository khác; TẠO hoá đơn (đơn
/// lẻ/hàng loạt) và sinh lại mã QR gọi thẳng Edge Function `generate-invoice`/
/// `generate-payment-qr` (engine tính tiền theo BR-BILL-01..13 đã viết sẵn ở
/// đó, KHÔNG viết lại bằng Dart — xem docs/DECISIONS.md Đợt 31).
class InvoiceRepository {
  final SupabaseClient _client;
  const InvoiceRepository(this._client);

  /// Hoá đơn chưa `Collected` (Draft/Sent) của 1 hợp đồng — T-09.
  Future<List<Invoice>> listUnpaidByContract(String contractId) async {
    final rows = await _client
        .from('tb_invoice')
        .select()
        .eq('contract_id', contractId)
        .neq('status', 'Collected')
        .order('period_start');
    return rows.map((row) => Invoice.fromMap(row)).toList();
  }

  /// Mọi hoá đơn (mọi trạng thái) của 1 hợp đồng — T-05 dải chip "Invoice
  /// schedule" (khớp `period_start` với từng kỳ suy ra từ `contract_version`
  /// để tô đúng màu Collected/Sent/Overdue).
  Future<List<Invoice>> listByContract(String contractId) async {
    final rows = await _client
        .from('tb_invoice')
        .select()
        .eq('contract_id', contractId)
        .order('period_start');
    return rows.map((row) => Invoice.fromMap(row)).toList();
  }

  /// Mọi hoá đơn thuộc phạm vi các nhà đang có quyền — B-01.
  Future<List<Invoice>> listAll() async {
    final rows = await _client
        .from('tb_invoice')
        .select()
        .order('period_start', ascending: false);
    return rows.map((row) => Invoice.fromMap(row)).toList();
  }

  Future<Invoice> getById(String invoiceId) async {
    final row =
        await _client.from('tb_invoice').select().eq('id', invoiceId).single();
    return Invoice.fromMap(row);
  }

  /// Tạo hoá đơn cho 1 hợp đồng cụ thể — B-02. `periodYm` dạng `YYYY-MM-01`.
  /// Trả về hoá đơn vừa tạo, hoặc ném lỗi kèm lý do bỏ qua (thiếu chỉ số...).
  Future<Invoice> generateSingle({
    required String contractId,
    required DateTime periodYm,
  }) async {
    final res = await _client.functions.invoke('generate-invoice', body: {
      'mode': 'single',
      'contractId': contractId,
      'periodYm': _ymString(periodYm),
    });
    final data = res.data as Map<String, dynamic>;
    if (data['skipped'] != null) {
      throw InvoiceSkippedException(data['skipped']['reason'] as String);
    }
    return Invoice.fromMap(data['invoice'] as Map<String, dynamic>);
  }

  /// Tạo hàng loạt cho mọi hợp đồng Active của 1 Nhà trong 1 kỳ — B-03.
  Future<BatchInvoiceResult> generateBatch({
    required String houseId,
    required DateTime periodYm,
  }) async {
    final res = await _client.functions.invoke('generate-invoice', body: {
      'mode': 'batch',
      'houseId': houseId,
      'periodYm': _ymString(periodYm),
    });
    final data = res.data as Map<String, dynamic>;
    final created = (data['created'] as List)
        .map((e) => Invoice.fromMap(e as Map<String, dynamic>))
        .toList();
    final skipped = (data['skipped'] as List)
        .map((e) => (
              contractId: e['contractId'] as String,
              reason: e['reason'] as String,
            ))
        .toList();
    return BatchInvoiceResult(created: created, skipped: skipped);
  }

  /// Sinh lại mã QR cho 1 hoá đơn đã có — dùng khi "Gửi lại" (B-04) mà không
  /// cần tính lại toàn bộ hoá đơn.
  Future<String> regeneratePaymentQr(String invoiceId) async {
    final res = await _client.functions
        .invoke('generate-payment-qr', body: {'invoiceId': invoiceId});
    final data = res.data as Map<String, dynamic>;
    if (data['error'] != null) throw Exception(data['error'] as String);
    return data['paymentQrPayload'] as String;
  }

  /// Thêm 1 dòng phí phát sinh vào hoá đơn đang Draft (B-02 "+ Add other
  /// fee") — cộng dồn vào `otherFees` + `totalAmount`. Chỉ hợp lý khi hoá
  /// đơn còn Draft (chưa gửi); không tự kiểm tra ở đây, màn gọi tự đảm bảo.
  Future<Invoice> addOtherFee(Invoice invoice, RecurringFee fee) async {
    final newOtherFees = [...invoice.otherFees, fee];
    final newTotal = invoice.totalAmount + fee.amount;
    final row = await _client
        .from('tb_invoice')
        .update({
          'other_fees': newOtherFees.map((f) => f.toMap()).toList(),
          'total_amount': newTotal,
        })
        .eq('id', invoice.id)
        .select()
        .single();
    return Invoice.fromMap(row);
  }

  Future<void> updateStatus(String invoiceId, InvoiceStatus status) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('tb_invoice').update({
      'status': status.dbValue,
      if (status == InvoiceStatus.sent) 'sent_at': now,
      if (status == InvoiceStatus.collected) 'collected_at': now,
    }).eq('id', invoiceId);
  }

  /// "Huỷ đánh dấu" Collected → quay lại Sent (B-04) — không xoá `sentAt` cũ.
  Future<void> undoCollected(String invoiceId) async {
    await _client.from('tb_invoice').update({
      'status': InvoiceStatus.sent.dbValue,
      'collected_at': null
    }).eq('id', invoiceId);
  }

  String _ymString(DateTime ym) =>
      '${ym.year.toString().padLeft(4, '0')}-${ym.month.toString().padLeft(2, '0')}-01';
}

/// Hợp đồng bị bỏ qua khi tạo hoá đơn đơn lẻ (thiếu chỉ số kỳ này...) —
/// BR-BILL-11, `generate-invoice` trả `{skipped: {contractId, reason}}` thay
/// vì `{invoice}`.
class InvoiceSkippedException implements Exception {
  final String reason;
  const InvoiceSkippedException(this.reason);

  @override
  String toString() => reason;
}

final invoiceRepository = InvoiceRepository(supabase);

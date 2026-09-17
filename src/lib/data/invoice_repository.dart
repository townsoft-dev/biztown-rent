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

/// Kết quả `InvoiceRepository.batchCreateAndSend()` — B-03, chạy hẳn phía
/// backend trong 1 lần gọi (xem docs/DECISIONS.md).
class BatchSendResult {
  final int created;
  final int sent;
  final List<({String contractId, String reason})> errors;

  const BatchSendResult(
      {required this.created, required this.sent, required this.errors});
}

/// Trạng thái 1 hợp đồng khi xem trước B-03 — khớp `StatusBadge` trong Figma:
/// `ready` (xanh, có thể chọn), `missingReading`/`alreadyCreated` (xám/cam,
/// dòng mờ 60%, không cho chọn).
enum BatchPreviewStatus { ready, missingReading, alreadyCreated }

/// 1 dòng trong danh sách xem trước B-03 (`mode: "previewBatch"`) — tính thử
/// số tiền, KHÔNG tạo hoá đơn thật. Người dùng tick chọn trong số các dòng
/// `ready`, bấm tạo thì app tự gọi lại `generateSingle` cho từng hợp đồng đã
/// chọn (xem docs/DECISIONS.md).
class BatchPreviewItem {
  final String contractId;
  final List<String> roomNos;
  final String tenantName;
  final num totalAmount;
  final BatchPreviewStatus status;
  final String? reason;

  const BatchPreviewItem({
    required this.contractId,
    required this.roomNos,
    required this.tenantName,
    required this.totalAmount,
    required this.status,
    this.reason,
  });
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

  /// Xem trước (KHÔNG tạo thật) trạng thái + số tiền ước tính từng hợp đồng
  /// Active của 1 Nhà trong 1 kỳ — B-03 mở màn hiện danh sách checkbox trước
  /// khi người dùng chọn tạo.
  Future<List<BatchPreviewItem>> previewBatch({
    required String houseId,
    required DateTime periodYm,
  }) async {
    final res = await _client.functions.invoke('generate-invoice', body: {
      'mode': 'previewBatch',
      'houseId': houseId,
      'periodYm': _ymString(periodYm),
    });
    final data = res.data as Map<String, dynamic>;
    return (data['items'] as List).map((e) {
      final map = e as Map<String, dynamic>;
      final status = switch (map['status'] as String) {
        'ready' => BatchPreviewStatus.ready,
        'already_created' => BatchPreviewStatus.alreadyCreated,
        _ => BatchPreviewStatus.missingReading,
      };
      return BatchPreviewItem(
        contractId: map['contractId'] as String,
        roomNos:
            (map['roomNos'] as List? ?? []).map((r) => r as String).toList(),
        tenantName: map['tenantName'] as String? ?? '',
        totalAmount: (map['totalAmount'] as num?) ?? 0,
        status: status,
        reason: map['reason'] as String?,
      );
    }).toList();
  }

  /// Tạo hoá đơn cho ĐÚNG danh sách hợp đồng đã chọn (B-03, checkbox) — rồi
  /// nếu `send=true` gửi SMS thật luôn trong CÙNG 1 lần gọi. Chạy HẲN phía
  /// backend (Edge Function tự lặp + gửi, không phải app tự lặp gọi từng
  /// hợp đồng) — tránh rủi ro tiến trình bị hệ điều hành tạm dừng giữa chừng
  /// nếu người dùng khoá màn hình/chuyển app trong lúc app đang tự lặp gọi
  /// (dungtv xác nhận 2026-09-14, xem docs/DECISIONS.md).
  Future<BatchSendResult> batchCreateAndSend({
    required String houseId,
    required DateTime periodYm,
    required List<String> contractIds,
    required bool send,
  }) async {
    final res = await _client.functions.invoke('generate-invoice', body: {
      'mode': 'batchSend',
      'houseId': houseId,
      'periodYm': _ymString(periodYm),
      'contractIds': contractIds,
      'send': send,
    });
    final data = res.data as Map<String, dynamic>;
    return BatchSendResult(
      created: data['created'] as int? ?? 0,
      sent: data['sent'] as int? ?? 0,
      errors: (data['errors'] as List? ?? [])
          .map((e) => (
                contractId: (e as Map<String, dynamic>)['contractId'] as String,
                reason: e['reason'] as String,
              ))
          .toList(),
    );
  }

  /// Gửi SMS hoá đơn tới Tenant qua `send-notification` (kênh `tenant`, eSMS
  /// SmsType "1" — chưa có Brandname CSKH, xem docs/DECISIONS.md) rồi cập
  /// nhật `status → Sent` — B-05. KHÔNG bật push (`push: false`, Firebase
  /// chưa cấu hình, ngoài phạm vi B-05).
  Future<void> sendSms({
    required String invoiceId,
    required String houseId,
    required String phone,
    required String message,
  }) async {
    final res = await _client.functions.invoke('send-notification', body: {
      'houseId': houseId,
      'event': 'invoice_created',
      'title': 'Hoá đơn mới',
      'body': message,
      'push': false,
      'tenant': {'phone': phone, 'message': message},
    });
    final data = res.data as Map<String, dynamic>?;
    if (data?['error'] != null) {
      throw Exception(data!['error'] as String);
    }
    await updateStatus(invoiceId, InvoiceStatus.sent);
  }

  /// B-05 kênh Email — gọi Edge Function `send-invoice-email`. Nội dung thư do
  /// backend dựng (mẫu của Hường), app chỉ cần đưa `invoiceId`.
  Future<void> sendEmail({required String invoiceId}) async {
    final res = await _client.functions
        .invoke('send-invoice-email', body: {'invoiceId': invoiceId});
    final data = res.data as Map<String, dynamic>?;
    if (data?['error'] != null) {
      throw Exception(data!['error'] as String);
    }
    await updateStatus(invoiceId, InvoiceStatus.sent);
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

  /// Xoá hẳn 1 hoá đơn còn Draft (B-04 "Delete draft") — chỉ hợp lý khi còn
  /// Draft, màn gọi tự đảm bảo. Phải gỡ `invoice_id` khỏi mọi chỉ số điện/
  /// nước đã đóng vai trò "to" cho hoá đơn này TRƯỚC khi xoá (khoá ngoại
  /// `tb_electricity_reading/tb_water_reading.invoice_id` chặn xoá thẳng nếu
  /// còn tham chiếu) — mở khoá lại các chỉ số đó (`isLocked` derived về false).
  Future<void> deleteDraft(String invoiceId) async {
    await _client
        .from('tb_electricity_reading')
        .update({'invoice_id': null}).eq('invoice_id', invoiceId);
    await _client
        .from('tb_water_reading')
        .update({'invoice_id': null}).eq('invoice_id', invoiceId);
    await _client.from('tb_invoice').delete().eq('id', invoiceId);
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

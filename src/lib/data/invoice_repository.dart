import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import 'models/invoice.dart';

/// Chỉ ĐỌC `tb_invoice` — dùng cho T-09 ("Outstanding invoices" chưa
/// Collected) và tương lai T-05/B-01 (dải chip lịch hoá đơn). Bills (B-0x)
/// chưa xây UI tạo hoá đơn nên bảng này trong thực tế luôn rỗng; không thêm
/// hàm create/update ở đây, tránh trùng lặp khi B-0x xây thật.
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
}

final invoiceRepository = InvoiceRepository(supabase);

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import 'models/contract.dart';

/// CRUD cho `tb_contract`/`tb_contract_room`/`tb_contract_version` (T-0x).
/// Cố tình KHÔNG dùng cú pháp embed/join của PostgREST (`select('*, foo(*)')`)
/// — theo đúng quy ước sẵn có của mọi repository khác trong app (Room/House/
/// User đều query phẳng từng bảng rồi tự ghép ở tầng Dart/provider), tránh
/// vướng vấn đề PostgREST cần chỉ rõ tên constraint khi 2 bảng có NHIỀU hơn 1
/// quan hệ FK với nhau (`tb_contract.current_version_id` ↔
/// `tb_contract_version.contract_id`).
class ContractRepository {
  final SupabaseClient _client;
  const ContractRepository(this._client);

  Future<Contract> getById(String contractId) async {
    final row = await _client
        .from('tb_contract')
        .select()
        .eq('id', contractId)
        .single();
    return Contract.fromMap(row);
  }

  /// Mọi hợp đồng Tenant này từng/đang tham gia (mọi trạng thái) — T-03.
  Future<List<Contract>> listByTenant(String tenantId) async {
    final rows = await _client
        .from('tb_contract')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);
    return rows.map((row) => Contract.fromMap(row)).toList();
  }

  /// Mọi hợp đồng thuộc phạm vi các Nhà tài khoản hiện tại có quyền (RLS tự
  /// lọc) — nguồn thô cho T-02, ghép thêm Tenant/Room/Version ở tầng provider.
  Future<List<Contract>> listAll() async {
    final rows = await _client
        .from('tb_contract')
        .select()
        .order('created_at', ascending: false);
    return rows.map((row) => Contract.fromMap(row)).toList();
  }

  Future<ContractVersion> getVersionById(String versionId) async {
    final row = await _client
        .from('tb_contract_version')
        .select()
        .eq('id', versionId)
        .single();
    return ContractVersion.fromMap(row);
  }

  Future<List<ContractVersion>> listVersionsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows =
        await _client.from('tb_contract_version').select().inFilter('id', ids);
    return rows.map((row) => ContractVersion.fromMap(row)).toList();
  }

  /// Lịch sử đầy đủ điều khoản của 1 hợp đồng, mới nhất trước — T-08.
  Future<List<ContractVersion>> listVersionsByContract(
      String contractId) async {
    final rows = await _client
        .from('tb_contract_version')
        .select()
        .eq('contract_id', contractId)
        .order('version_no', ascending: false);
    return rows.map((row) => ContractVersion.fromMap(row)).toList();
  }

  /// ID các phòng thuộc 1 hợp đồng (mọi lúc, kể cả sau khi hợp đồng Ended —
  /// `tb_contract_room` không xoá dòng khi kết thúc, chỉ đổi `is_active`).
  Future<List<String>> listRoomIdsByContract(String contractId) async {
    final rows = await _client
        .from('tb_contract_room')
        .select('room_id')
        .eq('contract_id', contractId);
    return rows.map((r) => r['room_id'] as String).toList();
  }

  /// `{contractId: [roomId, ...]}` cho nhiều hợp đồng cùng lúc — dùng ghép
  /// dữ liệu hiển thị ở T-01/T-02, tránh N+1 query theo từng hợp đồng.
  Future<Map<String, List<String>>> roomIdsByContractIds(
      List<String> contractIds) async {
    if (contractIds.isEmpty) return {};
    final rows = await _client
        .from('tb_contract_room')
        .select('contract_id, room_id')
        .inFilter('contract_id', contractIds);
    final map = <String, List<String>>{};
    for (final row in rows) {
      map
          .putIfAbsent(row['contract_id'] as String, () => [])
          .add(row['room_id'] as String);
    }
    return map;
  }

  /// `{roomId: contractId}` cho các phòng đang có hợp đồng Active — dùng lọc
  /// phòng "Empty" ở T-06 mà không cần đọc `tb_room.status` (tránh lệch nếu
  /// status chưa kịp đồng bộ).
  Future<Set<String>> listActiveContractRoomIds(List<String> roomIds) async {
    if (roomIds.isEmpty) return {};
    final rows = await _client
        .from('tb_contract_room')
        .select('room_id')
        .inFilter('room_id', roomIds)
        .eq('is_active', true);
    return rows.map((r) => r['room_id'] as String).toSet();
  }

  /// Tạo hợp đồng mới: 1 dòng `tb_contract`, 1 dòng `tb_contract_version`
  /// (`versionNo=1`, `changeReason=New`), N dòng `tb_contract_room`. Ràng
  /// buộc DB `one_active_contract_per_room` tự chặn (23505) nếu 1 trong các
  /// phòng đã có hợp đồng Active khác — gọi nơi dùng hàm này phải bắt
  /// `PostgrestException` để hiện lỗi race-condition phù hợp (BR-CTR-13 edge
  /// case). KHÔNG tự cập nhật `tb_room.status` ở đây — gọi riêng
  /// `RoomRepository.updateStatus` cho từng phòng sau khi tạo thành công,
  /// giữ 2 repository độc lập, không phụ thuộc chéo.
  Future<Contract> create({
    required String tenantId,
    required List<String> roomIds,
    required ContractVersion version,
  }) async {
    final contractRow = await _client
        .from('tb_contract')
        .insert({'tenant_id': tenantId, 'status': 'Active'})
        .select()
        .single();
    final contractId = contractRow['id'] as String;

    final versionRow = await _client
        .from('tb_contract_version')
        .insert({...version.toInsertMap(), 'contract_id': contractId})
        .select()
        .single();
    final versionId = versionRow['id'] as String;

    await _client.from('tb_contract_room').insert([
      for (final roomId in roomIds)
        {'contract_id': contractId, 'room_id': roomId},
    ]);

    final updatedRow = await _client
        .from('tb_contract')
        .update({'current_version_id': versionId})
        .eq('id', contractId)
        .select()
        .single();
    return Contract.fromMap(updatedRow);
  }

  /// Gia hạn (Renew) hoặc sửa điều khoản giữa kỳ (Amend) — T-07. Cả 2 chỉ
  /// khác nhau ở `changeReason` do màn hình gọi truyền vào (BR-CTR-08:
  /// KHÔNG ghi đè bản cũ, luôn tạo bản ghi `tb_contract_version` mới).
  Future<void> addVersion(String contractId, ContractVersion version) async {
    final versionRow = await _client
        .from('tb_contract_version')
        .insert({...version.toInsertMap(), 'contract_id': contractId})
        .select()
        .single();
    await _client
        .from('tb_contract')
        .update({'current_version_id': versionRow['id']}).eq('id', contractId);
  }

  /// Kết thúc hợp đồng (T-09) — chỉ ghi lại số liệu đối soát, KHÔNG tự tạo
  /// hoá đơn cuối (chốt 2026-09-11, xem docs/DECISIONS.md Đợt 26 — Figma
  /// thật ghi rõ "does NOT create a final invoice"). KHÔNG tự cập nhật
  /// `tb_room.status` — gọi riêng `RoomRepository.updateStatus` cho từng
  /// phòng sau khi gọi hàm này, giống lúc tạo hợp đồng.
  Future<void> endContract({
    required String contractId,
    num? unpaidInvoicesTotal,
    num? damageDeduction,
    num? refundAmount,
    String? settlementNote,
  }) async {
    await _client.from('tb_contract').update({
      'status': 'Ended',
      'unpaid_invoices_total': unpaidInvoicesTotal,
      'damage_deduction': damageDeduction,
      'refund_amount': refundAmount,
      'settlement_note': settlementNote,
      'settlement_confirmed_at': DateTime.now().toIso8601String(),
    }).eq('id', contractId);
  }
}

final contractRepository = ContractRepository(supabase);

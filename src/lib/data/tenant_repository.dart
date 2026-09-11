import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase_client.dart';
import 'models/tenant.dart';

const _photosBucket = 'property-photos';

/// CRUD cho `tb_tenant` ("Tenant Pool", T-01/T-03/T-04) + ảnh CCCD 2 mặt,
/// dùng chung bucket Storage `property-photos` với House/Room (path
/// `<houseId>/tenants/<tenantId>/<file>` — cùng quy ước "path segment đầu
/// tiên = houseId" nên không cần policy Storage riêng, xem migration
/// `20260910130000_house_room_photos_storage.sql`).
class TenantRepository {
  final SupabaseClient _client;
  const TenantRepository(this._client);

  /// Toàn bộ Tenant thuộc các Nhà tài khoản hiện tại có quyền truy cập (RLS
  /// tự lọc theo `tb_user_house_access`) — dùng cho T-01, lọc theo Nhà ở tầng
  /// UI (Tenant Pool độc lập theo từng Nhà, BR-DATA-05).
  Future<List<Tenant>> listAll() async {
    final rows = await _client.from('tb_tenant').select().order('created_at');
    return rows.map((row) => Tenant.fromMap(row)).toList();
  }

  Future<Tenant> getById(String tenantId) async {
    final row =
        await _client.from('tb_tenant').select().eq('id', tenantId).single();
    return Tenant.fromMap(row);
  }

  /// Tenant Pool đã có SĐT này trong CÙNG 1 Nhà — dùng cảnh báo trùng ở T-04
  /// (BR-CTR-09 edge case: trùng SĐT ở Nhà khác không cảnh báo).
  Future<Tenant?> findByPhoneInHouse(String houseId, String phone) async {
    final rows = await _client
        .from('tb_tenant')
        .select()
        .eq('house_id', houseId)
        .eq('phone', phone)
        .limit(1);
    return rows.isEmpty ? null : Tenant.fromMap(rows.first);
  }

  Future<Tenant> create(Tenant tenant) async {
    final id = const Uuid().v4();
    await _client.from('tb_tenant').insert({...tenant.toInsertMap(), 'id': id});
    return getById(id);
  }

  Future<Tenant> update(String tenantId, Tenant tenant) async {
    final row = await _client
        .from('tb_tenant')
        .update(tenant.toInsertMap())
        .eq('id', tenantId)
        .select()
        .single();
    return Tenant.fromMap(row);
  }

  /// Xoá Tenant — DB tự chặn (lỗi FK, `tb_contract.tenant_id references
  /// tb_tenant on delete restrict`) nếu Tenant còn hợp đồng (kể cả đã Ended,
  /// vì lịch sử hợp đồng phải giữ nguyên), gọi nơi dùng hàm này phải bắt
  /// `PostgrestException` để hiện thông báo phù hợp.
  Future<void> delete(String tenantId) async {
    await _client.from('tb_tenant').delete().eq('id', tenantId);
  }

  Future<String> uploadIdPhoto(
      String houseId, String tenantId, File file) async {
    final ext = file.path.split('.').last;
    final path = '$houseId/tenants/$tenantId/${const Uuid().v4()}.$ext';
    await _client.storage.from(_photosBucket).upload(path, file);
    return path;
  }

  Future<void> deletePhoto(String path) async {
    await _client.storage.from(_photosBucket).remove([path]);
  }

  /// URL tạm (1h) để hiển thị ảnh — bucket private nên không dùng `getPublicUrl`.
  Future<String> signedPhotoUrl(String path) async {
    return _client.storage.from(_photosBucket).createSignedUrl(path, 3600);
  }
}

final tenantRepository = TenantRepository(supabase);

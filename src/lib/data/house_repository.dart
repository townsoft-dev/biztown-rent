import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase_client.dart';
import 'models/house.dart';

const _photosBucket = 'property-photos';

/// CRUD cho `tb_house` + ảnh trong bucket Storage `property-photos`
/// (path `<houseId>/houses/<file>`, xem migration
/// `20260910130000_house_room_photos_storage.sql`).
class HouseRepository {
  final SupabaseClient _client;
  const HouseRepository(this._client);

  /// Danh sách nhà tài khoản hiện tại có quyền truy cập (RLS tự lọc theo
  /// `tb_user_house_access`, xem docs/DATABASE.md mục RLS).
  Future<List<House>> listMyHouses() async {
    final rows = await _client.from('tb_house').select().order('created_at');
    return rows.map((row) => House.fromMap(row)).toList();
  }

  Future<House> getById(String houseId) async {
    final row =
        await _client.from('tb_house').select().eq('id', houseId).single();
    return House.fromMap(row);
  }

  /// Tạo nhà mới — trigger `trg_house_insert_grant_owner` tự cấp quyền
  /// `owner` cho người tạo, không cần tự ghi `tb_user_house_access`.
  ///
  /// Cố tình KHÔNG dùng `.insert(...).select().single()` (insert kèm
  /// RETURNING) — Postgres áp lại policy SELECT (`has_house_access`) ngay khi
  /// trả về hàng vừa insert, nhưng dòng quyền `owner` do trigger AFTER INSERT
  /// tạo ra chưa kịp "nhìn thấy" tại đúng thời điểm đó nên bị RLS chặn
  /// (`42501`, phát hiện 10/09/2026 lúc test CRUD thật — xem
  /// docs/DECISIONS.md). Sinh sẵn `id` ở client, insert KHÔNG yêu cầu trả về
  /// hàng, rồi gọi `getById` ở 1 request riêng (lúc đó trigger đã chắc chắn
  /// commit xong) để né vấn đề thời điểm này.
  Future<House> create(House house) async {
    final id = const Uuid().v4();
    await _client.from('tb_house').insert({...house.toInsertMap(), 'id': id});
    return getById(id);
  }

  Future<House> update(String houseId, House house) async {
    final row = await _client
        .from('tb_house')
        .update(house.toInsertMap())
        .eq('id', houseId)
        .select()
        .single();
    return House.fromMap(row);
  }

  /// Tên hiển thị của các Manager **đang active** cho nhà này — đọc thẳng
  /// `tb_user_house_access.full_name` (tên do chính chủ nhà tự nhập lúc mời
  /// qua P-06, độc lập với hồ sơ `tb_user` thật của người đó nếu có tài
  /// khoản — giống mô hình `tb_tenant`, xem migration
  /// `20260910160000_manager_invite_profile_and_active_toggle.sql`). Không
  /// cần join `tb_user` nữa (đơn giản hơn cách làm trước — join qua `tb_user`
  /// chỉ cần thiết nếu muốn hiện hồ sơ THẬT của người đó, nhưng thiết kế đã
  /// chốt là chủ nhà tự quản lý tên riêng cho từng lời mời).
  Future<List<String>> listManagerDisplayNames(String houseId) async {
    final rows = await _client
        .from('tb_user_house_access')
        .select('phone, full_name')
        .eq('house_id', houseId)
        .eq('role', 'manager')
        .eq('is_active', true);
    return rows
        .map((r) => (r['full_name'] as String?) ?? r['phone'] as String)
        .toList();
  }

  /// Tên hiển thị của Owner (người tạo nhà) — dùng làm Manager MẶC ĐỊNH khi
  /// nhà chưa gán ai làm Manager (quyết định chốt 2026-09-10: 1 nhà chưa mời
  /// Manager thì chính Owner là người quản lý, không tạo thêm dòng DB nào vì
  /// 1 SĐT chỉ có đúng 1 vai trò/1 nhà — `unique(phone, house_id)`). Đọc
  /// được tên thật của Owner (kể cả khi người xem không phải chính họ) nhờ
  /// policy `20260910150000_tb_user_visible_to_housemates.sql`.
  Future<String?> getOwnerDisplayName(String houseId) async {
    final accessRow = await _client
        .from('tb_user_house_access')
        .select('phone')
        .eq('house_id', houseId)
        .eq('role', 'owner')
        .limit(1)
        .maybeSingle();
    if (accessRow == null) return null;
    final phone = accessRow['phone'] as String;
    final userRow = await _client
        .from('tb_user')
        .select('full_name')
        .eq('phone', phone)
        .maybeSingle();
    return (userRow?['full_name'] as String?) ?? phone;
  }

  /// Xoá nhà — DB tự chặn (lỗi FK) nếu còn phòng có lịch sử hợp đồng
  /// (`tb_contract_room.room_id references tb_room on delete restrict`), gọi
  /// nơi dùng hàm này phải bắt `PostgrestException` để hiện thông báo phù hợp.
  Future<void> delete(String houseId) async {
    await _client.from('tb_house').delete().eq('id', houseId);
  }

  /// Upload 1 ảnh nhà, trả về path để lưu vào `House.photos`.
  Future<String> uploadPhoto(String houseId, File file) async {
    final ext = file.path.split('.').last;
    final path = '$houseId/houses/${const Uuid().v4()}.$ext';
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

final houseRepository = HouseRepository(supabase);

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

  /// Tên hiển thị của những người có role `manager` cho nhà này (join
  /// `tb_user_house_access` với `tb_user` — `phone` chỉ là FK logic, không
  /// phải FK thật trong DB nên phải query 2 bước, không dùng embed của
  /// PostgREST được). Người được mời nhưng chưa có tài khoản (`phone` chưa
  /// có dòng `tb_user`) thì hiện thẳng SĐT thay vì tên. Đọc được nhờ policy
  /// mới `20260910150000_tb_user_visible_to_housemates.sql`.
  Future<List<String>> listManagerDisplayNames(String houseId) async {
    final accessRows = await _client
        .from('tb_user_house_access')
        .select('phone')
        .eq('house_id', houseId)
        .eq('role', 'manager');
    final phones = accessRows.map((r) => r['phone'] as String).toList();
    if (phones.isEmpty) return [];
    final userRows =
        await _client.from('tb_user').select('phone, full_name').inFilter(
              'phone',
              phones,
            );
    final nameByPhone = {
      for (final r in userRows) r['phone'] as String: r['full_name'] as String
    };
    return phones.map((p) => nameByPhone[p] ?? p).toList();
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

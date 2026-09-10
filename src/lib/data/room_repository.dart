import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase_client.dart';
import 'models/room.dart';

const _photosBucket = 'property-photos';

/// CRUD cho `tb_room` + ảnh trong bucket Storage `property-photos` (path
/// `<houseId>/rooms/<roomId>/<file>`, xem migration
/// `20260910130000_house_room_photos_storage.sql` — path bắt đầu bằng
/// `houseId` để dùng chung policy với ảnh Nhà).
class RoomRepository {
  final SupabaseClient _client;
  const RoomRepository(this._client);

  Future<List<Room>> listByHouse(String houseId) async {
    final rows = await _client
        .from('tb_room')
        .select()
        .eq('house_id', houseId)
        .order('room_no');
    return rows.map((row) => Room.fromMap(row)).toList();
  }

  /// Trạng thái phòng của MỌI nhà tài khoản hiện tại có quyền truy cập, gộp
  /// theo `houseId` — dùng để tính số liệu tổng quan ở H-01 (Total/Empty
  /// rooms, badge số phòng của từng nhà) mà không phải tải toàn bộ cột phòng.
  Future<Map<String, List<RoomStatus>>> listStatusesGroupedByHouse() async {
    final rows = await _client.from('tb_room').select('house_id, status');
    final map = <String, List<RoomStatus>>{};
    for (final row in rows) {
      final houseId = row['house_id'] as String;
      map
          .putIfAbsent(houseId, () => [])
          .add(RoomStatusX.fromDb(row['status'] as String));
    }
    return map;
  }

  Future<Room> getById(String roomId) async {
    final row =
        await _client.from('tb_room').select().eq('id', roomId).single();
    return Room.fromMap(row);
  }

  Future<Room> create(Room room) async {
    final row = await _client
        .from('tb_room')
        .insert(room.toInsertMap())
        .select()
        .single();
    return Room.fromMap(row);
  }

  Future<Room> update(String roomId, Room room) async {
    final row = await _client
        .from('tb_room')
        .update(room.toInsertMap())
        .eq('id', roomId)
        .select()
        .single();
    return Room.fromMap(row);
  }

  /// Xoá phòng — DB tự chặn (lỗi FK `on delete restrict`) nếu phòng còn từng
  /// thuộc hợp đồng nào (kể cả đã Ended), gọi nơi dùng phải bắt
  /// `PostgrestException` để hiện thông báo phù hợp.
  Future<void> delete(String roomId) async {
    await _client.from('tb_room').delete().eq('id', roomId);
  }

  Future<String> uploadPhoto(String houseId, String roomId, File file) async {
    final ext = file.path.split('.').last;
    final path = '$houseId/rooms/$roomId/${const Uuid().v4()}.$ext';
    await _client.storage.from(_photosBucket).upload(path, file);
    return path;
  }

  Future<void> deletePhoto(String path) async {
    await _client.storage.from(_photosBucket).remove([path]);
  }

  Future<String> signedPhotoUrl(String path) async {
    return _client.storage.from(_photosBucket).createSignedUrl(path, 3600);
  }
}

final roomRepository = RoomRepository(supabase);

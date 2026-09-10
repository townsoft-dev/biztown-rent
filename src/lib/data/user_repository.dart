import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import 'models/manager_account.dart';
import 'models/user_profile.dart';

/// CRUD cho hồ sơ cá nhân (`tb_user`, P-01/P-02), đổi mật khẩu, và quản lý
/// Manager (`tb_user_house_access` role=manager, P-05/P-06) — seri màn
/// Profile & Settings.
class UserRepository {
  final SupabaseClient _client;
  const UserRepository(this._client);

  /// SĐT tài khoản hiện tại — GoTrue trả về KHÔNG có dấu "+", khớp đúng quy
  /// ước `current_user_phone()`/`tb_user_house_access.phone` dùng khắp hệ
  /// thống (xem changelog 2026-09-10 vụ sửa lỗi lệch định dạng SĐT).
  String get _myPhone => _client.auth.currentUser!.phone!;

  Future<UserProfile> getCurrentProfile() async {
    final userId = _client.auth.currentUser!.id;
    final row =
        await _client.from('tb_user').select().eq('id', userId).single();
    return UserProfile.fromMap(row);
  }

  Future<void> updateProfile(
      {required String fullName, String? idNumber}) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('tb_user').update({
      'full_name': fullName,
      'id_number': idNumber,
    }).eq('id', userId);
  }

  /// Đổi mật khẩu — Supabase không có API riêng để "xác thực mật khẩu hiện
  /// tại" mà không đổi session, nên xác thực bằng cách đăng nhập lại
  /// (`signInWithPassword` ném lỗi ngay nếu sai mật khẩu hiện tại) rồi mới
  /// `updateUser`.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.auth
        .signInWithPassword(phone: '+$_myPhone', password: currentPassword);
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// "Main Manager" (P-01/P-02 badge) — tính SỐNG mỗi lần gọi, không cache:
  /// true nếu tài khoản này đang sở hữu (`role=owner`) ít nhất 1 Nhà. 1 tài
  /// khoản có thể vừa Main Manager (nhà riêng) vừa Manager (nhà người khác
  /// giao) cùng lúc — xác nhận với dungtv 2026-09-10 (Đợt 20).
  Future<bool> isMainManager() async {
    final rows = await _client
        .from('tb_user_house_access')
        .select('id')
        .eq('phone', _myPhone)
        .eq('role', 'owner')
        .eq('is_active', true)
        .limit(1);
    return rows.isNotEmpty;
  }

  /// ID các Nhà tài khoản hiện tại đang SỞ HỮU (không tính nhà chỉ được giao
  /// làm Manager) — dùng cho danh sách "House access" ở P-06 và "Houses" ở
  /// P-03 (chỉ Owner mới mời Manager/sửa tài khoản nhận tiền).
  Future<Set<String>> listOwnedHouseIds() async {
    final rows = await _client
        .from('tb_user_house_access')
        .select('house_id')
        .eq('phone', _myPhone)
        .eq('role', 'owner')
        .eq('is_active', true);
    return rows.map((r) => r['house_id'] as String).toSet();
  }

  /// Gộp mọi dòng quyền `role=manager` của các Nhà tôi sở hữu THEO NGƯỜI
  /// (1 người có thể được giao nhiều Nhà → nhiều dòng) — nguồn cho P-05.
  Future<List<ManagerAccount>> listManagerAccounts() async {
    final ownedIds = await listOwnedHouseIds();
    if (ownedIds.isEmpty) return const [];
    final rows = await _client
        .from('tb_user_house_access')
        .select()
        .eq('role', 'manager')
        .inFilter('house_id', ownedIds.toList());

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row['phone'] as String, () => []).add(row);
    }
    return grouped.entries.map((entry) {
      final personRows = entry.value;
      final first = personRows.first;
      return ManagerAccount(
        phone: entry.key,
        fullName: (first['full_name'] as String?) ?? entry.key,
        idNumber: first['id_number'] as String?,
        note: first['note'] as String?,
        isActive: personRows.any((r) => r['is_active'] as bool),
        joinedAt: personRows
            .map((r) => DateTime.parse(r['granted_at'] as String))
            .reduce((a, b) => a.isBefore(b) ? a : b),
        houseIds: personRows.map((r) => r['house_id'] as String).toSet(),
      );
    }).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  /// Với mỗi Nhà tôi sở hữu, Manager ĐANG active hiện tại (nếu có) —
  /// {houseId: (phone, tên)}. Dùng ở P-06 để disable checkbox khi đang gán
  /// 1 Manager KHÁC vào Nhà đã có người quản lý (quyết định chốt với dungtv
  /// 2026-09-10: 1 Nhà chỉ 1 Manager active tại 1 thời điểm).
  Future<Map<String, ({String phone, String name})>>
      currentActiveManagerByHouse() async {
    final ownedIds = await listOwnedHouseIds();
    if (ownedIds.isEmpty) return {};
    final rows = await _client
        .from('tb_user_house_access')
        .select('house_id, phone, full_name')
        .inFilter('house_id', ownedIds.toList())
        .eq('role', 'manager')
        .eq('is_active', true);
    return {
      for (final row in rows)
        row['house_id'] as String: (
          phone: row['phone'] as String,
          name: (row['full_name'] as String?) ?? row['phone'] as String,
        ),
    };
  }

  /// Lưu (tạo mới hoặc sửa) 1 Manager — đồng bộ `fullName`/`idNumber`/
  /// `isActive` xuống MỌI dòng `tb_user_house_access` của người này thuộc
  /// các Nhà vừa tick ở `houseIds`, thêm dòng mới cho Nhà mới tick, xoá dòng
  /// cho Nhà vừa bỏ tick. `previousHouseIds` rỗng khi tạo Manager mới.
  Future<void> saveManager({
    required String phone,
    required String fullName,
    String? idNumber,
    String? note,
    required bool isActive,
    required Set<String> houseIds,
    required Set<String> previousHouseIds,
  }) async {
    final toAdd = houseIds.difference(previousHouseIds);
    final toKeep = houseIds.intersection(previousHouseIds);
    final toRemove = previousHouseIds.difference(houseIds);

    for (final houseId in toAdd) {
      await _client.from('tb_user_house_access').insert({
        'phone': phone,
        'house_id': houseId,
        'role': 'manager',
        'full_name': fullName,
        'id_number': idNumber,
        'note': note,
        'is_active': isActive,
        'granted_by_phone': _myPhone,
      });
    }
    for (final houseId in toKeep) {
      await _client
          .from('tb_user_house_access')
          .update({
            'full_name': fullName,
            'id_number': idNumber,
            'note': note,
            'is_active': isActive,
          })
          .eq('phone', phone)
          .eq('house_id', houseId)
          .eq('role', 'manager');
    }
    for (final houseId in toRemove) {
      await _client
          .from('tb_user_house_access')
          .delete()
          .eq('phone', phone)
          .eq('house_id', houseId)
          .eq('role', 'manager');
    }
  }

  /// Thu quyền Manager hoàn toàn — xoá mọi dòng `role=manager` của người này
  /// thuộc các Nhà tôi sở hữu (không đụng dòng ở Nhà của chủ khác nếu người
  /// này quản lý nhiều nơi).
  Future<void> removeManager(String phone) async {
    final ownedIds = await listOwnedHouseIds();
    if (ownedIds.isEmpty) return;
    await _client
        .from('tb_user_house_access')
        .delete()
        .eq('phone', phone)
        .eq('role', 'manager')
        .inFilter('house_id', ownedIds.toList());
  }
}

final userRepository = UserRepository(supabase);

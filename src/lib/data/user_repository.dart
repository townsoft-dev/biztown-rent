import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase_client.dart';
import 'models/manager_account.dart';
import 'models/user_profile.dart';

const _avatarsBucket = 'avatars';

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

  /// Upload ảnh đại diện mới, cập nhật `tb_user.avatar_path` luôn (không đợi
  /// bấm "Save" chung của form — đổi ảnh là hành động tức thời, tách khỏi
  /// Full name/ID number vẫn cần Save riêng). Trả về path mới để màn gọi tự
  /// xoá ảnh cũ (nếu có) sau khi cập nhật DB thành công.
  Future<String> uploadAvatar(File file) async {
    final userId = _client.auth.currentUser!.id;
    final ext = file.path.split('.').last;
    final path = '$userId/${const Uuid().v4()}.$ext';
    await _client.storage.from(_avatarsBucket).upload(path, file);
    await _client
        .from('tb_user')
        .update({'avatar_path': path}).eq('id', userId);
    return path;
  }

  Future<void> deleteAvatar(String path) async {
    await _client.storage.from(_avatarsBucket).remove([path]);
  }

  /// URL tạm (1h) để hiển thị avatar — bucket private nên không dùng
  /// `getPublicUrl`, cùng quy ước với `HouseRepository.signedPhotoUrl`.
  Future<String> signedAvatarUrl(String path) async {
    return _client.storage.from(_avatarsBucket).createSignedUrl(path, 3600);
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

  /// Gộp mọi dòng quyền `role=manager` của các Nhà tôi sở hữu THEO NGƯỜI (1
  /// người có thể được giao nhiều Nhà → nhiều dòng), CỘNG THÊM hồ sơ "nháp"
  /// (chưa gán Nhà nào, `house_id is null`) do CHÍNH tôi tạo — nguồn cho
  /// P-05. Đợt 2026-09-11: cho phép 1 Manager tồn tại mà chưa gán Nhà nào
  /// (trước đó bắt buộc phải có ≥1 Nhà mới lưu được gì, xem DECISIONS.md).
  Future<List<ManagerAccount>> listManagerAccounts() async {
    final ownedIds = await listOwnedHouseIds();
    final houseRows = ownedIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _client
            .from('tb_user_house_access')
            .select()
            .eq('role', 'manager')
            .inFilter('house_id', ownedIds.toList());
    final draftRows = await _client
        .from('tb_user_house_access')
        .select()
        .eq('role', 'manager')
        .eq('granted_by_phone', _myPhone)
        .isFilter('house_id', null);
    final rows = [...houseRows, ...draftRows];
    if (rows.isEmpty) return const [];

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
        // `house_id` null cho dòng nháp — loại bỏ trước khi gom vào Set.
        houseIds: personRows
            .map((r) => r['house_id'] as String?)
            .whereType<String>()
            .toSet(),
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
  ///
  /// `houseIds` rỗng (chưa/không còn gán Nhà nào) KHÔNG có nghĩa là không
  /// lưu gì — tự lưu/giữ lại 1 dòng "nháp" (`house_id = null`) mang hồ sơ
  /// (tên/SĐT/CCCD/note/active) để Manager vẫn "tồn tại", gán Nhà sau này
  /// cũng được (đổi kiến trúc 2026-09-11, xem DECISIONS.md — trước đó Save
  /// với 0 Nhà sẽ mất trắng toàn bộ form mà không báo lỗi gì).
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

    if (houseIds.isEmpty) {
      final draftData = {
        'phone': phone,
        'house_id': null,
        'role': 'manager',
        'full_name': fullName,
        'id_number': idNumber,
        'note': note,
        'is_active': isActive,
        'granted_by_phone': _myPhone,
      };
      final existingDraft = await _client
          .from('tb_user_house_access')
          .select('id')
          .eq('phone', phone)
          .eq('granted_by_phone', _myPhone)
          .eq('role', 'manager')
          .isFilter('house_id', null)
          .maybeSingle();
      if (existingDraft == null) {
        await _client.from('tb_user_house_access').insert(draftData);
      } else {
        await _client
            .from('tb_user_house_access')
            .update(draftData)
            .eq('id', existingDraft['id'] as String);
      }
    } else {
      // Vừa được gán ≥1 Nhà thật — hồ sơ nay sống trên các dòng đó, dòng
      // nháp (nếu còn sót từ trước) không cần nữa.
      await _client
          .from('tb_user_house_access')
          .delete()
          .eq('phone', phone)
          .eq('granted_by_phone', _myPhone)
          .eq('role', 'manager')
          .isFilter('house_id', null);
    }
  }

  /// Thu quyền Manager hoàn toàn — xoá mọi dòng `role=manager` của người này
  /// thuộc các Nhà tôi sở hữu (không đụng dòng ở Nhà của chủ khác nếu người
  /// này quản lý nhiều nơi), CỘNG cả dòng "nháp" (chưa gán Nhà) do tôi tạo
  /// nếu có.
  Future<void> removeManager(String phone) async {
    final ownedIds = await listOwnedHouseIds();
    if (ownedIds.isNotEmpty) {
      await _client
          .from('tb_user_house_access')
          .delete()
          .eq('phone', phone)
          .eq('role', 'manager')
          .inFilter('house_id', ownedIds.toList());
    }
    await _client
        .from('tb_user_house_access')
        .delete()
        .eq('phone', phone)
        .eq('granted_by_phone', _myPhone)
        .eq('role', 'manager')
        .isFilter('house_id', null);
  }
}

final userRepository = UserRepository(supabase);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../data/house_repository.dart';
import '../data/models/house.dart';
import '../data/models/manager_account.dart';
import '../data/models/reading.dart';
import '../data/models/room.dart';
import '../data/models/user_profile.dart';
import '../data/reading_repository.dart';
import '../data/room_repository.dart';
import '../data/user_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => authRepository);

/// Session hiện tại — S-00 dùng để quyết định vào H-01 hay S-01.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Tên tài khoản đang đăng nhập (Header H-01 "Hello, {tên}") — watch
/// `authStateProvider` để tự làm mới đúng người khi đổi phiên đăng nhập.
final currentUserNameProvider = FutureProvider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentFullName();
});

final userRepositoryProvider =
    Provider<UserRepository>((ref) => userRepository);

/// Hồ sơ đầy đủ tài khoản đang đăng nhập (P-01/P-02) — watch
/// `authStateProvider` để tự làm mới đúng người khi đổi phiên đăng nhập.
final currentUserProfileProvider = FutureProvider<UserProfile>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(userRepositoryProvider).getCurrentProfile();
});

/// "Main Manager" badge (P-01/P-02) — xem `UserRepository.isMainManager`.
final isMainManagerProvider = FutureProvider<bool>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(userRepositoryProvider).isMainManager();
});

/// ID các Nhà tài khoản hiện tại SỞ HỮU — dùng ở P-03/P-06.
final ownedHouseIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.watch(userRepositoryProvider).listOwnedHouseIds();
});

/// Danh sách Manager (gộp theo người) của các Nhà tôi sở hữu — P-05.
final managerAccountsProvider = FutureProvider<List<ManagerAccount>>((ref) {
  return ref.watch(userRepositoryProvider).listManagerAccounts();
});

/// Manager active hiện tại theo từng Nhà — P-06 (disable checkbox khi Nhà đã
/// có người quản lý khác).
final activeManagerByHouseProvider =
    FutureProvider<Map<String, ({String phone, String name})>>((ref) {
  return ref.watch(userRepositoryProvider).currentActiveManagerByHouse();
});

final houseRepositoryProvider =
    Provider<HouseRepository>((ref) => houseRepository);
final roomRepositoryProvider =
    Provider<RoomRepository>((ref) => roomRepository);

/// Danh sách nhà (H-01) — gọi `ref.invalidate(housesProvider)` sau khi
/// tạo/sửa/xoá nhà để list tự làm mới, tránh mỗi màn tự quản lý cache riêng.
final housesProvider = FutureProvider<List<House>>((ref) {
  return ref.watch(houseRepositoryProvider).listMyHouses();
});

final houseProvider = FutureProvider.family<House, String>((ref, houseId) {
  return ref.watch(houseRepositoryProvider).getById(houseId);
});

/// Tên các Manager của 1 nhà (H-03 "Owner" section, field "Manager") — xem
/// `HouseRepository.listManagerDisplayNames`.
final houseManagersProvider =
    FutureProvider.family<List<String>, String>((ref, houseId) {
  return ref.watch(houseRepositoryProvider).listManagerDisplayNames(houseId);
});

/// Tên Owner — dùng làm fallback hiển thị field "Manager" khi nhà chưa gán
/// ai. Xem `HouseRepository.getOwnerDisplayName`.
final houseOwnerNameProvider =
    FutureProvider.family<String?, String>((ref, houseId) {
  return ref.watch(houseRepositoryProvider).getOwnerDisplayName(houseId);
});

/// Danh sách phòng theo nhà (H-03 tab Rooms) — invalidate sau khi tạo/sửa/xoá phòng.
final roomsProvider = FutureProvider.family<List<Room>, String>((ref, houseId) {
  return ref.watch(roomRepositoryProvider).listByHouse(houseId);
});

final roomProvider = FutureProvider.family<Room, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).getById(roomId);
});

/// Trạng thái phòng mọi nhà, gộp theo houseId (H-01 tổng quan) — xem
/// `RoomRepository.listStatusesGroupedByHouse`.
final roomStatusesByHouseProvider =
    FutureProvider<Map<String, List<RoomStatus>>>((ref) {
  return ref.watch(roomRepositoryProvider).listStatusesGroupedByHouse();
});

final readingRepositoryProvider =
    Provider<ReadingRepository>((ref) => readingRepository);

/// 1 dòng dữ liệu cho 1 `MeterCard` ở H-06 Entry: chỉ số cũ gần nhất + đã ghi
/// kỳ này chưa (BR-READ-02/07).
class RoomMeterEntry {
  final Room room;
  final UtilityType utilityType;
  final Reading? previous;
  final Reading? thisPeriod;

  const RoomMeterEntry(
      {required this.room,
      required this.utilityType,
      this.previous,
      this.thisPeriod});

  bool get recorded => thisPeriod != null;
}

/// Tham số cho `houseMeterEntriesProvider` — record tự implement `==`/`hashCode`
/// theo từng field nên dùng trực tiếp làm key `FutureProvider.family` được.
typedef HouseReadingPeriodKey = ({String houseId, DateTime periodYm});

/// Dữ liệu đầy đủ cho màn H-06 Entry: mọi phòng của 1 nhà × 2 tiện ích (điện,
/// nước) — mỗi phòng luôn ghi cả 2 loại (BR-READ-05: bỏ qua theo hợp đồng
/// NOT_BILLED để sau, vì Tenant/Contract chưa xây nên chưa có hợp đồng nào để
/// mà bỏ qua trong thực tế).
final houseMeterEntriesProvider =
    FutureProvider.family<List<RoomMeterEntry>, HouseReadingPeriodKey>(
        (ref, key) async {
  final rooms =
      await ref.watch(roomRepositoryProvider).listByHouse(key.houseId);
  final repo = ref.watch(readingRepositoryProvider);
  final entries = <RoomMeterEntry>[];
  for (final room in rooms) {
    for (final type in UtilityType.values) {
      final thisPeriod =
          await repo.periodicForPeriod(room.id, type, key.periodYm);
      // "Previous" luôn là chỉ số TRƯỚC kỳ đang xem — nếu kỳ này đã ghi rồi,
      // không được dùng `latestForRoom` (nó sẽ trả về chính bản ghi của kỳ
      // này, vì đó luôn là bản ghi mới nhất) mà phải lần theo
      // `previousReadingId` của chính bản ghi kỳ này.
      final previous = thisPeriod != null
          ? (thisPeriod.previousReadingId == null
              ? null
              : await repo.byId(thisPeriod.previousReadingId!, type))
          : await repo.latestForRoom(room.id, type);
      entries.add(RoomMeterEntry(
          room: room,
          utilityType: type,
          previous: previous,
          thisPeriod: thisPeriod));
    }
  }
  return entries;
});

/// Lịch sử đầy đủ 1 phòng + 1 tiện ích (H-06 Detail).
typedef RoomUtilityKey = ({String roomId, UtilityType utilityType});

final readingHistoryProvider =
    FutureProvider.family<List<Reading>, RoomUtilityKey>((ref, key) {
  return ref
      .watch(readingRepositoryProvider)
      .historyForRoom(key.roomId, key.utilityType);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../data/house_repository.dart';
import '../data/models/house.dart';
import '../data/models/room.dart';
import '../data/room_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => authRepository);

/// Session hiện tại — S-00 dùng để quyết định vào H-01 hay S-01.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'invoice_period.dart';
import '../data/auth_repository.dart';
import '../data/contract_repository.dart';
import '../data/house_repository.dart';
import '../data/invoice_repository.dart';
import '../data/models/app_notification.dart';
import '../data/models/contract.dart';
import '../data/models/house.dart';
import '../data/models/invoice.dart';
import '../data/models/manager_account.dart';
import '../data/models/reading.dart';
import '../data/models/room.dart';
import '../data/models/tenant.dart';
import '../data/models/user_profile.dart';
import '../data/notification_repository.dart';
import '../data/reading_repository.dart';
import '../data/room_repository.dart';
import '../data/tenant_repository.dart';
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

/// URL tạm để hiển thị avatar (P-01/P-02) — family theo path vì mỗi lần đổi
/// ảnh, `avatar_path` đổi sang 1 UUID mới nên tự tạo key cache mới, không cần
/// tự tay invalidate provider này khi đổi ảnh.
final avatarUrlProvider = FutureProvider.family<String, String>((ref, path) {
  return ref.watch(userRepositoryProvider).signedAvatarUrl(path);
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

// ============================================================
// T-0x — Tenant & Contract
// ============================================================

final tenantRepositoryProvider =
    Provider<TenantRepository>((ref) => tenantRepository);
final contractRepositoryProvider =
    Provider<ContractRepository>((ref) => contractRepository);

/// Toàn bộ Tenant Pool thuộc phạm vi các Nhà đang có quyền — T-01.
final tenantsProvider = FutureProvider<List<Tenant>>((ref) {
  return ref.watch(tenantRepositoryProvider).listAll();
});

final tenantProvider = FutureProvider.family<Tenant, String>((ref, tenantId) {
  return ref.watch(tenantRepositoryProvider).getById(tenantId);
});

/// Toàn bộ hợp đồng thuộc phạm vi các Nhà đang có quyền — nguồn thô cho T-02.
final contractsProvider = FutureProvider<List<Contract>>((ref) {
  return ref.watch(contractRepositoryProvider).listAll();
});

final contractProvider =
    FutureProvider.family<Contract, String>((ref, contractId) {
  return ref.watch(contractRepositoryProvider).getById(contractId);
});

/// Mọi hợp đồng (mọi trạng thái) của 1 Tenant, mới nhất trước — T-03.
final contractsByTenantProvider =
    FutureProvider.family<List<Contract>, String>((ref, tenantId) {
  return ref.watch(contractRepositoryProvider).listByTenant(tenantId);
});

final contractVersionProvider =
    FutureProvider.family<ContractVersion, String>((ref, versionId) {
  return ref.watch(contractRepositoryProvider).getVersionById(versionId);
});

/// Lịch sử phiên bản điều khoản của 1 hợp đồng, mới nhất trước — T-08.
final contractVersionsProvider =
    FutureProvider.family<List<ContractVersion>, String>((ref, contractId) {
  return ref
      .watch(contractRepositoryProvider)
      .listVersionsByContract(contractId);
});

/// Hợp đồng Active hiện tại của 1 phòng (kèm điều khoản hiện hành + Tenant),
/// null nếu phòng đang Empty — H-04 Room Detail khối "Current contract".
class RoomActiveContract {
  final Contract contract;
  final ContractVersion version;
  final Tenant tenant;

  const RoomActiveContract(
      {required this.contract, required this.version, required this.tenant});
}

final roomActiveContractProvider =
    FutureProvider.family<RoomActiveContract?, String>((ref, roomId) async {
  final contractRepo = ref.watch(contractRepositoryProvider);
  final contractId = await contractRepo.activeContractIdForRoom(roomId);
  if (contractId == null) return null;
  final contract = await contractRepo.getById(contractId);
  final version = await ref
      .watch(contractVersionProvider(contract.currentVersionId!).future);
  final tenant = await ref.watch(tenantProvider(contract.tenantId).future);
  return RoomActiveContract(
      contract: contract, version: version, tenant: tenant);
});

final contractRoomIdsProvider =
    FutureProvider.family<List<String>, String>((ref, contractId) {
  return ref
      .watch(contractRepositoryProvider)
      .listRoomIdsByContract(contractId);
});

/// Danh sách phòng (đầy đủ) của 1 hợp đồng — T-03/T-05.
final contractRoomsProvider =
    FutureProvider.family<List<Room>, String>((ref, contractId) async {
  final roomIds = await ref.watch(contractRoomIdsProvider(contractId).future);
  return ref.watch(roomRepositoryProvider).listByIds(roomIds);
});

/// 1 dòng hiển thị cho T-01 (Tenant list) — Tenant + hợp đồng Active hiện tại
/// (nếu có) + phòng/nhà đang thuê. `activeContract == null` ⇒ "Unassigned".
class TenantListItem {
  final Tenant tenant;
  final Contract? activeContract;
  final List<Room> rooms;
  final House? house;

  const TenantListItem({
    required this.tenant,
    this.activeContract,
    this.rooms = const [],
    this.house,
  });

  bool get isRenting => activeContract != null;
}

/// Ghép Tenant + hợp đồng Active + phòng/nhà — tránh N+1 query bằng cách gọi
/// các hàm `...ByIds`/`...ByContractIds` theo lô, xem `ContractRepository`.
final tenantListProvider = FutureProvider<List<TenantListItem>>((ref) async {
  final contractRepo = ref.watch(contractRepositoryProvider);
  final tenants = await ref.watch(tenantsProvider.future);
  final contracts = await ref.watch(contractsProvider.future);

  final activeByTenant = <String, Contract>{
    for (final c in contracts)
      if (c.status == ContractStatus.active) c.tenantId: c,
  };
  final roomIdsByContract = await contractRepo
      .roomIdsByContractIds(activeByTenant.values.map((c) => c.id).toList());
  final allRoomIds =
      roomIdsByContract.values.expand((ids) => ids).toSet().toList();
  final rooms = await ref.watch(roomRepositoryProvider).listByIds(allRoomIds);
  final roomsById = {for (final r in rooms) r.id: r};
  final houses = await ref.watch(housesProvider.future);
  final housesById = {for (final h in houses) h.id: h};

  return tenants.map((t) {
    final contract = activeByTenant[t.id];
    if (contract == null) return TenantListItem(tenant: t);
    final roomIds = roomIdsByContract[contract.id] ?? const [];
    final tenantRooms =
        roomIds.map((id) => roomsById[id]).whereType<Room>().toList();
    final house =
        tenantRooms.isEmpty ? null : housesById[tenantRooms.first.houseId];
    return TenantListItem(
        tenant: t, activeContract: contract, rooms: tenantRooms, house: house);
  }).toList();
});

/// 1 dòng hiển thị cho T-02 (Contract list) — Hợp đồng + điều khoản hiện
/// hành + Tenant đại diện + phòng/nhà.
class ContractListItem {
  final Contract contract;
  final ContractVersion currentVersion;
  final Tenant tenant;
  final List<Room> rooms;
  final House house;

  const ContractListItem({
    required this.contract,
    required this.currentVersion,
    required this.tenant,
    required this.rooms,
    required this.house,
  });

  /// Ngưỡng 30 ngày theo SCREEN-SPEC.md T-05 — chỉ tính khi hợp đồng đang Active.
  bool get isEndingSoon =>
      contract.status == ContractStatus.active &&
      !currentVersion.endDate.isBefore(DateTime.now()) &&
      currentVersion.endDate.difference(DateTime.now()).inDays <= 30;
}

final contractListProvider =
    FutureProvider<List<ContractListItem>>((ref) async {
  final contractRepo = ref.watch(contractRepositoryProvider);
  final contracts = await ref.watch(contractsProvider.future);
  if (contracts.isEmpty) return const [];

  final versionIds =
      contracts.map((c) => c.currentVersionId).whereType<String>().toList();
  final versions = await contractRepo.listVersionsByIds(versionIds);
  final versionsById = {for (final v in versions) v.id: v};

  final tenantIds = contracts.map((c) => c.tenantId).toSet().toList();
  final tenants = await Future.wait(
      tenantIds.map((id) => ref.watch(tenantRepositoryProvider).getById(id)));
  final tenantsById = {for (final t in tenants) t.id: t};

  final roomIdsByContract = await contractRepo
      .roomIdsByContractIds(contracts.map((c) => c.id).toList());
  final allRoomIds =
      roomIdsByContract.values.expand((ids) => ids).toSet().toList();
  final rooms = await ref.watch(roomRepositoryProvider).listByIds(allRoomIds);
  final roomsById = {for (final r in rooms) r.id: r};
  final houses = await ref.watch(housesProvider.future);
  final housesById = {for (final h in houses) h.id: h};

  final items = <ContractListItem>[];
  for (final c in contracts) {
    final version = versionsById[c.currentVersionId];
    final tenant = tenantsById[c.tenantId];
    if (version == null || tenant == null) continue;
    final roomIds = roomIdsByContract[c.id] ?? const [];
    final contractRooms =
        roomIds.map((id) => roomsById[id]).whereType<Room>().toList();
    if (contractRooms.isEmpty) continue;
    final house = housesById[contractRooms.first.houseId];
    if (house == null) continue;
    items.add(ContractListItem(
        contract: c,
        currentVersion: version,
        tenant: tenant,
        rooms: contractRooms,
        house: house));
  }
  return items;
});

final invoiceRepositoryProvider =
    Provider<InvoiceRepository>((ref) => invoiceRepository);

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => notificationRepository);

/// S-03 — danh sách thông báo của người đang đăng nhập (RLS tự giới hạn đúng
/// `recipient_phone`). Dùng Realtime (`StreamProvider`, không phải
/// `FutureProvider`) để chuông/danh sách tự cập nhật ngay cả khi thông báo
/// mới đến từ người khác (quản lý khác, hoặc backend) trong lúc app đang mở
/// sẵn — không chỉ khi chính người dùng vừa thao tác xong (dungtv yêu cầu
/// 2026-09-15, xem docs/DECISIONS.md).
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).watch();
});

/// Số thông báo chưa đọc — hiện chấm đỏ trên chuông ở Home.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return items.where((n) => n.isUnread).length;
});

/// Hoá đơn chưa `Collected` của 1 hợp đồng — T-09 "Outstanding invoices".
final unpaidInvoicesProvider =
    FutureProvider.family<List<Invoice>, String>((ref, contractId) {
  return ref.watch(invoiceRepositoryProvider).listUnpaidByContract(contractId);
});

/// Mọi hoá đơn (mọi trạng thái) của 1 hợp đồng — T-05 dải chip "Invoice
/// schedule".
final contractInvoicesProvider =
    FutureProvider.family<List<Invoice>, String>((ref, contractId) {
  return ref.watch(invoiceRepositoryProvider).listByContract(contractId);
});

/// Mọi hoá đơn thuộc phạm vi các nhà đang có quyền — B-01.
final invoicesProvider = FutureProvider<List<Invoice>>((ref) {
  return ref.watch(invoiceRepositoryProvider).listAll();
});

/// 1 hoá đơn cụ thể — B-04.
final invoiceProvider =
    FutureProvider.family<Invoice, String>((ref, invoiceId) {
  return ref.watch(invoiceRepositoryProvider).getById(invoiceId);
});

/// 1 dòng hợp đồng hiển thị trên B-01 — hợp đồng Active + dải chip kỳ hoá
/// đơn (tái dùng đúng `buildInvoiceScheduleChips` của T-05) + hoá đơn kỳ
/// HIỆN TẠI (nếu có) để hiện badge/subtitle đúng trạng thái.
class BillsContractRow {
  final Contract contract;
  final ContractVersion version;
  final Tenant tenant;
  final House house;
  final String roomNosLabel;
  final List<InvoiceScheduleChipData> chips;
  final Invoice? selectedPeriodInvoice;

  const BillsContractRow({
    required this.contract,
    required this.version,
    required this.tenant,
    required this.house,
    required this.roomNosLabel,
    required this.chips,
    this.selectedPeriodInvoice,
  });
}

class BillsHouseGroup {
  final House house;
  final List<BillsContractRow> rows;
  const BillsHouseGroup({required this.house, required this.rows});
}

/// Nhóm mọi hợp đồng Active theo Nhà — B-01. `periodYm` chỉ dùng để tìm ĐÚNG
/// hoá đơn của kỳ đang xem (`selectedPeriodInvoice`, cho badge/subtitle) —
/// dải chip `chips` luôn tính theo hôm nay thật (không đổi theo kỳ đang chọn)
/// vì ý nghĩa "Current" (167:54) là kỳ đã tới hạn thật, không phải kỳ đang
/// browse. Không lọc theo trạng thái ở đây (lọc ở tầng UI).
final billsHouseGroupsProvider =
    FutureProvider.family<List<BillsHouseGroup>, DateTime>(
        (ref, periodYm) async {
  final contractRepo = ref.watch(contractRepositoryProvider);
  final contracts = await ref.watch(contractsProvider.future);
  final activeContracts =
      contracts.where((c) => c.status == ContractStatus.active).toList();
  if (activeContracts.isEmpty) return const [];

  final versions = await contractRepo.listVersionsByIds(
      activeContracts.map((c) => c.currentVersionId!).toList());
  final versionById = {for (final v in versions) v.id: v};

  final roomIdsByContract = await contractRepo
      .roomIdsByContractIds(activeContracts.map((c) => c.id).toList());
  final allRoomIds =
      roomIdsByContract.values.expand((ids) => ids).toSet().toList();
  final rooms = await ref.watch(roomRepositoryProvider).listByIds(allRoomIds);
  final roomsById = {for (final r in rooms) r.id: r};

  final houses = await ref.watch(housesProvider.future);
  final housesById = {for (final h in houses) h.id: h};

  final rowsByHouse = <String, List<BillsContractRow>>{};
  for (final contract in activeContracts) {
    final version = versionById[contract.currentVersionId];
    if (version == null) continue;
    final tenant = await ref.watch(tenantProvider(contract.tenantId).future);
    final roomIds = roomIdsByContract[contract.id] ?? const [];
    final contractRooms =
        roomIds.map((id) => roomsById[id]).whereType<Room>().toList();
    if (contractRooms.isEmpty) continue;
    final house = housesById[contractRooms.first.houseId];
    if (house == null) continue;

    final invoices =
        await ref.watch(contractInvoicesProvider(contract.id).future);
    final chips = buildInvoiceScheduleChips(version, invoices);
    final targetPeriod = periodStartingAt(version, periodYm);
    final matchingInvoices =
        invoices.where((i) => i.periodStart == targetPeriod.start);
    final selectedInvoice =
        matchingInvoices.isEmpty ? null : matchingInvoices.first;

    rowsByHouse.putIfAbsent(house.id, () => []).add(BillsContractRow(
          contract: contract,
          version: version,
          tenant: tenant,
          house: house,
          roomNosLabel: contractRooms.map((r) => r.roomNo).join(', '),
          chips: chips,
          selectedPeriodInvoice: selectedInvoice,
        ));
  }

  return rowsByHouse.entries
      .map((e) => BillsHouseGroup(house: housesById[e.key]!, rows: e.value))
      .toList();
});

/// Key cho [batchPreviewProvider] — 1 Nhà + 1 kỳ.
typedef BatchPreviewArgs = ({String houseId, DateTime periodYm});

/// Xem trước danh sách hợp đồng + số tiền ước tính cho B-03 (KHÔNG tạo hoá
/// đơn thật) — gọi Edge Function `mode: "previewBatch"`.
final batchPreviewProvider =
    FutureProvider.family<List<BatchPreviewItem>, BatchPreviewArgs>(
        (ref, args) {
  return ref
      .watch(invoiceRepositoryProvider)
      .previewBatch(houseId: args.houseId, periodYm: args.periodYm);
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_strings.dart';
import '../core/enum_labels.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/house.dart';
import '../data/models/room.dart';
import '../data/models/vn_bank.dart';
import '../shared/app_chip.dart';
import '../shared/app_fab.dart';
import '../shared/confirm_dialog.dart';
import '../shared/detail_row.dart';
import '../shared/list_card.dart';
import '../shared/section_label.dart';
import '../shared/segmented_control.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';
import 'package:material_symbols_icons/symbols.dart';

/// H-03 — Room List (theo 1 House) (node 220:2424 "Rooms" + 312:2069 "House
/// detail", lấy qua Figma MCP 10/09/2026) — 1 màn, 2 state qua Segmented
/// control. Nối CRUD thật vào `tb_house`/`tb_room` (10/09/2026, xem
/// changelog/2026-09-10.md).
class RoomListScreen extends ConsumerStatefulWidget {
  final String houseId;

  const RoomListScreen({super.key, required this.houseId});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  int _tab = 0; // 0 = House detail, 1 = Rooms
  int _filter = 0; // 0=All 1=Empty 2=Occupied 3=Under repair

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final houseAsync = ref.watch(houseProvider(widget.houseId));
    final roomsAsync = ref.watch(roomsProvider(widget.houseId));

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      floatingActionButton: _tab == 1
          ? AppFab(
              onPressed: () =>
                  context.push('/home/houses/${widget.houseId}/rooms/new'))
          : null,
      body: Column(
        children: [
          houseAsync.when(
            data: (house) {
              final rooms = roomsAsync.valueOrNull ?? const <Room>[];
              final occupied =
                  rooms.where((r) => r.status == RoomStatus.occupied).length;
              return TopBar(
                title: house.name,
                subtitle: AppStrings.t('roomList.headerSubtitle', {
                  'address': house.address,
                  'occupied': '$occupied',
                  'total': '${rooms.length}',
                }),
                onBack: () => context.pop(),
                trailing: TopBarActionMenuButton(
                  onEdit: () =>
                      context.push('/home/houses/${widget.houseId}/edit'),
                  onRecordReadings: () =>
                      context.push('/home/houses/${widget.houseId}/readings'),
                  onDelete: () => _confirmDeleteHouse(context),
                ),
              );
            },
            loading: () => TopBar(title: '', onBack: () => context.pop()),
            error: (e, st) => TopBar(
                title: AppStrings.t('common.error'),
                onBack: () => context.pop()),
          ),
          Expanded(
            child: houseAsync.when(
              data: (house) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  AppSegmentedControl(
                      labels: [
                        AppStrings.t('roomList.tabHouseDetail'),
                        AppStrings.t('roomList.tabRooms'),
                      ],
                      selectedIndex: _tab,
                      onChanged: (i) => setState(() => _tab = i)),
                  const SizedBox(height: 8),
                  if (_tab == 0)
                    ..._buildHouseDetail(
                        house, roomsAsync.valueOrNull ?? const [])
                  else
                    ..._buildRooms(roomsAsync),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                  child: Text(
                      AppStrings.t('roomList.loadError', {'error': '$e'}))),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteHouse(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.t('roomList.deleteHouseTitle'),
      description: AppStrings.t('roomList.deleteHouseDescription'),
      confirmLabel: AppStrings.t('common.delete'),
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(houseRepositoryProvider).delete(widget.houseId);
      ref.invalidate(housesProvider);
      // Xoá Nhà cũng xoá cascade mọi Phòng của nó — nếu không làm mới
      // provider này, thẻ "Total rooms"/"Empty rooms" ở H-01 vẫn cộng dồn số
      // phòng đã mất cho tới khi mở lại app (bug tự phát hiện lúc test tay).
      ref.invalidate(roomStatusesByHouseProvider);
      if (context.mounted) context.go('/home');
    } on PostgrestException catch (e) {
      if (!context.mounted) return;
      final blocked = e.code == '23503'; // foreign_key_violation
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(blocked
            ? AppStrings.t('roomList.deleteBlockedSnackbar')
            : AppStrings.t('roomList.deleteFailedSnackbar')),
      ));
    }
  }

  List<Widget> _buildHouseDetail(House house, List<Room> rooms) {
    final occupied = rooms.where((r) => r.status == RoomStatus.occupied).length;
    // Thiếu tên ngân hàng ở đây là bug thật (phát hiện lúc test lại toàn bộ
    // luồng P-0x lần cuối 11/09/2026) — P-03 đã lưu/hiển thị đúng `bankBin`
    // từ lâu, nhưng field "Payout bank account" ở H-03 chưa bao giờ ghép
    // tên ngân hàng vào, chỉ ghép Account name/number. Khớp đúng cách ghép
    // đã dùng ở `payout_bank_account_screen.dart`.
    final bankAccount = [
      VnBank.byBin(house.bankBin)?.name,
      house.bankAccountName,
      house.bankAccountNumber
    ].where((e) => e != null && e.isNotEmpty).join(' · ');
    return [
      _HousePhoto(house: house),
      const SizedBox(height: 8),
      Text(house.name,
          style: GoogleFonts.inter(
              fontSize: 19, fontWeight: FontWeight.w700, color: Colors.black)),
      Text(house.address,
          style: GoogleFonts.inter(
              fontSize: 13, height: 18 / 13, color: Colors.black)),
      SectionLabel(AppStrings.t('roomList.sectionHouseInfo')),
      if (house.description != null)
        DetailRow(
            label: AppStrings.t('roomList.description'),
            value: house.description!),
      DetailRow(
          label: AppStrings.t('roomList.rooms'),
          value: AppStrings.t('roomList.roomsSummary',
              {'total': '${rooms.length}', 'occupied': '$occupied'}),
          showDivider: false),
      SectionLabel(AppStrings.t('roomList.sectionOwner')),
      DetailRow(
          label: AppStrings.t('roomList.ownerName'),
          value: house.ownerFullName),
      if (house.ownerPhone != null)
        DetailRow(
            label: AppStrings.t('roomList.phoneNumber'),
            value: house.ownerPhone!),
      if (house.ownerIdNumber != null)
        DetailRow(
            label: AppStrings.t('roomList.ownerIdNumber'),
            value: house.ownerIdNumber!),
      if (house.ownerTaxCode != null)
        DetailRow(
            label: AppStrings.t('roomList.ownerTaxCode'),
            value: house.ownerTaxCode!),
      if (bankAccount.isNotEmpty)
        DetailRow(
            label: AppStrings.t('roomList.payoutBankAccount'),
            value: bankAccount),
      DetailRow(
          label: AppStrings.t('roomList.ownerEmail'),
          value: house.ownerEmail ?? '—'),
      DetailRow(
        label: AppStrings.t('roomList.manager'),
        value: ref.watch(houseManagersProvider(house.id)).when(
              data: (names) {
                if (names.isNotEmpty) return names.join(', ');
                // Chưa gán Manager nào → chính Owner là người quản lý mặc
                // định (không tạo thêm dòng DB, xem HouseRepository.getOwnerDisplayName).
                return ref.watch(houseOwnerNameProvider(house.id)).maybeWhen(
                      data: (name) => name ?? '—',
                      orElse: () => '…',
                    );
              },
              loading: () => '…',
              error: (e, st) => '—',
            ),
        showDivider: false,
      ),
      SectionLabel(AppStrings.t('roomList.sectionPricing')),
      DetailRow(
          label: AppStrings.t('roomList.electricityPrice'),
          value: house.defaultElectricityPrice == null
              ? '—'
              : formatNumber(house.defaultElectricityPrice!)),
      DetailRow(
          label: AppStrings.t('roomList.waterPrice'),
          value: house.defaultWaterPrice == null
              ? '—'
              : formatNumber(house.defaultWaterPrice!)),
      DetailRow(
        label: AppStrings.t('roomList.recurringFees'),
        value: house.recurringFees.isEmpty
            ? '—'
            : house.recurringFees
                .map((f) => '${f.name} ${formatNumber(f.amount)}')
                .join('\n'),
        showDivider: false,
      ),
    ];
  }

  List<Widget> _buildRooms(AsyncValue<List<Room>> roomsAsync) {
    return roomsAsync.when(
      data: (rooms) {
        final filtered = switch (_filter) {
          1 => rooms.where((r) => r.status == RoomStatus.empty),
          2 => rooms.where((r) => r.status == RoomStatus.occupied),
          3 => rooms.where((r) => r.status == RoomStatus.underRepair),
          _ => rooms,
        };
        final emptyCount =
            rooms.where((r) => r.status == RoomStatus.empty).length;
        final occupiedCount =
            rooms.where((r) => r.status == RoomStatus.occupied).length;
        final underRepairCount =
            rooms.where((r) => r.status == RoomStatus.underRepair).length;
        return [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AppChip(
                    label: AppStrings.t(
                        'roomList.filterAll', {'count': '${rooms.length}'}),
                    selected: _filter == 0,
                    onTap: () => setState(() => _filter = 0)),
                const SizedBox(width: 6),
                AppChip(
                    label: AppStrings.t(
                        'roomList.filterEmpty', {'count': '$emptyCount'}),
                    selected: _filter == 1,
                    onTap: () => setState(() => _filter = 1)),
                const SizedBox(width: 6),
                AppChip(
                    label: AppStrings.t(
                        'roomList.filterOccupied', {'count': '$occupiedCount'}),
                    selected: _filter == 2,
                    onTap: () => setState(() => _filter = 2)),
                const SizedBox(width: 6),
                AppChip(
                    label: AppStrings.t('roomList.filterUnderRepair',
                        {'count': '$underRepairCount'}),
                    selected: _filter == 3,
                    onTap: () => setState(() => _filter = 3)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (rooms.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(AppStrings.t('roomList.noRoomsYet'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          for (final room in filtered) ...[
            ListCard(
              thumbColor: switch (room.status) {
                RoomStatus.occupied => AppColors.primary,
                RoomStatus.empty => AppColors.secondaryLight,
                RoomStatus.underRepair => AppColors.accentCoral,
              },
              icon: Symbols.bed_rounded,
              title: room.roomNo,
              trailing: StatusPill(
                text: roomStatusLabel(room.status),
                style: switch (room.status) {
                  RoomStatus.occupied => StatusBadgeStyle.occupied,
                  RoomStatus.empty => StatusBadgeStyle.empty,
                  RoomStatus.underRepair => StatusBadgeStyle.underRepair,
                },
              ),
              body: AppStrings.t('roomList.roomAreaRent', {
                'area': formatNumber(room.areaSqm),
                'rentLine': AppStrings.t('roomList.rentReferenceValue', {
                  'rent': room.baseRent != null
                      ? formatNumber(room.baseRent!)
                      : '—',
                }),
              }),
              onTap: () => context
                  .push('/home/houses/${widget.houseId}/rooms/${room.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ];
      },
      loading: () => [const Center(child: CircularProgressIndicator())],
      error: (e, st) => [
        Text(AppStrings.t('roomList.loadRoomsError', {'error': '$e'}))
      ],
    );
  }
}

class _HousePhoto extends ConsumerWidget {
  final House house;
  const _HousePhoto({required this.house});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decoration = BoxDecoration(
      color: AppColors.bgMuted,
      border: Border.all(color: AppColors.neutral200),
      borderRadius: BorderRadius.circular(AppRadii.card),
    );
    if (house.photos.isEmpty) {
      return Container(
        height: 160,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: decoration,
        child: const Icon(Symbols.image_rounded,
            color: AppColors.neutral200, size: 36),
      );
    }
    return FutureBuilder<String>(
      future:
          ref.read(houseRepositoryProvider).signedPhotoUrl(house.photos.first),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
              height: 160, width: double.infinity, decoration: decoration);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Image.network(snapshot.data!,
              height: 160, width: double.infinity, fit: BoxFit.cover),
        );
      },
    );
  }
}

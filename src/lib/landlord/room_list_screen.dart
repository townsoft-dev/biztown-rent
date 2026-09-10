import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/house.dart';
import '../data/models/room.dart';
import '../shared/app_chip.dart';
import '../shared/app_fab.dart';
import '../shared/confirm_dialog.dart';
import '../shared/detail_row.dart';
import '../shared/list_card.dart';
import '../shared/section_label.dart';
import '../shared/segmented_control.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

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
                subtitle:
                    '${house.address} · $occupied/${rooms.length} rooms occupied',
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
            error: (e, st) =>
                TopBar(title: 'Error', onBack: () => context.pop()),
          ),
          Expanded(
            child: houseAsync.when(
              data: (house) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  AppSegmentedControl(
                      labels: const ['House detail', 'Rooms'],
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
              error: (e, st) =>
                  Center(child: Text('Could not load this house.\n$e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteHouse(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete house?',
      description:
          'Are you sure you want to delete this house? This action cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(houseRepositoryProvider).delete(widget.houseId);
      ref.invalidate(housesProvider);
      if (context.mounted) context.go('/home');
    } on PostgrestException catch (e) {
      if (!context.mounted) return;
      final blocked = e.code == '23503'; // foreign_key_violation
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(blocked
            ? "Can't delete: this house still has rooms with contract history."
            : 'Could not delete this house. Please try again.'),
      ));
    }
  }

  List<Widget> _buildHouseDetail(House house, List<Room> rooms) {
    final occupied = rooms.where((r) => r.status == RoomStatus.occupied).length;
    final bankAccount = [house.bankAccountName, house.bankAccountNumber]
        .where((e) => e != null && e.isNotEmpty)
        .join(' · ');
    return [
      _HousePhoto(house: house),
      const SizedBox(height: 8),
      Text(house.name,
          style: GoogleFonts.inter(
              fontSize: 19, fontWeight: FontWeight.w700, color: Colors.black)),
      Text(house.address,
          style: GoogleFonts.inter(
              fontSize: 13, height: 18 / 13, color: Colors.black)),
      const SectionLabel('House info'),
      DetailRow(label: 'Type', value: house.houseType),
      if (house.description != null)
        DetailRow(label: 'Description', value: house.description!),
      DetailRow(
          label: 'Rooms',
          value: '${rooms.length} rooms  ·  $occupied/${rooms.length} occupied',
          showDivider: false),
      const SectionLabel('Owner'),
      DetailRow(label: 'Owner Name', value: house.ownerFullName),
      if (house.ownerPhone != null)
        DetailRow(label: 'Phone number', value: house.ownerPhone!),
      if (house.ownerIdNumber != null)
        DetailRow(label: 'Owner ID number', value: house.ownerIdNumber!),
      if (house.ownerTaxCode != null)
        DetailRow(label: 'Owner tax code', value: house.ownerTaxCode!),
      if (bankAccount.isNotEmpty)
        DetailRow(label: 'Payout bank account', value: bankAccount),
      DetailRow(
          label: 'Owner email',
          value: house.ownerEmail ?? '—',
          showDivider: false),
      const SectionLabel('Pricing & fees defaults'),
      DetailRow(
          label: 'Electricity /kWh',
          value: house.defaultElectricityPrice?.toString() ?? '—'),
      DetailRow(
          label: 'Water /m³',
          value: house.defaultWaterPrice?.toString() ?? '—'),
      DetailRow(
        label: 'Recurring fees',
        value: house.recurringFees.isEmpty
            ? '—'
            : house.recurringFees
                .map((f) => '${f.name} ${f.amount}')
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
                    label: 'All (${rooms.length})',
                    selected: _filter == 0,
                    onTap: () => setState(() => _filter = 0)),
                const SizedBox(width: 6),
                AppChip(
                    label: 'Empty ($emptyCount)',
                    selected: _filter == 1,
                    onTap: () => setState(() => _filter = 1)),
                const SizedBox(width: 6),
                AppChip(
                    label: 'Occupied ($occupiedCount)',
                    selected: _filter == 2,
                    onTap: () => setState(() => _filter = 2)),
                const SizedBox(width: 6),
                AppChip(
                    label: 'Under repair ($underRepairCount)',
                    selected: _filter == 3,
                    onTap: () => setState(() => _filter = 3)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No rooms yet. Tap + to add the first room.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          for (final room in filtered) ...[
            ListCard(
              thumbColor: switch (room.status) {
                RoomStatus.occupied => AppColors.primary,
                RoomStatus.empty => AppColors.secondaryLight,
                RoomStatus.underRepair => AppColors.accentCoral,
              },
              icon: Icons.bed_rounded,
              title: room.roomNo,
              trailing: StatusPill(
                text: room.status.label,
                style: switch (room.status) {
                  RoomStatus.occupied => StatusBadgeStyle.occupied,
                  RoomStatus.empty => StatusBadgeStyle.empty,
                  RoomStatus.underRepair => StatusBadgeStyle.underRepair,
                },
              ),
              body:
                  '${room.areaSqm} m² · ${room.baseRent ?? '—'} VND/month (reference)',
              onTap: () => context
                  .push('/home/houses/${widget.houseId}/rooms/${room.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ];
      },
      loading: () => [const Center(child: CircularProgressIndicator())],
      error: (e, st) => [Text('Could not load rooms.\n$e')],
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
        child: const Icon(Icons.image_rounded,
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

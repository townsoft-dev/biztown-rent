import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
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
/// control. Dữ liệu mẫu khớp Figma (house "Nha tro Binh An"), chưa nối
/// `tb_house`/`tb_room` thật.
class RoomListScreen extends StatefulWidget {
  final String houseId;

  const RoomListScreen({super.key, required this.houseId});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  int _tab = 0; // 0 = House detail, 1 = Rooms
  int _filter = 0; // 0=All 1=Empty 2=Occupied 3=Under repair

  static const _rooms = [
    _RoomData(
        number: 'P.101',
        area: '22 m²',
        rent: '3,200,000 VND/month (reference)',
        badge: StatusBadgeStyle.occupied,
        badgeText: 'Occupied',
        thumbColor: AppColors.primary),
    _RoomData(
        number: 'P.102',
        area: '20 m²',
        rent: '3,000,000 VND/month (reference)',
        badge: StatusBadgeStyle.empty,
        badgeText: 'Empty',
        thumbColor: AppColors.secondaryLight),
    _RoomData(
        number: 'P.103',
        area: '18 m²',
        rent: '2,800,000 VND/month (reference)',
        badge: StatusBadgeStyle.underRepair,
        badgeText: 'Under repair',
        thumbColor: AppColors.accentCoral),
    _RoomData(
        number: 'P.104',
        area: '22 m²',
        rent: '3,200,000 VND/month (reference)',
        badge: StatusBadgeStyle.occupied,
        badgeText: 'Occupied',
        thumbColor: AppColors.primary),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      floatingActionButton: _tab == 1
          ? AppFab(
              onPressed: () =>
                  context.push('/home/houses/${widget.houseId}/rooms/new'))
          : null,
      body: Column(
        children: [
          TopBar(
            title: 'Nha tro Binh An',
            subtitle: '12 Le Van Sy, D.3 · 18/24 rooms occupied',
            onBack: () => context.pop(),
            trailing: TopBarActionMenuButton(
              onEdit: () => context.push('/home/houses/${widget.houseId}/edit'),
              onDelete: () => _confirmDeleteHouse(context),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                AppSegmentedControl(
                    labels: const ['House detail', 'Rooms'],
                    selectedIndex: _tab,
                    onChanged: (i) => setState(() => _tab = i)),
                const SizedBox(height: 8),
                if (_tab == 0) ..._buildHouseDetail() else ..._buildRooms(),
              ],
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
    // TODO: nối xoá tb_house thật (kèm rà buộc nghiệp vụ — chặn nếu còn phòng/
    // hợp đồng đang hoạt động) khi có backend House/Room. Hiện chỉ quay lại H-01.
    context.go('/home');
  }

  List<Widget> _buildHouseDetail() {
    return [
      Container(
        height: 160,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgMuted,
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: const Icon(Icons.image_rounded,
            color: AppColors.neutral200, size: 36),
      ),
      const SizedBox(height: 8),
      Text('Nha tro Binh An',
          style: GoogleFonts.inter(
              fontSize: 19, fontWeight: FontWeight.w700, color: Colors.black)),
      Text('12 Le Van Sy, District 3, HCMC',
          style: GoogleFonts.inter(
              fontSize: 13, height: 18 / 13, color: Colors.black)),
      const SectionLabel('House info'),
      const DetailRow(label: 'Type', value: 'Dãy trọ (Boarding house)'),
      const DetailRow(
          label: 'Description',
          value: '24 rooms, 3 floors, gated,\n24/7 security.'),
      const DetailRow(
          label: 'Rooms',
          value: '8 rooms  ·  6/8 occupied',
          showDivider: false),
      const SectionLabel('Owner'),
      const DetailRow(label: 'Owner Name', value: 'Nguyễn Thúy Hường'),
      const DetailRow(label: 'Phone number', value: '0909 888 777'),
      const DetailRow(label: 'Owner ID number', value: '079xxxxxxxxx'),
      const DetailRow(label: 'Owner tax code', value: '0312xxxxxx'),
      const DetailRow(
          label: 'Payout bank account', value: 'Vietcombank · 0071000xxxxxx'),
      const DetailRow(
          label: 'Owner email',
          value: 'huong.nguyen@example.com',
          showDivider: false),
      const SectionLabel('Pricing & fees defaults'),
      const DetailRow(label: 'Electricity /kWh', value: '3,800'),
      const DetailRow(label: 'Water /m³', value: '35,000'),
      const DetailRow(
          label: 'Recurring fees',
          value: 'Internet 100,000\nWaste 30,000',
          showDivider: false),
    ];
  }

  List<Widget> _buildRooms() {
    final filtered = switch (_filter) {
      1 => _rooms.where((r) => r.badgeText == 'Empty'),
      2 => _rooms.where((r) => r.badgeText == 'Occupied'),
      3 => _rooms.where((r) => r.badgeText == 'Under repair'),
      _ => _rooms,
    };
    return [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AppChip(
                label: 'All (24)',
                selected: _filter == 0,
                onTap: () => setState(() => _filter = 0)),
            const SizedBox(width: 6),
            AppChip(
                label: 'Empty (6)',
                selected: _filter == 1,
                onTap: () => setState(() => _filter = 1)),
            const SizedBox(width: 6),
            AppChip(
                label: 'Occupied (18)',
                selected: _filter == 2,
                onTap: () => setState(() => _filter = 2)),
            const SizedBox(width: 6),
            AppChip(
                label: 'Under repair (0)',
                selected: _filter == 3,
                onTap: () => setState(() => _filter = 3)),
          ],
        ),
      ),
      const SizedBox(height: 8),
      for (final room in filtered) ...[
        ListCard(
          thumbColor: room.thumbColor,
          icon: Icons.bed_rounded,
          title: room.number,
          trailing: StatusPill(text: room.badgeText, style: room.badge),
          body: '${room.area} · ${room.rent}',
          onTap: () => context
              .push('/home/houses/${widget.houseId}/rooms/${room.number}'),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }
}

class _RoomData {
  final String number;
  final String area;
  final String rent;
  final StatusBadgeStyle badge;
  final String badgeText;
  final Color thumbColor;

  const _RoomData(
      {required this.number,
      required this.area,
      required this.rent,
      required this.badge,
      required this.badgeText,
      required this.thumbColor});
}

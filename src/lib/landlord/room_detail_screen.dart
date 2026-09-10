import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../shared/app_button.dart';
import '../shared/confirm_dialog.dart';
import '../shared/detail_row.dart';
import '../shared/list_card.dart';
import '../shared/mini_profile_card.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

/// H-04 — Room Detail (View) (node 220:2714, lấy qua Figma MCP 10/09/2026).
/// Dữ liệu mẫu khớp Figma (phòng P.101 của "Nha tro Binh An"), chưa nối
/// `tb_room` thật.
class RoomDetailScreen extends StatelessWidget {
  final String houseId;
  final String roomId;

  const RoomDetailScreen(
      {super.key, required this.houseId, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(
              title: roomId,
              subtitle: 'Nha tro Binh An',
              onBack: () => context.pop(),
              trailing: TopBarActionMenuButton(
                onEdit: () =>
                    context.push('/home/houses/$houseId/rooms/$roomId/edit'),
                onDelete: () => _confirmDeleteRoom(context),
              )),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: Text(roomId,
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary))),
                    const StatusPill(
                        text: 'Occupied', style: StatusBadgeStyle.occupied),
                  ],
                ),
                const SizedBox(height: 10),
                const DetailBlock(children: [
                  DetailRow(label: 'Area (optional)', value: '22 m²'),
                  DetailRow(
                      label: 'Reference rent', value: '3,200,000 / month'),
                  DetailRow(
                      label: 'Amenities', value: 'A/C, water heater, balcony'),
                  DetailRow(
                      label: 'Recurring fees',
                      value: 'Internet 100,000\nWaste 30,000'),
                  DetailRow(
                      label: 'Note',
                      value: 'Corner room, quiet side',
                      showDivider: false),
                ]),
                const SizedBox(height: 10),
                AppButton(
                  label: 'View reading history',
                  style: AppButtonStyle.ghost,
                  onPressed: () => context
                      .push('/home/houses/$houseId/readings/P.101-electricity'),
                ),
                const SectionLabel('Reading history  ·  this room'),
                ListCard(
                  thumbColor: AppColors.accentOrange,
                  icon: Icons.bolt_rounded,
                  title: '01/09/2026  ·  Electricity',
                  body: '1,120 → 1,216  ·  96 kWh  ·  Periodic',
                  onTap: () => context
                      .push('/home/houses/$houseId/readings/P.101-electricity'),
                ),
                const SizedBox(height: 8),
                const ListCard(
                  thumbColor: AppColors.info,
                  icon: Icons.water_drop_rounded,
                  title: '01/09/2026  ·  Water',
                  body: '54 → 59  ·  5 m³  ·  Periodic',
                ),
                const SectionLabel('Current contract'),
                // TODO: → T-03/T-05 khi seri màn Tenant & Contract có (chưa build).
                const MiniProfileCard(
                  initials: 'NA',
                  name: 'Nguyen Thi Anh',
                  subtitle: '0909 123 456 · 15/03/2026 → 15/03/2027',
                ),
                const SizedBox(height: 10),
                AppButton(label: 'View contract', onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteRoom(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete room?',
      description:
          'Are you sure you want to delete this room? This action cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    // TODO: nối xoá tb_room thật (chặn nếu phòng đang Occupied/có hợp đồng) khi
    // có backend House/Room. Hiện chỉ quay lại H-03.
    context.pop();
  }
}

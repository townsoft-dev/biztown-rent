import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/room.dart';
import '../shared/app_button.dart';
import '../shared/confirm_dialog.dart';
import '../shared/detail_row.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

/// H-04 — Room Detail (View) (node 220:2714, lấy qua Figma MCP 10/09/2026),
/// nối CRUD thật vào `tb_room` (10/09/2026, xem changelog/2026-09-10.md).
/// Lịch sử chỉ số/Hợp đồng hiện tại chưa nối (chờ seri H-06 thật/T-0x).
class RoomDetailScreen extends ConsumerWidget {
  final String houseId;
  final String roomId;

  const RoomDetailScreen(
      {super.key, required this.houseId, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomProvider(roomId));
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          roomAsync.when(
            data: (room) => TopBar(
              title: room.roomNo,
              subtitle: ref.watch(houseProvider(houseId)).valueOrNull?.name,
              onBack: () => context.pop(),
              trailing: TopBarActionMenuButton(
                onEdit: () =>
                    context.push('/home/houses/$houseId/rooms/$roomId/edit'),
                onDelete: () => _confirmDeleteRoom(context, ref),
              ),
            ),
            loading: () => TopBar(title: '', onBack: () => context.pop()),
            error: (e, st) =>
                TopBar(title: 'Error', onBack: () => context.pop()),
          ),
          Expanded(
            child: roomAsync.when(
              data: (room) => _buildBody(context, ref, room),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  Center(child: Text('Could not load this room.\n$e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, Room room) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        _RoomPhoto(room: room),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(room.roomNo,
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
            StatusPill(
              text: room.status.label,
              style: switch (room.status) {
                RoomStatus.occupied => StatusBadgeStyle.occupied,
                RoomStatus.empty => StatusBadgeStyle.empty,
                RoomStatus.underRepair => StatusBadgeStyle.underRepair,
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        DetailBlock(children: [
          DetailRow(label: 'Area (optional)', value: '${room.areaSqm} m²'),
          DetailRow(
              label: 'Reference rent',
              value: room.baseRent != null ? '${room.baseRent} / month' : '—'),
          DetailRow(
              label: 'Amenities',
              value: room.amenities.isEmpty ? '—' : room.amenities.join(', ')),
          DetailRow(
            label: 'Recurring fees',
            value: room.recurringFees.isEmpty
                ? '—'
                : room.recurringFees
                    .map((f) => '${f.name} ${f.amount}')
                    .join('\n'),
          ),
          DetailRow(label: 'Note', value: room.note ?? '—', showDivider: false),
        ]),
        const SizedBox(height: 10),
        // TODO: → H-06 thật khi có điểm vào rõ ràng (xem docs/CURRENT_STATUS.md).
        const AppButton(
            label: 'View reading history',
            style: AppButtonStyle.ghost,
            onPressed: null),
        const SectionLabel('Reading history  ·  this room'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No reading recorded yet.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        const SectionLabel('Current contract'),
        // TODO: → T-03/T-05 khi seri màn Tenant & Contract có (chưa build).
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No active contract.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteRoom(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete room?',
      description:
          'Are you sure you want to delete this room? This action cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(roomRepositoryProvider).delete(roomId);
      ref.invalidate(roomsProvider(houseId));
      if (context.mounted) context.pop();
    } on PostgrestException catch (e) {
      if (!context.mounted) return;
      final blocked = e.code == '23503'; // foreign_key_violation
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(blocked
            ? "Can't delete: this room still has contract history."
            : 'Could not delete this room. Please try again.'),
      ));
    }
  }
}

class _RoomPhoto extends ConsumerWidget {
  final Room room;
  const _RoomPhoto({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decoration = BoxDecoration(
      color: AppColors.bgMuted,
      border: Border.all(color: AppColors.neutral200),
      borderRadius: BorderRadius.circular(AppRadii.card),
    );
    if (room.photos.isEmpty) {
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
          ref.read(roomRepositoryProvider).signedPhotoUrl(room.photos.first),
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

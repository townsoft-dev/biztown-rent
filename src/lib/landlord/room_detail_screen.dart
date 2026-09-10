import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/reading.dart';
import '../data/models/room.dart';
import '../shared/app_button.dart';
import '../shared/confirm_dialog.dart';
import '../shared/detail_row.dart';
import '../shared/list_card.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

/// H-04 — Room Detail (View) (node 220:2714, lấy lại qua Figma MCP 10/09/2026
/// sau khi Dream cập nhật: ảnh dạng slider nhiều ảnh, lịch sử chỉ số hiện 2
/// `ListCard` thật thay vì text tóm tắt), nối CRUD thật vào `tb_room` +
/// lịch sử chỉ số (H-06) — "View reading history" mở bottom sheet chọn
/// Electricity/Water (1 phòng có 2 chuỗi chỉ số độc lập, xem BR-READ-01/02).
/// Hợp đồng hiện tại chưa nối (chờ seri T-0x, chưa build).
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
        AppButton(
            label: 'View reading history',
            style: AppButtonStyle.ghost,
            onPressed: () => _chooseUtilityAndOpenHistory(context, room.id)),
        const SectionLabel('Reading history  ·  this room'),
        _ReadingSummaryCard(
            roomId: room.id,
            utilityType: UtilityType.electricity,
            onTap: () => context.push(
                '/home/houses/$houseId/readings/${room.id}/${UtilityType.electricity.pathSegment}')),
        const SizedBox(height: 10),
        _ReadingSummaryCard(
            roomId: room.id,
            utilityType: UtilityType.water,
            onTap: () => context.push(
                '/home/houses/$houseId/readings/${room.id}/${UtilityType.water.pathSegment}')),
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

  Future<void> _chooseUtilityAndOpenHistory(
      BuildContext context, String roomId) async {
    final type = await showModalBottomSheet<UtilityType>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.bolt_rounded, color: AppColors.accentOrange),
              title: const Text('Electricity'),
              onTap: () => Navigator.of(context).pop(UtilityType.electricity),
            ),
            ListTile(
              leading:
                  const Icon(Icons.water_drop_rounded, color: AppColors.info),
              title: const Text('Water'),
              onTap: () => Navigator.of(context).pop(UtilityType.water),
            ),
          ],
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    context.push('/home/houses/$houseId/readings/$roomId/${type.pathSegment}');
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

/// Ảnh phòng dạng slider (node `410:2908`, cập nhật Figma sau khi thấy 1
/// phòng có thể có nhiều ảnh) — 2 mũi tên trái/phải luôn hiện (kể cả lúc
/// chưa có ảnh nào, đúng Figma), chỉ thật sự chuyển ảnh khi có ≥2 ảnh.
class _RoomPhoto extends ConsumerStatefulWidget {
  final Room room;
  const _RoomPhoto({required this.room});

  @override
  ConsumerState<_RoomPhoto> createState() => _RoomPhotoState();
}

class _RoomPhotoState extends ConsumerState<_RoomPhoto> {
  int _index = 0;

  void _step(int delta) {
    final count = widget.room.photos.length;
    if (count < 2) return;
    setState(() => _index = (_index + delta) % count);
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.room.photos;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bgMuted,
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            photos.isEmpty
                ? const Center(
                    child: Icon(Icons.image_rounded,
                        color: AppColors.neutral200, size: 36),
                  )
                : FutureBuilder<String>(
                    key: ValueKey(photos[_index]),
                    future: ref
                        .read(roomRepositoryProvider)
                        .signedPhotoUrl(photos[_index]),
                    builder: (context, snapshot) {
                      // Hiện lỗi thật (thay vì im lặng bỏ trống) nếu không
                      // lấy được signed URL hoặc ảnh tải lỗi — dễ chẩn đoán
                      // hơn khi có sự cố mạng thật ngoài đời.
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('${snapshot.error}',
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.error)));
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)));
                      }
                      return Image.network(snapshot.data!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                              child: Text('$error',
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.error))));
                    },
                  ),
            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: _SliderArrow(
                    icon: Icons.chevron_left_rounded,
                    overPhoto: photos.isNotEmpty,
                    onTap: photos.length > 1 ? () => _step(-1) : null),
              ),
            ),
            Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: _SliderArrow(
                    icon: Icons.chevron_right_rounded,
                    overPhoto: photos.isNotEmpty,
                    onTap: photos.length > 1 ? () => _step(1) : null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút mũi tên đè lên ảnh — luôn hiện (kể cả chưa có ảnh, đúng Figma mock
/// placeholder gốc: icon xám `text-tertiary`, không nền). Khi đã có ảnh thật
/// thì thêm nền tròn mờ đen để chữ/icon luôn đọc được dù ảnh sáng màu (Figma
/// không mock sẵn trạng thái này vì chỉ là wireframe không có ảnh thật — suy
/// ra hợp lý theo pattern overlay đã dùng ở `photo_picker_row.dart`).
/// `onTap` null (≤1 ảnh) thì chỉ mang tính trang trí, không bắt sự kiện.
class _SliderArrow extends StatelessWidget {
  final IconData icon;
  final bool overPhoto;
  final VoidCallback? onTap;
  const _SliderArrow(
      {required this.icon, required this.overPhoto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: overPhoto ? Colors.black.withValues(alpha: 0.24) : null,
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              color: overPhoto ? Colors.white : AppColors.textTertiary,
              size: 24),
        ),
      ),
    );
  }
}

/// 1 thẻ tóm tắt chỉ số gần nhất của 1 tiện ích (điện/nước) — đúng "List
/// card" trên Figma (node `220:2730`/`220:2731`, cập nhật thay cho dòng text
/// tóm tắt trước đây), tap mở lịch sử đầy đủ (H-06 Detail).
class _ReadingSummaryCard extends ConsumerWidget {
  final String roomId;
  final UtilityType utilityType;
  final VoidCallback onTap;

  const _ReadingSummaryCard(
      {required this.roomId, required this.utilityType, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(
        readingHistoryProvider((roomId: roomId, utilityType: utilityType)));
    final thumbColor = utilityType == UtilityType.electricity
        ? AppColors.accentOrange
        : AppColors.info;
    final icon = utilityType == UtilityType.electricity
        ? Icons.bolt_rounded
        : Icons.water_drop_rounded;

    return historyAsync.when(
      loading: () => ListCard(
          thumbColor: thumbColor,
          icon: icon,
          title: utilityType.label,
          body: 'Loading…'),
      error: (e, st) => ListCard(
          thumbColor: thumbColor,
          icon: icon,
          title: utilityType.label,
          body: 'Could not load.'),
      data: (history) {
        if (history.isEmpty) {
          return ListCard(
            thumbColor: thumbColor,
            icon: icon,
            title: '${utilityType.label}  ·  no reading yet',
            body: 'Tap to record the first reading.',
            onTap: onTap,
          );
        }
        final latest = history.first;
        return ListCard(
          thumbColor: thumbColor,
          icon: icon,
          title:
              '${DateFormat('dd/MM/yyyy').format(latest.readingDate)}  ·  ${utilityType.label}',
          body:
              '${latest.previousReading == null ? '—' : formatReadingValue(latest.previousReading!)} → ${formatReadingValue(latest.currentReading)}  ·  ${latest.usageAmount == null ? '—' : formatReadingValue(latest.usageAmount!)} ${utilityType.unit}  ·  ${latest.readingType.label}',
          onTap: onTap,
        );
      },
    );
  }
}

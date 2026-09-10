import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/reading.dart';
import '../shared/app_banner.dart';
import '../shared/app_button.dart';
import '../shared/detail_row.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

/// H-06 — Record Monthly Reading (PERIODIC) · Detail/Edit (node 220:2905,
/// Figma). Lịch sử đầy đủ 1 phòng + 1 tiện ích, sửa tại chỗ bản ghi mới nhất
/// khi chưa khoá (BR-METER-13/14, BR-READ-04).
class ReadingDetailScreen extends ConsumerStatefulWidget {
  final String houseId;
  final String roomId;
  final UtilityType utilityType;

  const ReadingDetailScreen(
      {super.key,
      required this.houseId,
      required this.roomId,
      required this.utilityType});

  @override
  ConsumerState<ReadingDetailScreen> createState() =>
      _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends ConsumerState<ReadingDetailScreen> {
  bool _editing = false;
  bool _saving = false;
  String? _error;
  final _currentController = TextEditingController();
  final _noteController = TextEditingController();

  RoomUtilityKey get _key =>
      (roomId: widget.roomId, utilityType: widget.utilityType);

  @override
  void dispose() {
    _currentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _startEdit(Reading latest) {
    _currentController.text = latest.currentReading.toString();
    _noteController.clear();
    setState(() {
      _editing = true;
      _error = null;
    });
  }

  Future<void> _saveEdit(Reading latest) async {
    final value = num.tryParse(_currentController.text.trim());
    if (value == null) {
      setState(() => _error = 'Invalid number');
      return;
    }
    if (latest.previousReading != null && value < latest.previousReading!) {
      setState(() => _error =
          'Current reading must be ≥ previous (${latest.previousReading}).');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(readingRepositoryProvider).updateCurrentReading(
            id: latest.id,
            type: widget.utilityType,
            currentReading: value,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      ref.invalidate(readingHistoryProvider(_key));
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      setState(() => _error = 'Could not save — try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final houseAsync = ref.watch(houseProvider(widget.houseId));
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final historyAsync = ref.watch(readingHistoryProvider(_key));

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(
            title: 'Reading detail',
            subtitle: roomAsync.maybeWhen(
                data: (room) =>
                    '${room.roomNo}  ·  ${widget.utilityType.label}  ·  periodic reading',
                orElse: () => widget.utilityType.label),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Failed to load: $e')),
              data: (history) {
                if (history.isEmpty) {
                  return const Center(
                      child: Text('No readings recorded yet.',
                          style: TextStyle(color: AppColors.textSecondary)));
                }
                final latest = history.first;
                return FutureBuilder<bool>(
                  future: ref.read(readingRepositoryProvider).isLocked(latest),
                  builder: (context, lockedSnapshot) {
                    final isLocked = lockedSnapshot.data ?? false;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: widget.utilityType ==
                                          UtilityType.electricity
                                      ? AppColors.accentOrange
                                      : AppColors.info,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.button)),
                              child: Icon(
                                  widget.utilityType == UtilityType.electricity
                                      ? Icons.bolt_rounded
                                      : Icons.water_drop_rounded,
                                  color: Colors.white,
                                  size: 24),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  '${DateFormat('dd/MM/yyyy').format(latest.readingDate)}  ·  ${roomAsync.maybeWhen(data: (r) => r.roomNo, orElse: () => '')}',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                            ),
                            StatusPill(
                                text: latest.readingType.label,
                                style: StatusBadgeStyle.sent),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DetailBlock(children: [
                          DetailRow(
                              label: 'Reading type',
                              value:
                                  '${latest.readingType.label}  (${latest.readingType.dbValue})'),
                          DetailRow(
                              label: 'Room',
                              value:
                                  '${roomAsync.maybeWhen(data: (r) => r.roomNo, orElse: () => '')}  —  ${houseAsync.maybeWhen(data: (h) => h.name, orElse: () => '')}'),
                          DetailRow(
                              label: 'Period',
                              value: DateFormat('MMMM yyyy')
                                  .format(latest.periodYm)),
                          DetailRow(
                              label: 'Previous → Current',
                              value:
                                  '${latest.previousReading ?? '—'} → ${latest.currentReading}   ·   ${latest.usageAmount ?? '—'} ${widget.utilityType.unit}'),
                          DetailRow(
                              label: 'Recorded by',
                              value:
                                  '${latest.recordedByPhone}  ·  ${DateFormat('dd/MM HH:mm').format(latest.createdAt)}${latest.photoUrl != null ? '  ·  photo ✓' : ''}'),
                          DetailRow(
                              label: 'Lock status',
                              value: isLocked
                                  ? 'Locked — used by an invoice'
                                  : 'Unlocked — no invoice uses it yet',
                              showDivider: false),
                        ]),
                        if (isLocked) ...[
                          const SizedBox(height: 10),
                          const AppBanner(
                            message:
                                'A reading locks as soon as any invoice other than Draft uses it. Locked readings cannot be edited; correct them with an adjustment line on the next invoice.',
                          ),
                        ],
                        SectionLabel(
                            'Reading history  ·  ${roomAsync.maybeWhen(data: (r) => r.roomNo, orElse: () => '')} · ${widget.utilityType.label}'),
                        DetailBlock(children: [
                          for (var i = 0; i < history.length; i++)
                            DetailRow(
                              label: DateFormat('dd/MM/yyyy')
                                  .format(history[i].readingDate),
                              value:
                                  '${history[i].previousReading ?? '—'} → ${history[i].currentReading} · ${history[i].usageAmount ?? '—'} ${widget.utilityType.unit} · ${history[i].readingType.label}',
                              showDivider: i != history.length - 1,
                            ),
                        ]),
                        const SizedBox(height: 10),
                        if (_editing) ...[
                          TextField(
                            controller: _currentController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Current reading',
                              errorText: _error,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _noteController,
                            decoration: const InputDecoration(
                                labelText: 'Reason for edit (optional)'),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                    label: 'Cancel',
                                    style: AppButtonStyle.ghost,
                                    onPressed: _saving
                                        ? null
                                        : () =>
                                            setState(() => _editing = false)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppButton(
                                    label: _saving ? 'Saving…' : 'Save',
                                    style: AppButtonStyle.accent,
                                    onPressed: _saving
                                        ? null
                                        : () => _saveEdit(latest)),
                              ),
                            ],
                          ),
                        ] else
                          AppButton(
                              label: 'Edit reading',
                              style: AppButtonStyle.accent,
                              onPressed:
                                  isLocked ? null : () => _startEdit(latest)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

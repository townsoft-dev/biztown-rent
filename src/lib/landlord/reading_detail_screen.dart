import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/app_strings.dart';
import '../core/enum_labels.dart';
import '../core/locale_provider.dart';
import '../core/number_format.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/reading.dart';
import '../shared/app_banner.dart';
import '../shared/app_button.dart';
import '../shared/detail_row.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    _currentController.text = formatReadingValue(latest.currentReading);
    _noteController.clear();
    setState(() {
      _editing = true;
      _error = null;
    });
  }

  Future<void> _saveEdit(Reading latest) async {
    final value = parseFormattedNumber(_currentController.text);
    if (value == null) {
      setState(() => _error = AppStrings.t('common.invalidNumber'));
      return;
    }
    if (latest.previousReading != null && value < latest.previousReading!) {
      setState(() => _error = AppStrings.t(
          'readingDetail.currentMustBeGreaterOrEqual',
          {'value': formatReadingValue(latest.previousReading!)}));
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
      // Sửa chỉ số ở đây cũng phải làm mới H-06 Entry (màn ghi hàng loạt cho
      // cả nhà) — nếu không, quay lại đó vẫn thấy giá trị cũ trong ô Current
      // dù DB đã đúng (bug tự phát hiện lúc test tay: sửa 150→200 ở đây,
      // quay lại Entry vẫn thấy 150).
      ref.invalidate(houseMeterEntriesProvider(
          (houseId: widget.houseId, periodYm: latest.periodYm)));
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      setState(() => _error = AppStrings.t('common.saveRowError'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final houseAsync = ref.watch(houseProvider(widget.houseId));
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final historyAsync = ref.watch(readingHistoryProvider(_key));

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(
            title: AppStrings.t('readingDetail.title'),
            subtitle: roomAsync.maybeWhen(
                data: (room) => AppStrings.t('readingDetail.subtitle', {
                      'room': room.roomNo,
                      'utility': utilityTypeLabel(widget.utilityType),
                    }),
                orElse: () => utilityTypeLabel(widget.utilityType)),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                  child: Text(AppStrings.t(
                      'readingDetail.loadError', {'error': '$e'}))),
              data: (history) {
                if (history.isEmpty) {
                  return Center(
                      child: Text(AppStrings.t('readingDetail.noReadingsYet'),
                          style:
                              const TextStyle(color: AppColors.textSecondary)));
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
                                      ? Symbols.bolt_rounded
                                      : Symbols.water_drop_rounded,
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
                                text: readingTypeLabel(latest.readingType),
                                style: StatusBadgeStyle.sent),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DetailBlock(children: [
                          DetailRow(
                              label: AppStrings.t('readingDetail.readingType'),
                              value:
                                  '${readingTypeLabel(latest.readingType)}  (${latest.readingType.dbValue})'),
                          DetailRow(
                              label: AppStrings.t('readingDetail.room'),
                              value:
                                  '${roomAsync.maybeWhen(data: (r) => r.roomNo, orElse: () => '')}  —  ${houseAsync.maybeWhen(data: (h) => h.name, orElse: () => '')}'),
                          DetailRow(
                              label: AppStrings.t('readingDetail.period'),
                              value: DateFormat('MMMM yyyy')
                                  .format(latest.periodYm)),
                          DetailRow(
                              label: AppStrings.t(
                                  'readingDetail.previousToCurrent'),
                              value:
                                  '${latest.previousReading == null ? '—' : formatReadingValue(latest.previousReading!)} → ${formatReadingValue(latest.currentReading)}   ·   ${latest.usageAmount == null ? '—' : formatReadingValue(latest.usageAmount!)} ${widget.utilityType.unit}'),
                          DetailRow(
                              label: AppStrings.t('readingDetail.recordedBy'),
                              value:
                                  '${latest.recordedByPhone}  ·  ${DateFormat('dd/MM HH:mm').format(latest.createdAt)}${latest.photoUrl != null ? AppStrings.t('readingDetail.photoConfirmedSuffix') : ''}'),
                          DetailRow(
                              label: AppStrings.t('readingDetail.lockStatus'),
                              value: isLocked
                                  ? AppStrings.t('readingDetail.locked')
                                  : AppStrings.t('readingDetail.unlocked'),
                              showDivider: false),
                        ]),
                        if (isLocked) ...[
                          const SizedBox(height: 10),
                          AppBanner(
                            message: AppStrings.t('readingDetail.banner'),
                          ),
                        ],
                        SectionLabel(
                            AppStrings.t('readingDetail.sectionHistory', {
                          'room': roomAsync.maybeWhen(
                              data: (r) => r.roomNo, orElse: () => ''),
                          'type': utilityTypeLabel(widget.utilityType),
                        })),
                        DetailBlock(children: [
                          for (var i = 0; i < history.length; i++)
                            DetailRow(
                              label: DateFormat('dd/MM/yyyy')
                                  .format(history[i].readingDate),
                              value:
                                  '${history[i].previousReading == null ? '—' : formatReadingValue(history[i].previousReading!)} → ${formatReadingValue(history[i].currentReading)} · ${history[i].usageAmount == null ? '—' : formatReadingValue(history[i].usageAmount!)} ${widget.utilityType.unit} · ${readingTypeLabel(history[i].readingType)}',
                              showDivider: i != history.length - 1,
                            ),
                        ]),
                        const SizedBox(height: 10),
                        if (_editing) ...[
                          TextField(
                            controller: _currentController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: const [ThousandsInputFormatter()],
                            decoration: InputDecoration(
                              labelText: AppStrings.t(
                                  'readingDetail.currentReadingFieldLabel'),
                              errorText: _error,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                                labelText: AppStrings.t(
                                    'readingDetail.reasonForEdit')),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                    label: AppStrings.t('common.cancel'),
                                    style: AppButtonStyle.ghost,
                                    onPressed: _saving
                                        ? null
                                        : () =>
                                            setState(() => _editing = false)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppButton(
                                    label: _saving
                                        ? AppStrings.t('common.saving')
                                        : AppStrings.t('common.save'),
                                    style: AppButtonStyle.accent,
                                    onPressed: _saving
                                        ? null
                                        : () => _saveEdit(latest)),
                              ),
                            ],
                          ),
                        ] else
                          AppButton(
                              label: AppStrings.t('readingDetail.editReading'),
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

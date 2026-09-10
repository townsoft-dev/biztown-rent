import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/reading.dart';
import '../data/reading_repository.dart';
import '../shared/app_banner.dart';
import '../shared/app_button.dart';
import '../shared/meter_card.dart';
import '../shared/progress_card.dart';
import '../shared/top_bar.dart';

/// H-06 — Record Monthly Reading (PERIODIC) · Entry (node 220:3077, Figma).
/// Ghi chỉ số PERIODIC thật cho mọi phòng của 1 nhà, theo BR-READ-02/03/07 —
/// mỗi phòng có 2 `MeterCard` độc lập (điện/nước, 2 bảng riêng). Chưa lọc
/// theo `electricityBillingMethod`/`waterBillingMethod = NOT_BILLED` (BR-READ-05)
/// vì đó là field snapshot trên hợp đồng, và Tenant/Contract (T-0x) chưa xây
/// nên hiện tại không phòng nào có hợp đồng để mà bỏ qua — sẽ bổ sung lọc khi
/// làm T-0x.
class ReadingEntryScreen extends ConsumerStatefulWidget {
  final String houseId;

  const ReadingEntryScreen({super.key, required this.houseId});

  @override
  ConsumerState<ReadingEntryScreen> createState() => _ReadingEntryScreenState();
}

class _ReadingEntryScreenState extends ConsumerState<ReadingEntryScreen> {
  late DateTime _period = DateTime(DateTime.now().year, DateTime.now().month);
  final _controllers = <String, TextEditingController>{};
  final _errors = <String, String>{};
  bool _saving = false;
  String? _saveError;

  // Key theo cả kỳ (period) — nếu chỉ theo room+utility, chuyển qua lại giữa
  // các kỳ sẽ vô tình dùng lại text đã gõ dở của kỳ khác (bug tự phát hiện
  // lúc test tay: gõ "100" ở kỳ A rồi chuyển sang kỳ B vẫn còn thấy "100").
  String _keyFor(String roomId, UtilityType type) =>
      '$roomId:${type.name}:${_period.year}-${_period.month}';

  TextEditingController _controllerFor(String roomId, UtilityType type,
      {num? prefill}) {
    final key = _keyFor(roomId, type);
    return _controllers.putIfAbsent(
        key, () => TextEditingController(text: prefill?.toString() ?? ''));
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  HouseReadingPeriodKey get _periodKey =>
      (houseId: widget.houseId, periodYm: _period);

  void _changePeriod(int monthDelta) {
    setState(() {
      _period = DateTime(_period.year, _period.month + monthDelta);
      _saveError = null;
    });
  }

  Future<void> _save() async {
    final entriesAsync = ref.read(houseMeterEntriesProvider(_periodKey));
    final entries = entriesAsync.value;
    if (entries == null || _saving) return;

    setState(() {
      _saving = true;
      _errors.clear();
      _saveError = null;
    });

    final repo = ref.read(readingRepositoryProvider);
    var savedAny = false;
    var hadError = false;
    final now = DateTime.now();

    for (final entry in entries) {
      if (entry.recorded) continue;
      final key = _keyFor(entry.room.id, entry.utilityType);
      final text = _controllers[key]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      final value = num.tryParse(text);
      if (value == null) {
        setState(() => _errors[key] = 'Invalid number');
        hadError = true;
        continue;
      }
      try {
        await repo.createPeriodic(
          roomId: entry.room.id,
          houseId: widget.houseId,
          type: entry.utilityType,
          periodYm: _period,
          readingDate: now,
          currentReading: value,
        );
        savedAny = true;
        ref.invalidate(readingHistoryProvider(
            (roomId: entry.room.id, utilityType: entry.utilityType)));
      } on ReadingOrderException catch (e) {
        setState(() => _errors[key] = e.message);
        hadError = true;
      } catch (e) {
        setState(() => _errors[key] = 'Could not save — try again.');
        hadError = true;
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (savedAny) {
      ref.invalidate(houseMeterEntriesProvider(_periodKey));
    }
    if (hadError) {
      setState(() => _saveError =
          'Some rooms could not be saved — check the highlighted fields.');
      return;
    }
    if (!savedAny) {
      setState(() => _saveError = 'Enter at least 1 reading before saving.');
      return;
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final houseAsync = ref.watch(houseProvider(widget.houseId));
    final entriesAsync = ref.watch(houseMeterEntriesProvider(_periodKey));
    final periodLabel = DateFormat('MMMM yyyy').format(_period);

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(
            title: 'Record monthly readings',
            subtitle: houseAsync.maybeWhen(
                data: (house) => house.name, orElse: () => ''),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Failed to load: $e')),
              data: (entries) {
                final done = entries.where((e) => e.recorded).length;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.bgDefault,
                        border: Border.all(color: AppColors.neutral200),
                        borderRadius:
                            BorderRadius.circular(AppRadii.inputField),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _changePeriod(-1),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          Expanded(
                            child: Text('Reading period  ·  $periodLabel',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _changePeriod(1),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ProgressCard(done: done, total: entries.length),
                    const SizedBox(height: 10),
                    if (entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No rooms yet — add a room first.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    for (final entry in entries) ...[
                      MeterCard(
                        icon: entry.utilityType == UtilityType.electricity
                            ? Icons.bolt_rounded
                            : Icons.water_drop_rounded,
                        iconColor: entry.utilityType == UtilityType.electricity
                            ? AppColors.accentOrange
                            : AppColors.info,
                        title:
                            '${entry.room.roomNo}  ·  ${entry.utilityType.label}',
                        lastReadingLabel: entry.previous == null
                            ? 'No previous reading yet'
                            : 'Last reading: ${DateFormat('dd/MM/yyyy').format(entry.previous!.readingDate)} (${entry.previous!.readingType.label.toLowerCase()})',
                        recorded: entry.recorded,
                        previousValue: entry.previous == null
                            ? '—'
                            : '${entry.previous!.currentReading} ${entry.utilityType.unit}',
                        currentController: _controllerFor(
                            entry.room.id, entry.utilityType,
                            prefill: entry.thisPeriod?.currentReading),
                        usageLabel: entry.thisPeriod?.usageAmount != null
                            ? 'Usage this period: ${entry.thisPeriod!.usageAmount} ${entry.utilityType.unit}'
                            : null,
                        errorText:
                            _errors[_keyFor(entry.room.id, entry.utilityType)],
                        onViewHistory: () => context.push(
                            '/home/houses/${widget.houseId}/readings/${entry.room.id}/${entry.utilityType.pathSegment}'),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_saveError != null) ...[
                      Text(_saveError!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 12.5)),
                      const SizedBox(height: 10),
                    ],
                    AppButton(
                        label: _saving ? 'Saving…' : 'Save readings',
                        style: AppButtonStyle.accent,
                        onPressed: _saving || entries.isEmpty ? null : _save),
                    const SizedBox(height: 10),
                    const AppBanner(
                      message:
                          'Saving stays on this screen. Invoices are created separately in the Bills tab. Empty rooms are still read — that usage belongs to the landlord, not to the next tenant.',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

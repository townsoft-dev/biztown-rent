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
import '../shared/app_text_field.dart';
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

  /// "X/Y rooms recorded" phải đếm theo PHÒNG, không phải theo dòng
  /// (room × tiện ích) — `entries` có 2 dòng/phòng (điện + nước) nên đếm
  /// thẳng `entries.length`/`entries.where(recorded)` sẽ ra gấp đôi số phòng
  /// thật (bug dungtv phát hiện: nhà chỉ có 1 phòng nhưng hiện "2/2 rooms").
  /// 1 phòng chỉ tính "đã ghi" khi CẢ điện lẫn nước của phòng đó đều Recorded.
  ({int done, int total}) _roomProgress(List<RoomMeterEntry> entries) {
    final byRoom = <String, List<RoomMeterEntry>>{};
    for (final entry in entries) {
      byRoom.putIfAbsent(entry.room.id, () => []).add(entry);
    }
    final done =
        byRoom.values.where((es) => es.every((e) => e.recorded)).length;
    return (done: done, total: byRoom.length);
  }

  TextEditingController _controllerFor(String roomId, UtilityType type,
      {num? prefill}) {
    final key = _keyFor(roomId, type);
    // Prefill có dấu phẩy (đúng Figma) — an toàn vì dòng đã Recorded thì
    // field bị disable, `_save()` không bao giờ đọc lại controller này để
    // parse số (xem `if (entry.recorded) continue;`).
    return _controllers.putIfAbsent(
        key,
        () => TextEditingController(
            text: prefill == null ? '' : formatReadingValue(prefill)));
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

  Future<void> _pickPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _period,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select reading period',
    );
    if (picked == null) return;
    setState(() {
      _period = DateTime(picked.year, picked.month);
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
              data: (house) {
                final entries = entriesAsync.valueOrNull;
                var progress = '';
                if (entries != null) {
                  final p = _roomProgress(entries);
                  progress = '  ·  ${p.done}/${p.total} rooms recorded';
                }
                return '${house.name}$progress  ·  ${DateFormat('MMM yyyy').format(_period)}';
              },
              orElse: () => '',
            ),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Failed to load: $e')),
              data: (entries) {
                final roomProgress = _roomProgress(entries);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    AppTextField(
                      // `initialValue` của TextFormField chỉ đọc 1 lần lúc
                      // tạo — đổi `key` theo kỳ để ép remount mỗi khi đổi kỳ
                      // (bấm mũi tên hoặc chọn ngày), nếu không chữ hiển thị
                      // sẽ đứng yên dù `_period` đã đổi.
                      key: ValueKey(_period),
                      label: 'Reading period *',
                      initialValue:
                          '$periodLabel  ·  ${DateFormat('dd/MM/yyyy').format(_period)}',
                      // Cố tình KHÔNG set `readOnly: true` — đúng Figma field
                      // này nền trắng + viền (như field đang gõ được), không
                      // phải nền xám mờ `bgMuted` của field readonly thật sự
                      // (VD "Previous"). `onTap` một mình đã đủ chặn gõ tay
                      // (`AppTextField` tự tính `readOnly || onTap != null`
                      // cho TextFormField) mà không đổi màu nền.
                      trailing: AppTextFieldTrailingIcon.date,
                      onTap: _pickPeriod,
                    ),
                    const SizedBox(height: 10),
                    ProgressCard(
                        done: roomProgress.done, total: roomProgress.total),
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
                            : '${formatReadingValue(entry.previous!.currentReading)} ${entry.utilityType.unit}',
                        currentController: _controllerFor(
                            entry.room.id, entry.utilityType,
                            prefill: entry.thisPeriod?.currentReading),
                        usageLabel: entry.thisPeriod?.usageAmount != null
                            ? 'Usage this period: ${formatReadingValue(entry.thisPeriod!.usageAmount!)} ${entry.utilityType.unit}'
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

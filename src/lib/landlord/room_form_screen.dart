import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/house.dart';
import '../data/models/room.dart';
import '../data/photo_picker_controller.dart';
import '../data/recurring_fees_controller.dart';
import '../shared/app_button.dart';
import '../shared/app_chip.dart';
import '../shared/app_text_field.dart';
import '../shared/photo_picker_row.dart';
import '../shared/recurring_fees_editor.dart';
import '../shared/section_label.dart';
import '../shared/top_bar.dart';

/// H-05 — Room Create/Edit (node 220:2804, lấy qua Figma MCP 10/09/2026), nối
/// CRUD thật vào `tb_room` (10/09/2026, xem changelog/2026-09-10.md).
/// `roomId == null` → tạo mới; ngược lại → sửa, nạp dữ liệu thật qua `roomProvider`.
class RoomFormScreen extends ConsumerStatefulWidget {
  final String houseId;
  final String? roomId;

  const RoomFormScreen({super.key, required this.houseId, this.roomId});

  bool get isEdit => roomId != null;

  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends ConsumerState<RoomFormScreen> {
  static const _fixedAmenities = ['A/C', 'Water heater', 'Balcony', 'Window'];

  final _formKey = GlobalKey<FormState>();
  final _roomNoController = TextEditingController();
  final _areaController = TextEditingController();
  final _referenceRentController = TextEditingController();
  final _noteController = TextEditingController();
  late final PhotoPickerController _photos;
  late final RecurringFeesController _fees;
  final Set<String> _selectedAmenities = {};
  final List<String> _customAmenities = [];

  bool _initialized = false;
  bool _houseFeesPrefilled = false;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _photos = PhotoPickerController();
    _fees = RecurringFeesController();
  }

  void _prefill(Room room) {
    if (_initialized) return;
    _initialized = true;
    _roomNoController.text = room.roomNo;
    _areaController.text = room.areaSqm.toString();
    _referenceRentController.text = room.baseRent?.toString() ?? '';
    _noteController.text = room.note ?? '';
    _photos.existingPaths.addAll(room.photos);
    for (final amenity in room.amenities) {
      if (_fixedAmenities.contains(amenity)) {
        _selectedAmenities.add(amenity);
      } else {
        _customAmenities.add(amenity);
        _selectedAmenities.add(amenity);
      }
    }
    if (room.recurringFees.isNotEmpty) {
      _fees.rows
        ..clear()
        ..addAll(room.recurringFees.map(
            (f) => RecurringFeeRow(name: f.name, amount: f.amount.toString())));
    }
  }

  /// Tạo phòng mới (không phải Edit) — điền sẵn "Default recurring fees" của
  /// Nhà, đúng câu chú thích ngay dưới field ("Pre-filled from this house's
  /// Default recurring fees when the room is created") — trước đó câu chú
  /// thích có nhưng code chưa thật sự làm, phát hiện lúc test tay tạo phòng
  /// mới thấy field trống dù Nhà đã có sẵn phí "Internet".
  void _prefillFeesFromHouse(House house) {
    if (widget.isEdit || _houseFeesPrefilled) return;
    _houseFeesPrefilled = true;
    if (house.recurringFees.isNotEmpty) {
      _fees.rows
        ..clear()
        ..addAll(house.recurringFees.map(
            (f) => RecurringFeeRow(name: f.name, amount: f.amount.toString())));
    }
  }

  @override
  void dispose() {
    _roomNoController.dispose();
    _areaController.dispose();
    _referenceRentController.dispose();
    _noteController.dispose();
    _photos.dispose();
    _fees.dispose();
    super.dispose();
  }

  Future<void> _addCustomAmenity() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add amenity'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() {
        _customAmenities.add(name);
        _selectedAmenities.add(name);
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final repo = ref.read(roomRepositoryProvider);
      final room = Room(
        id: '',
        houseId: widget.houseId,
        roomNo: _roomNoController.text.trim(),
        areaSqm: num.tryParse(_areaController.text.trim()) ?? 0,
        baseRent: num.tryParse(
            _referenceRentController.text.trim().replaceAll(',', '')),
        recurringFees: _fees.fees,
        amenities: _selectedAmenities.toList(),
        photos: _photos.keptExistingPaths,
        status: RoomStatus.empty,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: DateTime.now(),
      );

      late final String roomId;
      if (widget.isEdit) {
        roomId = widget.roomId!;
        await repo.update(roomId, room);
      } else {
        final created = await repo.create(room);
        roomId = created.id;
      }

      if (_photos.newFiles.isNotEmpty) {
        final uploadedPaths = <String>[];
        for (final file in _photos.newFiles) {
          uploadedPaths.add(
              await repo.uploadPhoto(widget.houseId, roomId, File(file.path)));
        }
        await repo.update(
          roomId,
          Room(
            id: roomId,
            houseId: room.houseId,
            roomNo: room.roomNo,
            areaSqm: room.areaSqm,
            baseRent: room.baseRent,
            recurringFees: room.recurringFees,
            amenities: room.amenities,
            photos: [..._photos.keptExistingPaths, ...uploadedPaths],
            status: room.status,
            note: room.note,
            createdAt: room.createdAt,
          ),
        );
      }
      for (final removed in _photos.removedExisting) {
        await repo.deletePhoto(removed);
      }

      ref.invalidate(roomsProvider(widget.houseId));
      if (widget.isEdit) ref.invalidate(roomProvider(roomId));
      // Cả family (mọi kỳ đã cache) — H-06 Entry tự lấy danh sách phòng
      // riêng qua `roomRepository.listByHouse`, không đi qua `roomsProvider`
      // ở trên, nên tạo/sửa phòng (đổi tên, thêm phòng mới...) không tự làm
      // mới màn đó nếu thiếu dòng này (bug tự phát hiện lúc test tay: thêm
      // phòng thứ 2 xong quay lại H-06 Entry vẫn chỉ thấy 1 phòng).
      ref.invalidate(houseMeterEntriesProvider);
      // Thẻ "Total/Empty rooms" ở H-01 — tạo phòng mới (hoặc chỉnh trạng
      // thái) phải cập nhật số liệu tổng hợp này, không chỉ danh sách phòng
      // trong 1 nhà.
      ref.invalidate(roomStatusesByHouseProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(
          () => _errorText = 'Could not save this room. Please try again.\n$e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEdit) {
      return _buildScaffold(context, null);
    }
    final roomAsync = ref.watch(roomProvider(widget.roomId!));
    return roomAsync.when(
      data: (room) {
        _prefill(room);
        return _buildScaffold(context, room);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) =>
          Scaffold(body: Center(child: Text('Could not load this room.\n$e'))),
    );
  }

  Widget _buildScaffold(BuildContext context, Room? room) {
    final houseAsync = ref.watch(houseProvider(widget.houseId));
    houseAsync.whenData(_prefillFeesFromHouse);
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: Column(
        children: [
          TopBar(
            title: widget.isEdit ? 'Edit room' : 'Add room',
            subtitle: houseAsync.value?.name,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  const SectionLabel('Photos'),
                  PhotoPickerRow(
                    controller: _photos,
                    resolveExistingUrl: (path) =>
                        ref.read(roomRepositoryProvider).signedPhotoUrl(path),
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                      label: 'Room no *',
                      controller: _roomNoController,
                      hintText: 'e.g. P.105'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Area (m²)',
                          controller: _areaController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          label: 'Reference rent *',
                          controller: _referenceRentController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Reference rent only suggests the monthly rent when a contract is created — it is never the billed amount.',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 17 / 12,
                          color: AppColors.textTertiary),
                    ),
                  ),
                  const SectionLabel('Amenities'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final a in [..._fixedAmenities, ..._customAmenities])
                        AppChip(
                          label: a,
                          selected: _selectedAmenities.contains(a),
                          onTap: () => setState(() =>
                              _selectedAmenities.contains(a)
                                  ? _selectedAmenities.remove(a)
                                  : _selectedAmenities.add(a)),
                        ),
                      AppChip(label: '+ Add', onTap: _addCustomAmenity),
                    ],
                  ),
                  const SectionLabel('Default recurring fees'),
                  Text(
                    "Pre-filled from this house's Default recurring fees when the room is created — freely editable afterward and never re-synced automatically.",
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 17 / 12,
                        color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 10),
                  RecurringFeesEditor(controller: _fees),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: 'Status',
                    initialValue: (room?.status ?? RoomStatus.empty).label,
                    readOnly: true,
                    trailing: AppTextFieldTrailingIcon.select,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '"Occupied" is set automatically when an active contract exists — it cannot be chosen manually.',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 17 / 12,
                          color: AppColors.textTertiary),
                    ),
                  ),
                  AppTextField(
                      label: 'Note', controller: _noteController, maxLines: 3),
                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(_errorText!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12)),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Cancel',
                          style: AppButtonStyle.ghost,
                          onPressed: _isSaving ? null : () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: AppButton(
                              label: 'Save',
                              onPressed: _isSaving ? null : _save)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../shared/app_button.dart';
import '../shared/app_chip.dart';
import '../shared/app_text_field.dart';
import '../shared/photo_picker_row.dart';
import '../shared/section_label.dart';
import '../shared/top_bar.dart';

/// H-05 — Room Create/Edit (node 220:2804, lấy qua Figma MCP 10/09/2026).
/// `roomId == null` → "Add room" (field trống); ngược lại → "Edit room" nạp
/// sẵn dữ liệu mẫu khớp Figma (chưa nối `tb_room` thật).
class RoomFormScreen extends StatefulWidget {
  final String houseId;
  final String? roomId;

  const RoomFormScreen({super.key, required this.houseId, this.roomId});

  bool get _isEdit => roomId != null;

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  static const _allAmenities = ['A/C', 'Water heater', 'Balcony', 'Window'];
  late final Set<String> _selectedAmenities =
      widget._isEdit ? {'A/C', 'Water heater'} : {};

  @override
  Widget build(BuildContext context) {
    final isEdit = widget._isEdit;
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: Column(
        children: [
          TopBar(
              title: isEdit ? 'Edit room' : 'Add room',
              subtitle: 'Nha tro Binh An',
              onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                const SectionLabel('Photos'),
                PhotoPickerRow(photoCount: isEdit ? 2 : 0, onAddPhoto: () {}),
                const SizedBox(height: 10),
                AppTextField(
                    label: 'Room no *',
                    initialValue: isEdit ? widget.roomId : null,
                    hintText: 'e.g. P.105'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: AppTextField(
                            label: 'Area (m²)',
                            initialValue: isEdit ? '22' : null,
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: AppTextField(
                            label: 'Reference rent *',
                            initialValue: isEdit ? '3,200,000' : null,
                            keyboardType: TextInputType.number)),
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
                    for (final a in _allAmenities)
                      AppChip(
                        label: a,
                        selected: _selectedAmenities.contains(a),
                        onTap: () => setState(() =>
                            _selectedAmenities.contains(a)
                                ? _selectedAmenities.remove(a)
                                : _selectedAmenities.add(a)),
                      ),
                    AppChip(label: '+ Add', onTap: () {}),
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
                Row(
                  children: [
                    Expanded(
                        child: AppTextField(
                            label: 'Fee name',
                            initialValue: isEdit ? 'Internet' : null)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: AppTextField(
                            label: 'Amount',
                            initialValue: isEdit ? '100,000' : null,
                            keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: AppTextField(
                            label: 'Fee name',
                            initialValue: isEdit ? 'Waste collection' : null)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: AppTextField(
                            label: 'Amount',
                            initialValue: isEdit ? '30,000' : null,
                            keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 10),
                AppButton(
                    label: '+ Add fee',
                    style: AppButtonStyle.ghost,
                    size: AppButtonSize.sm,
                    onPressed: () {}),
                const SizedBox(height: 10),
                const AppTextField(
                    label: 'Status',
                    initialValue: 'Empty',
                    readOnly: true,
                    trailing: AppTextFieldTrailingIcon.select),
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
                    label: 'Note',
                    initialValue: isEdit ? 'Corner room, quiet side' : null,
                    maxLines: 3),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                        child: AppButton(
                            label: 'Cancel',
                            style: AppButtonStyle.ghost,
                            onPressed: () => context.pop())),
                    const SizedBox(width: 8),
                    Expanded(
                        child: AppButton(
                            label: 'Save', onPressed: () => context.pop())),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

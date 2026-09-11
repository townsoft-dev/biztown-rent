import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/theme.dart';
import '../data/models/room.dart';
import 'app_button.dart';

/// Bottom sheet chọn nhiều phòng (T-06 "Room", BR-CTR-04/05) — chỉ liệt kê
/// phòng đang Empty của 1 Nhà đã chọn (phòng Occupied/UnderRepair không cho
/// chọn, không hiện luôn để tránh chọn nhầm).
class RoomMultiSelect {
  static Future<List<String>?> show(
    BuildContext context, {
    required List<Room> emptyRooms,
    required List<String> selectedRoomIds,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RoomMultiSelectSheet(
          emptyRooms: emptyRooms, initialSelected: selectedRoomIds),
    );
  }
}

class _RoomMultiSelectSheet extends StatefulWidget {
  final List<Room> emptyRooms;
  final List<String> initialSelected;

  const _RoomMultiSelectSheet(
      {required this.emptyRooms, required this.initialSelected});

  @override
  State<_RoomMultiSelectSheet> createState() => _RoomMultiSelectSheetState();
}

class _RoomMultiSelectSheetState extends State<_RoomMultiSelectSheet> {
  late final Set<String> _selected = widget.initialSelected.toSet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.t('contractForm.selectRooms'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            if (widget.emptyRooms.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(AppStrings.t('contractForm.noEmptyRooms'),
                    style: const TextStyle(color: AppColors.textSecondary)),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final room in widget.emptyRooms)
                      CheckboxListTile(
                        value: _selected.contains(room.id),
                        title: Text(room.roomNo),
                        subtitle: Text('${room.areaSqm} m²'),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) => setState(() {
                          if (checked ?? false) {
                            _selected.add(room.id);
                          } else {
                            _selected.remove(room.id);
                          }
                        }),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            AppButton(
              label: AppStrings.t('common.save'),
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_selected.toList()),
            ),
          ],
        ),
      ),
    );
  }
}

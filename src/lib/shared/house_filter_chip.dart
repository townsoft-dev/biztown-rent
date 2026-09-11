import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_strings.dart';
import '../core/theme.dart';
import '../data/models/house.dart';

/// Pill "All houses ▾" (T-02 trên Figma) — lọc list theo 1 Nhà cụ thể hoặc
/// "Tất cả". Dùng lại ở T-01/T-06 và về sau ở B-0x (Invoice List cũng lọc
/// theo Nhà — xem `docs/SCREEN-SPEC.md`).
class HouseFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const HouseFilterChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 14 / 11,
                    color: Colors.white)),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet chọn 1 Nhà hoặc "All houses" — trả về `null` nếu chọn "All
  /// houses"/đóng sheet không chọn gì, hoặc `houseId` đã chọn.
  static Future<String?> showPicker(
    BuildContext context, {
    required List<House> houses,
    required String? selectedHouseId,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(AppStrings.t('common.allHouses')),
              trailing: selectedHouseId == null
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(),
            ),
            for (final house in houses)
              ListTile(
                title: Text(house.name),
                trailing: selectedHouseId == house.id
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(house.id),
              ),
          ],
        ),
      ),
    );
  }
}

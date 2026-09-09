import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "Segmented control" (167:36 trên Figma) — dùng ở S-03 (All/Unread), sẽ dùng
/// lại ở H-02/H-03 (Rooms/Meters) và T-01/T-02 (Tenants/Contracts).
class AppSegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AppSegmentedControl({super.key, required this.labels, required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.bgTrack, borderRadius: BorderRadius.circular(AppRadii.segmentedControl)),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.bgDefault : null,
                  borderRadius: BorderRadius.circular(AppRadii.segmentedControlButton),
                  boxShadow: selected ? [BoxShadow(color: const Color(0xFF14192E).withValues(alpha: 0.15), offset: const Offset(0, 1), blurRadius: 3)] : null,
                ),
                child: Text(
                  labels[i],
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, height: 17 / 12, color: selected ? AppColors.textPrimary : AppColors.textSecondary),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

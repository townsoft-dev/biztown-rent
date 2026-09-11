import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// "toggle row" (Figma, node 331:2916 ở P-06 "Account active") — khung viền
/// hairline bo góc 9px cao 42px, chứa 1 nhãn + 1 `Switch`. Dùng ở field nào
/// cần bật/tắt 1 trạng thái boolean ngay trong form (khác hẳn `Switch` trần
/// không khung của Material mặc định).
class ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleRow(
      {super.key,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 17 / 13.5,
                    color: AppColors.textPrimary)),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

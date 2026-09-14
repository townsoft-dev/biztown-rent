import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/invoice_period.dart';
import '../core/theme.dart';

/// "Invoice schedule chip" (node `167:54` trên Figma) — 1 chip/kỳ hoá đơn,
/// 34×30, dùng chung với dòng "+N" cuối dải (state riêng, không nằm trong
/// [InvoiceChipState]) và dòng chú thích màu bên dưới. Xem
/// `core/invoice_period.dart` cho cách suy ra state từng kỳ.
class InvoiceScheduleStrip extends StatelessWidget {
  final List<InvoiceScheduleChipData> chips;
  final int visibleCount;
  final ValueChanged<DateTime> onTapPeriod;

  const InvoiceScheduleStrip({
    super.key,
    required this.chips,
    required this.onTapPeriod,
    this.visibleCount = 7,
  });

  @override
  Widget build(BuildContext context) {
    final visible = chips.take(visibleCount).toList();
    final overflow = chips.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final chip in visible)
              _Chip.period(chip, onTap: () => onTapPeriod(chip.periodStart)),
            if (overflow > 0) _Chip.overflow('+$overflow'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _LegendDot(AppColors.success,
                AppStrings.t('contractDetail.legendCollected')),
            _LegendDot(
                AppColors.info, AppStrings.t('contractDetail.legendSent')),
            _LegendDot(
                AppColors.error, AppStrings.t('contractDetail.legendOverdue')),
            _LegendDot(AppColors.accentOrange,
                AppStrings.t('contractDetail.legendCurrent')),
            _LegendDot(AppColors.neutral200,
                AppStrings.t('contractDetail.legendPreview'),
                last: true),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? textColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const _Chip({
    required this.label,
    this.background,
    this.textColor,
    this.borderColor,
    this.onTap,
  });

  factory _Chip.period(InvoiceScheduleChipData chip,
      {required VoidCallback onTap}) {
    return switch (chip.state) {
      InvoiceChipState.collected => _Chip(
          label: chip.label,
          background: AppColors.success,
          textColor: Colors.white,
          onTap: onTap),
      InvoiceChipState.sent => _Chip(
          label: chip.label,
          background: AppColors.info,
          textColor: Colors.white,
          onTap: onTap),
      InvoiceChipState.overdue => _Chip(
          label: chip.label,
          background: AppColors.error,
          textColor: Colors.white,
          onTap: onTap),
      InvoiceChipState.current => _Chip(
          label: chip.label,
          background: AppColors.bgDefault,
          textColor: AppColors.accentOrange,
          borderColor: AppColors.accentOrange,
          onTap: onTap),
      InvoiceChipState.scheduled => _Chip(
          label: chip.label,
          background: AppColors.bgDefault,
          textColor: AppColors.neutral200,
          borderColor: AppColors.neutral200,
          onTap: onTap),
    };
  }

  factory _Chip.overflow(String label) => _Chip(
      label: label,
      background: AppColors.bgDefault,
      textColor: AppColors.textSecondary,
      borderColor: AppColors.borderSubtle);

  @override
  Widget build(BuildContext context) {
    // `dashed` (kỳ "scheduled") lẽ ra viền đứt nét theo Figma — `Border.all`
    // không hỗ trợ trực tiếp, `CustomPaint` là thừa cho 1 chip 34px; chấp
    // nhận viền liền nét cùng màu xám nhạt đúng token, khác biệt không đáng
    // kể ở kích thước này.
    final child = Container(
      width: 34,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xs),
        color: background,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.5)
            : null,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
    );
    if (onTap == null) return child;
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        child: child);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool last;

  const _LegendDot(this.color, this.label, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: last ? 0 : 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10.5, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

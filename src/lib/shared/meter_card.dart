import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import 'status_pill.dart';

/// "Meter card" (171:160 trên Figma) — 1 thẻ / 1 đồng hồ (không phải / phòng)
/// ở H-06 Entry. `previous` luôn readonly (chỉ số kỳ trước); `current` cho
/// nhập tay. Chưa ghi (`recorded = false`) thì viền cam + badge "Not recorded".
class MeterCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String lastReadingLabel;
  final bool recorded;
  final String previousValue;
  final TextEditingController currentController;
  final String? usageLabel;
  final ValueChanged<String>? onCurrentChanged;
  final String? errorText;
  final VoidCallback? onViewHistory;

  const MeterCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.lastReadingLabel,
    required this.recorded,
    required this.previousValue,
    required this.currentController,
    this.usageLabel,
    this.onCurrentChanged,
    this.errorText,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        border: Border.all(
            color: recorded ? AppColors.borderSubtle : AppColors.accentOrange,
            width: recorded ? 1 : 1.5),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onViewHistory,
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(AppRadii.inputField)),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 18 / 13.5,
                              color: AppColors.textPrimary)),
                      Text(lastReadingLabel,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              height: 17 / 11,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                StatusPill(
                    text: recorded ? 'Recorded' : 'Not recorded',
                    style: recorded
                        ? StatusBadgeStyle.occupied
                        : StatusBadgeStyle.expiringSoon),
                if (onViewHistory != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.neutral200, size: 20),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Previous',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 14 / 11,
                            color: AppColors.textTertiary)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 11),
                      decoration: BoxDecoration(
                          color: AppColors.bgMuted,
                          borderRadius:
                              BorderRadius.circular(AppRadii.inputField)),
                      child: Text(previousValue,
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Current',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 14 / 11,
                            color: AppColors.textTertiary)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: currentController,
                      enabled: !recorded,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: const [ThousandsInputFormatter()],
                      onChanged: onCurrentChanged,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter…',
                        errorText: errorText,
                        errorMaxLines: 3,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 11),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadii.inputField),
                          borderSide: const BorderSide(
                              color: AppColors.neutral200, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (usageLabel != null) ...[
            const SizedBox(height: 10),
            Text(usageLabel!,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 17 / 11,
                    color: AppColors.success)),
          ],
        ],
      ),
    );
  }
}

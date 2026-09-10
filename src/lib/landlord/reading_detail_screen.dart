import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../shared/app_banner.dart';
import '../shared/app_button.dart';
import '../shared/detail_row.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

/// H-06 — Record Monthly Reading (PERIODIC) · Detail/Edit (node 220:2905, lấy
/// qua Figma MCP 10/09/2026). Dữ liệu mẫu khớp Figma (P.101 · Electricity kỳ
/// 09/2026), chưa nối `tb_electricity_reading`/`tb_water_reading` thật.
class ReadingDetailScreen extends StatelessWidget {
  final String houseId;
  final String readingId;

  const ReadingDetailScreen(
      {super.key, required this.houseId, required this.readingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(
            title: 'Reading detail',
            subtitle: 'P.101  ·  Electricity  ·  periodic reading',
            onBack: () => context.pop(),
            trailing: TopBarMoreButton(onTap: () {}),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: AppColors.accentOrange,
                          borderRadius: BorderRadius.circular(AppRadii.button)),
                      child: const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('01/09/2026  ·  P.101',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ),
                    const StatusPill(
                        text: 'Periodic', style: StatusBadgeStyle.sent),
                  ],
                ),
                const SizedBox(height: 10),
                const DetailBlock(children: [
                  DetailRow(
                      label: 'Reading type', value: 'Periodic  (PERIODIC)'),
                  DetailRow(label: 'Room', value: 'P.101  —  Nha tro Binh An'),
                  DetailRow(label: 'Period', value: 'September 2026'),
                  DetailRow(
                      label: 'Previous → Current',
                      value: '1,120 → 1,216   ·   96 kWh'),
                  DetailRow(
                      label: 'Recorded by',
                      value: 'Dream Manager  ·  01/09 09:12  ·  photo ✓'),
                  DetailRow(
                      label: 'Lock status',
                      value: 'Unlocked — no invoice uses it yet',
                      showDivider: false),
                ]),
                const SizedBox(height: 10),
                const AppBanner(
                  message:
                      'A reading locks as soon as any invoice other than Draft uses it. Locked readings cannot be edited; correct them with an adjustment line on the next invoice.',
                ),
                const SectionLabel('Reading history  ·  P.101 · Electricity'),
                const DetailBlock(children: [
                  DetailRow(
                      label: '01/09/2026',
                      value: '1,120 → 1,216 · 96 kWh · Periodic'),
                  DetailRow(
                      label: '20/08/2026',
                      value: '1,120 → 1,120 · 0 · Move-in (Tran Thi B)'),
                  DetailRow(
                      label: '20/08/2026',
                      value: '1,050 → 1,120 · 70 kWh · Move-out'),
                  DetailRow(
                      label: '01/08/2026',
                      value: '980 → 1,050 · 70 kWh · Periodic',
                      showDivider: false),
                ]),
                const SizedBox(height: 10),
                AppButton(
                    label: 'Edit reading',
                    style: AppButtonStyle.accent,
                    onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

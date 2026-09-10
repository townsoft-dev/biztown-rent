import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../shared/app_banner.dart';
import '../shared/app_button.dart';
import '../shared/app_text_field.dart';
import '../shared/meter_card.dart';
import '../shared/progress_card.dart';
import '../shared/top_bar.dart';

/// H-06 — Record Monthly Reading (PERIODIC) · Entry (node 220:3077, lấy qua
/// Figma MCP 10/09/2026). Dữ liệu mẫu khớp Figma (3 đồng hồ của "Nha tro Binh
/// An", kỳ 09/2026), chưa nối `tb_electricity_reading`/`tb_water_reading` thật.
/// Xem lịch sử chi tiết 1 đồng hồ đi qua H-04 ("View reading history"), không
/// đặt thêm ở đây vì mỗi `MeterCard` đã có ô nhập số liệu riêng.
class ReadingEntryScreen extends StatefulWidget {
  final String houseId;

  const ReadingEntryScreen({super.key, required this.houseId});

  @override
  State<ReadingEntryScreen> createState() => _ReadingEntryScreenState();
}

class _ReadingEntryScreenState extends State<ReadingEntryScreen> {
  final _elecController = TextEditingController(text: '1,216');
  final _waterController = TextEditingController(text: '59');
  final _elec2Controller = TextEditingController();

  @override
  void dispose() {
    _elecController.dispose();
    _waterController.dispose();
    _elec2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(
            title: 'Record monthly readings',
            subtitle: 'Nha tro Binh An  ·  6/8 rooms recorded  ·  Sep 2026',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                const AppTextField(
                    label: 'Reading period *',
                    initialValue: 'September 2026  ·  01/09/2026',
                    readOnly: true,
                    trailing: AppTextFieldTrailingIcon.date),
                const SizedBox(height: 10),
                const ProgressCard(done: 6, total: 8),
                const SizedBox(height: 10),
                MeterCard(
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.accentOrange,
                  title: 'P.101  ·  Electricity',
                  lastReadingLabel: 'Last reading: 01/08/2026 (periodic)',
                  recorded: true,
                  previousValue: '1,120 kWh',
                  currentController: _elecController,
                  usageLabel: 'Usage this period: 96 kWh',
                  onCurrentChanged: (_) {},
                ),
                const SizedBox(height: 10),
                MeterCard(
                  icon: Icons.water_drop_rounded,
                  iconColor: AppColors.info,
                  title: 'P.101  ·  Water',
                  lastReadingLabel: 'Last reading: 01/08/2026 (periodic)',
                  recorded: true,
                  previousValue: '54 m³',
                  currentController: _waterController,
                  usageLabel: 'Usage this period: 5 m³',
                ),
                const SizedBox(height: 10),
                MeterCard(
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.accentOrange,
                  title: 'P.103  ·  Electricity',
                  lastReadingLabel: 'Last reading: 01/08/2026 (periodic)',
                  recorded: false,
                  previousValue: '1,284 kWh',
                  currentController: _elec2Controller,
                ),
                const SizedBox(height: 10),
                AppButton(
                    label: 'Save readings',
                    style: AppButtonStyle.accent,
                    onPressed: () => context.pop()),
                const SizedBox(height: 10),
                const AppBanner(
                  message:
                      'Saving stays on this screen. Invoices are created separately in the Bills tab. Empty rooms are still read — that usage belongs to the landlord, not to the next tenant.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

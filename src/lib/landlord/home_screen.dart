import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../shared/app_fab.dart';
import '../shared/list_card.dart';
import '../shared/section_label.dart';
import '../shared/stat_card.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

/// H-01 — Home / House List (node 220:2347, lấy qua Figma MCP 10/09/2026).
/// Dữ liệu nhà bên dưới là sample khớp đúng nội dung Figma — thay bằng dữ
/// liệu thật khi nối `tb_house`/`tb_room` (chưa tới phase này).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // houseId chỉ set cho "Nha tro Binh An" — đây là nhà DUY NHẤT Figma có đủ
  // dữ liệu mẫu chi tiết cho H-02→H-06; 2 nhà còn lại chưa có data mẫu tương
  // ứng nên chưa nối điều hướng (tránh hiện nhầm data của nhà này sang nhà
  // khác), sẽ nối khi có `tb_house`/`tb_room` thật.
  static const _houses = [
    _HouseData(
      houseId: 'binh-an',
      name: 'Nha tro Binh An',
      address: '12 Le Van Sy, District 3, HCMC',
      roomsSummary: '8 rooms  ·  6/8 occupied',
      badgeText: '18/24',
      badgeStyle: StatusBadgeStyle.occupied,
      thumbColor: AppColors.primary,
    ),
    _HouseData(
      houseId: null,
      name: 'Chung cu mini Phu Nhuan',
      address: '45 Nguyen Trong Tuyen, Phu Nhuan',
      roomsSummary: '3 rooms  ·  3/3 occupied',
      badgeText: '2/8',
      badgeStyle: StatusBadgeStyle.empty,
      thumbColor: AppColors.secondary,
    ),
    _HouseData(
      houseId: null,
      name: 'Day tro Tan Binh',
      address: '88 Cong Hoa, Tan Binh',
      roomsSummary: '6 rooms  ·  4/6 occupied',
      badgeText: '6/6',
      badgeStyle: StatusBadgeStyle.occupied,
      thumbColor: AppColors.accentCoral,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      floatingActionButton:
          AppFab(onPressed: () => context.push('/home/houses/new')),
      body: Column(
        children: [
          TopBar.home(
            greeting: 'Hello,',
            name: 'Nguyễn Thúy Hường',
            overview: '3 houses · 18/24 rooms occupied',
            trailing:
                TopBarBellButton(onTap: () => context.push('/notifications')),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                const Row(
                  children: [
                    Expanded(
                        child: StatCard(value: '24', label: 'Total rooms')),
                    SizedBox(width: 8),
                    Expanded(child: StatCard(value: '6', label: 'Empty rooms')),
                  ],
                ),
                const SectionLabel('Your houses'),
                for (final house in _houses) ...[
                  ListCard(
                    thumbColor: house.thumbColor,
                    icon: Icons.home_work_rounded,
                    title: house.name,
                    trailing: StatusPill(
                        text: house.badgeText, style: house.badgeStyle),
                    body: house.address,
                    meta: house.roomsSummary,
                    onTap: house.houseId == null
                        ? null
                        : () => context.push('/home/houses/${house.houseId}'),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseData {
  final String? houseId;
  final String name;
  final String address;
  final String roomsSummary;
  final String badgeText;
  final StatusBadgeStyle badgeStyle;
  final Color thumbColor;

  const _HouseData({
    required this.houseId,
    required this.name,
    required this.address,
    required this.roomsSummary,
    required this.badgeText,
    required this.badgeStyle,
    required this.thumbColor,
  });
}

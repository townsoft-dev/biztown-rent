import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/room.dart';
import '../shared/app_fab.dart';
import '../shared/list_card.dart';
import '../shared/section_label.dart';
import '../shared/stat_card.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

/// H-01 — Home / House List (node 220:2347, lấy qua Figma MCP 10/09/2026),
/// nối CRUD thật vào `tb_house`/`tb_room` (10/09/2026, xem
/// changelog/2026-09-10.md).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final housesAsync = ref.watch(housesProvider);
    final statusesAsync = ref.watch(roomStatusesByHouseProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      floatingActionButton:
          AppFab(onPressed: () => context.push('/home/houses/new')),
      body: Column(
        children: [
          TopBar.home(
            greeting: 'Hello,',
            name: 'Nguyễn Thúy Hường',
            overview: housesAsync.hasValue && statusesAsync.hasValue
                ? _overviewLine(
                    housesAsync.requireValue.length, statusesAsync.requireValue)
                : '',
            trailing:
                TopBarBellButton(onTap: () => context.push('/notifications')),
          ),
          Expanded(
            child: housesAsync.when(
              data: (houses) {
                final statuses = statusesAsync.valueOrNull ?? const {};
                final allStatuses = statuses.values.expand((e) => e);
                final total = allStatuses.length;
                final empty =
                    allStatuses.where((s) => s == RoomStatus.empty).length;

                if (houses.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        "You don't have any house yet. Tap + to add your first house.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: StatCard(
                                value: '$total', label: 'Total rooms')),
                        const SizedBox(width: 8),
                        Expanded(
                            child: StatCard(
                                value: '$empty', label: 'Empty rooms')),
                      ],
                    ),
                    const SectionLabel('Your houses'),
                    for (final house in houses) ...[
                      Builder(builder: (context) {
                        final houseStatuses = statuses[house.id] ?? const [];
                        final occupied = houseStatuses
                            .where((s) => s == RoomStatus.occupied)
                            .length;
                        return ListCard(
                          thumbColor: AppColors.primary,
                          icon: Icons.home_work_rounded,
                          title: house.name,
                          trailing: StatusPill(
                            text: '$occupied/${houseStatuses.length}',
                            style: occupied == houseStatuses.length &&
                                    houseStatuses.isNotEmpty
                                ? StatusBadgeStyle.occupied
                                : StatusBadgeStyle.empty,
                          ),
                          body: house.address,
                          meta:
                              '${houseStatuses.length} rooms  ·  $occupied/${houseStatuses.length} occupied',
                          onTap: () => context.push('/home/houses/${house.id}'),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  Center(child: Text('Could not load your houses.\n$e')),
            ),
          ),
        ],
      ),
    );
  }

  String _overviewLine(int houseCount, Map<String, List<RoomStatus>> statuses) {
    final allStatuses = statuses.values.expand((e) => e);
    final total = allStatuses.length;
    final occupied = allStatuses.where((s) => s == RoomStatus.occupied).length;
    return '$houseCount houses · $occupied/$total rooms occupied';
  }
}

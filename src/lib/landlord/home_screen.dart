import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
import '../core/locale_provider.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../data/models/room.dart';
import '../shared/app_fab.dart';
import '../shared/list_card.dart';
import '../shared/list_error_view.dart';
import '../shared/section_label.dart';
import '../shared/stat_card.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';
import 'package:material_symbols_icons/symbols.dart';

/// H-01 — Home / House List (node 220:2347, lấy qua Figma MCP 10/09/2026),
/// nối CRUD thật vào `tb_house`/`tb_room` (10/09/2026, xem
/// changelog/2026-09-10.md).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final housesAsync = ref.watch(housesProvider);
    final statusesAsync = ref.watch(roomStatusesByHouseProvider);
    final nameAsync = ref.watch(currentUserNameProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      floatingActionButton:
          AppFab(onPressed: () => context.push('/home/houses/new')),
      body: Column(
        children: [
          TopBar.home(
            greeting: AppStrings.t('home.greeting'),
            name: nameAsync.valueOrNull ?? '',
            overview: housesAsync.hasValue && statusesAsync.hasValue
                ? _overviewLine(
                    housesAsync.requireValue.length, statusesAsync.requireValue)
                : '',
            trailing: TopBarBellButton(
                onTap: () => context.push('/notifications'),
                unreadCount: unreadCount),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: housesAsync.when(
                data: (houses) {
                  final statuses = statusesAsync.valueOrNull ?? const {};
                  final allStatuses = statuses.values.expand((e) => e);
                  final total = allStatuses.length;
                  final empty =
                      allStatuses.where((s) => s == RoomStatus.empty).length;

                  // Bọc trong ListView cuộn-được kể cả khi rỗng, nếu không thì
                  // đúng lúc cần kéo xuống làm mới nhất (chưa có nhà nào, hoặc
                  // tải hụt) lại không kéo được.
                  if (houses.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            AppStrings.t('home.emptyState'),
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: StatCard(
                                  value: '$total',
                                  label: AppStrings.t('home.totalRooms'))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: StatCard(
                                  value: '$empty',
                                  label: AppStrings.t('home.emptyRooms'))),
                        ],
                      ),
                      SectionLabel(AppStrings.t('home.yourHouses')),
                      for (final house in houses) ...[
                        Builder(builder: (context) {
                          final houseStatuses = statuses[house.id] ?? const [];
                          final occupied = houseStatuses
                              .where((s) => s == RoomStatus.occupied)
                              .length;
                          return ListCard(
                            thumbColor: AppColors.primary,
                            icon: Symbols.home_work_rounded,
                            title: house.name,
                            trailing: StatusPill(
                              text: '$occupied/${houseStatuses.length}',
                              style: occupied == houseStatuses.length &&
                                      houseStatuses.isNotEmpty
                                  ? StatusBadgeStyle.occupied
                                  : StatusBadgeStyle.empty,
                            ),
                            body: house.address,
                            meta: AppStrings.t('home.houseListMeta', {
                              'total': '${houseStatuses.length}',
                              'occupied': '$occupied',
                            }),
                            onTap: () =>
                                context.push('/home/houses/${house.id}'),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ListErrorView(error: e, onRetry: () => _refresh(ref))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kéo xuống (hoặc bấm "Thử lại" ở màn lỗi) để tải lại toàn bộ dữ liệu H-01.
  /// Nhận `ref` qua tham số vì đây là `ConsumerWidget` (không giữ state), `ref`
  /// chỉ tồn tại trong phạm vi `build`.
  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(housesProvider);
    ref.invalidate(roomStatusesByHouseProvider);
    ref.invalidate(currentUserNameProvider);
    try {
      await ref.read(housesProvider.future);
    } catch (_) {
      // Lỗi đã hiển thị qua ListErrorView — nuốt ở đây để vòng xoay tắt.
    }
  }

  String _overviewLine(int houseCount, Map<String, List<RoomStatus>> statuses) {
    final allStatuses = statuses.values.expand((e) => e);
    final total = allStatuses.length;
    final occupied = allStatuses.where((s) => s == RoomStatus.occupied).length;
    return AppStrings.t('home.overview', {
      'houseCount': '$houseCount',
      'occupied': '$occupied',
      'total': '$total',
    });
  }
}

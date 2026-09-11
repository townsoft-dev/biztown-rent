import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
import '../core/locale_provider.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../shared/app_fab.dart';
import '../shared/list_card.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

/// P-05 — Manager List (node 220:5030, Figma) — gộp theo NGƯỜI (1 Manager có
/// thể được giao nhiều Nhà), chỉ hiện Manager của các Nhà tôi SỞ HỮU.
class ManagerListScreen extends ConsumerWidget {
  const ManagerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final managersAsync = ref.watch(managerAccountsProvider);
    final ownedIdsAsync = ref.watch(ownedHouseIdsProvider);
    final totalHouses = ownedIdsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      floatingActionButton:
          AppFab(onPressed: () => context.push('/profile/managers/new')),
      body: Column(
        children: [
          TopBar(
              title: AppStrings.t('managerList.title'),
              onBack: () => context.pop()),
          Expanded(
            child: managersAsync.when(
              data: (managers) {
                if (managers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        AppStrings.t('managerList.emptyState'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    SectionLabel(AppStrings.t('managerList.sectionManagers')),
                    for (final manager in managers) ...[
                      ListCard(
                        thumbColor: AppColors.primary,
                        thumbShape: ListCardThumbShape.round,
                        initials: manager.initials,
                        title: manager.fullName,
                        trailing: StatusPill(
                          text: manager.isActive
                              ? AppStrings.t('managerList.statusActive')
                              : AppStrings.t('managerList.statusDisabled'),
                          style: manager.isActive
                              ? StatusBadgeStyle.active
                              : StatusBadgeStyle.disabled,
                        ),
                        body: manager.phone,
                        meta: manager.houseIds.isEmpty
                            ? AppStrings.t('managerList.noHouseGranted')
                            : AppStrings.t('managerList.housesGranted', {
                                'count': '${manager.houseIds.length}',
                                'total': '$totalHouses',
                              }),
                        onTap: () =>
                            context.push('/profile/managers/${manager.phone}'),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                  child: Text(
                      AppStrings.t('managerList.loadError', {'error': '$e'}))),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final managersAsync = ref.watch(managerAccountsProvider);
    final ownedIdsAsync = ref.watch(ownedHouseIdsProvider);
    final totalHouses = ownedIdsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      floatingActionButton:
          AppFab(onPressed: () => context.push('/profile/managers/new')),
      body: Column(
        children: [
          TopBar(title: 'Manager accounts', onBack: () => context.pop()),
          Expanded(
            child: managersAsync.when(
              data: (managers) {
                if (managers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        "No manager accounts yet. Tap + to invite someone to help manage your houses.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    const SectionLabel('Managers'),
                    for (final manager in managers) ...[
                      ListCard(
                        thumbColor: AppColors.primary,
                        thumbShape: ListCardThumbShape.round,
                        initials: manager.initials,
                        title: manager.fullName,
                        trailing: StatusPill(
                          text: manager.isActive ? 'Active' : 'Disabled',
                          style: manager.isActive
                              ? StatusBadgeStyle.active
                              : StatusBadgeStyle.disabled,
                        ),
                        body: manager.phone,
                        meta: manager.houseIds.isEmpty
                            ? 'No house granted'
                            : '${manager.houseIds.length} of $totalHouses houses granted',
                        onTap: () =>
                            context.push('/profile/managers/${manager.phone}'),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  Center(child: Text('Could not load manager accounts.\n$e')),
            ),
          ),
        ],
      ),
    );
  }
}

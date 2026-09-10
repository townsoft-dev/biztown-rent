import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import '../shared/app_chip.dart';
import '../shared/avatar.dart';
import '../shared/confirm_dialog.dart';
import '../shared/menu_row.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';

/// P-01 — Profile & Settings (node 220:4706, lấy qua Figma MCP 10/09/2026).
/// Hub điều hướng sang toàn bộ seri P-0x — không tự CRUD gì ở đây.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isMainManagerAsync = ref.watch(isMainManagerProvider);
    final managersAsync = ref.watch(managerAccountsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          const TopBar(title: 'Profile & Settings'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                profileAsync.when(
                  data: (profile) => Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Avatar(initials: initialsFromName(profile.fullName)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(profile.fullName,
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 22 / 16,
                                    color: AppColors.textPrimary)),
                            Text(profile.phone,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    height: 18 / 13,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            if (isMainManagerAsync.valueOrNull == true)
                              const StatusPill(
                                  text: 'Main Manager',
                                  style: StatusBadgeStyle.empty),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(
                      height: 56,
                      child: Center(child: CircularProgressIndicator())),
                  error: (e, st) => Text('Could not load your profile.\n$e'),
                ),
                const SizedBox(height: 6),
                const SectionLabel('Account'),
                MenuRow(
                  icon: Icons.badge_rounded,
                  label: 'Personal profile',
                  onTap: () => context.push('/profile/personal'),
                ),
                const SizedBox(height: 8),
                MenuRow(
                  icon: Icons.account_balance_rounded,
                  label: 'Payout bank account',
                  onTap: () => context.push('/profile/bank-account'),
                ),
                const SizedBox(height: 8),
                MenuRow(
                  icon: Icons.lock_rounded,
                  label: 'Change password',
                  onTap: () => context.push('/profile/password'),
                ),
                if (isMainManagerAsync.valueOrNull == true) ...[
                  const SizedBox(height: 6),
                  const SectionLabel('Management  ·  Main Manager only'),
                  MenuRow(
                    icon: Icons.manage_accounts_rounded,
                    label: 'Manager accounts',
                    badgeText: managersAsync.valueOrNull?.length.toString(),
                    onTap: () => context.push('/profile/managers'),
                  ),
                ],
                const SizedBox(height: 6),
                const SectionLabel('Other'),
                MenuRow(
                  icon: Icons.notifications_rounded,
                  label: 'Notification center',
                  onTap: () => context.push('/notifications'),
                ),
                const SizedBox(height: 8),
                MenuRow(
                  icon: Icons.language_rounded,
                  label: 'Language',
                  // Đa ngôn ngữ để Phase 2 (docs/CLAUDE.md mục "Ngôn ngữ UI") —
                  // hiện chỉ hiện đúng chip Figma, chưa đổi được ngôn ngữ thật.
                  trailingWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppChip(label: 'EN', selected: true),
                      const SizedBox(width: 6),
                      AppChip(label: 'VI', onTap: () => _comingSoon(context)),
                      const SizedBox(width: 6),
                      AppChip(label: 'KO', onTap: () => _comingSoon(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                MenuRow(
                  icon: Icons.logout_rounded,
                  label: 'Log out',
                  type: MenuRowType.danger,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming in a future update.')),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Log out of BizTown Rent-Manager?',
      description:
          'You will need your phone number and password to sign back in.',
      confirmLabel: 'Log out',
    );
    if (!confirmed) return;
    await ref.read(authRepositoryProvider).signOut();
  }
}

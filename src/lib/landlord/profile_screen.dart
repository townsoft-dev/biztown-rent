import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_strings.dart';
import '../core/locale_provider.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../shared/app_chip.dart';
import '../shared/avatar.dart';
import '../shared/confirm_dialog.dart';
import '../shared/menu_row.dart';
import '../shared/section_label.dart';
import '../shared/status_pill.dart';
import '../shared/top_bar.dart';
import 'package:material_symbols_icons/symbols.dart';

/// P-01 — Profile & Settings (node 220:4706, lấy qua Figma MCP 10/09/2026).
/// Hub điều hướng sang toàn bộ seri P-0x — không tự CRUD gì ở đây.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isMainManagerAsync = ref.watch(isMainManagerProvider);
    final managersAsync = ref.watch(managerAccountsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Column(
        children: [
          TopBar(title: AppStrings.t('profile.title')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                profileAsync.when(
                  data: (profile) => Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Builder(builder: (context) {
                        final avatarUrlAsync = profile.avatarPath == null
                            ? null
                            : ref.watch(avatarUrlProvider(profile.avatarPath!));
                        return Avatar(
                          initials: initialsFromName(profile.fullName),
                          imageUrl: avatarUrlAsync?.valueOrNull,
                        );
                      }),
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
                              StatusPill(
                                  text: AppStrings.t('common.mainManager'),
                                  style: StatusBadgeStyle.empty),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(
                      height: 56,
                      child: Center(child: CircularProgressIndicator())),
                  error: (e, st) =>
                      Text(AppStrings.t('profile.loadError', {'error': '$e'})),
                ),
                const SizedBox(height: 6),
                SectionLabel(AppStrings.t('profile.sectionAccount')),
                MenuRow(
                  icon: Symbols.badge_rounded,
                  label: AppStrings.t('profile.personalProfile'),
                  onTap: () => context.push('/profile/personal'),
                ),
                const SizedBox(height: 8),
                MenuRow(
                  icon: Symbols.account_balance_rounded,
                  label: AppStrings.t('profile.payoutBankAccount'),
                  onTap: () => context.push('/profile/bank-account'),
                ),
                const SizedBox(height: 8),
                MenuRow(
                  icon: Symbols.lock_rounded,
                  label: AppStrings.t('profile.changePassword'),
                  onTap: () => context.push('/profile/password'),
                ),
                if (isMainManagerAsync.valueOrNull == true) ...[
                  const SizedBox(height: 6),
                  SectionLabel(AppStrings.t('profile.sectionManagement')),
                  MenuRow(
                    icon: Symbols.manage_accounts_rounded,
                    label: AppStrings.t('profile.managerAccounts'),
                    badgeText: managersAsync.valueOrNull?.length.toString(),
                    onTap: () => context.push('/profile/managers'),
                  ),
                ],
                const SizedBox(height: 6),
                SectionLabel(AppStrings.t('profile.sectionOther')),
                MenuRow(
                  icon: Symbols.notifications_rounded,
                  label: AppStrings.t('profile.notificationCenter'),
                  onTap: () => context.push('/notifications'),
                ),
                const SizedBox(height: 8),
                MenuRow(
                  icon: Symbols.language_rounded,
                  label: AppStrings.t('profile.language'),
                  trailingWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppChip(
                        label: 'EN',
                        selected: language == AppLanguage.en,
                        onTap: () => ref
                            .read(languageProvider.notifier)
                            .setLanguage(AppLanguage.en),
                      ),
                      const SizedBox(width: 6),
                      AppChip(
                        label: 'VI',
                        selected: language == AppLanguage.vi,
                        onTap: () => ref
                            .read(languageProvider.notifier)
                            .setLanguage(AppLanguage.vi),
                      ),
                      const SizedBox(width: 6),
                      AppChip(
                        label: 'KO',
                        selected: language == AppLanguage.ko,
                        onTap: () => ref
                            .read(languageProvider.notifier)
                            .setLanguage(AppLanguage.ko),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                MenuRow(
                  icon: Symbols.logout_rounded,
                  label: AppStrings.t('profile.logOut'),
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

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.t('profile.logOutConfirmTitle'),
      description: AppStrings.t('profile.logOutConfirmDescription'),
      confirmLabel: AppStrings.t('profile.logOut'),
    );
    if (!confirmed) return;
    await ref.read(authRepositoryProvider).signOut();
  }
}
